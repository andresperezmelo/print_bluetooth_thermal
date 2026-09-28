import Flutter
import UIKit
import CoreBluetooth

@objc(PrintBluetoothThermalPlugin)
public class PrintBluetoothThermalPlugin: NSObject, FlutterPlugin, CBCentralManagerDelegate, CBPeripheralDelegate {

    private var centralManager: CBCentralManager?
    private var connectedPeripheral: CBPeripheral?
    private var targetCharacteristic: CBCharacteristic?
    private var discoveredDevices: [String] = []

    // --- BLE write flow-control state (iOS 18+ fix) ---------------------------
    // iOS 18 enforces CoreBluetooth transmit-queue flow control strictly: any
    // writeValue(type:.withoutResponse) issued while the controller queue is full
    // is silently dropped. The old tight send loop therefore truncated the
    // ESC/POS stream on iOS >= 18 (QR failed) while "working" on iOS < 18.
    // We now queue the payload and drain it respecting canSendWriteWithoutResponse
    // (for .withoutResponse) or the didWriteValueFor ack (for .withResponse).
    private struct WriteJob {
        let data: Data
        var offset: Int
        let writeType: CBCharacteristicWriteType
        let result: FlutterResult
    }
    private var writeJobs: [WriteJob] = []
    private var writeProgress = 0
    private let preferredChunkSize = 150
    private let writeStallTimeout: TimeInterval = 8.0
    // -------------------------------------------------------------------------

    // UUIDs comunes en impresoras térmicas BLE / ESC-POS
    private let allowedServiceUUIDs: [CBUUID] = [
        CBUUID(string: "00001101-0000-1000-8000-00805F9B34FB"),
        CBUUID(string: "49535343-FE7D-4AE5-8FA9-9FAFD205E455"),
        CBUUID(string: "A76EB9E0-F3AC-4990-84CF-3A94D2426B2B"),
        CBUUID(string: "E7810A71-73AE-499D-8C15-FAA9AEF0C3F2"),
        CBUUID(string: "18F0")
    ]

    private let allowedCharacteristicUUIDs: [CBUUID] = [
        CBUUID(string: "00001101-0000-1000-8000-00805F9B34FB"),
        CBUUID(string: "49535343-8841-43F4-A8D4-ECBE34729BB3"),
        CBUUID(string: "A76EB9E2-F3AC-4990-84CF-3A94D2426B2B"),
        CBUUID(string: "E7810A71-73AE-499D-8C15-FAA9AEF0C3F2"),
        CBUUID(string: "BEF8D6C9-9C21-4C9E-B632-BD58C1009F9F")
    ]

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "groons.web.app/print", binaryMessenger: registrar.messenger())
        let instance = PrintBluetoothThermalPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }

        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)

        case "getBatteryLevel":
            UIDevice.current.isBatteryMonitoringEnabled = true
            let batteryLevel = UIDevice.current.batteryLevel
            if batteryLevel < 0 {
                result(FlutterError(code: "UNAVAILABLE", message: "Nivel de batería no disponible", details: nil))
            } else {
                result(Int(batteryLevel * 100))
            }

        case "bluetoothenabled":
            result(centralManager?.state == .poweredOn)

        case "ispermissionbluetoothgranted":
            if #available(iOS 13.1, *) {
                let auth = CBCentralManager.authorization
                result(auth == .allowedAlways)
            } else if #available(iOS 13.0, *) {
                let auth = centralManager?.authorization ?? .notDetermined
                result(auth == .allowedAlways)
            } else {
                result(centralManager?.state == .poweredOn)
            }

        case "pairedbluetooths":
            handleScanDevices(result: result)

        case "connect":
            handleConnect(call: call, result: result)

        case "connectionstatus":
            let isConnected = (connectedPeripheral?.state == .connected)
            result(isConnected)

        case "writebytes":
            handleWriteBytes(call: call, result: result)

        case "printstring":
            handlePrintString(call: call, result: result)

        case "disconnect":
            handleDisconnect(result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // =======================================================
    // Handlers de Métodos
    // =======================================================

    private func handleScanDevices(result: @escaping FlutterResult) {
        discoveredDevices.removeAll()

        guard centralManager?.state == .poweredOn else {
            result(discoveredDevices)
            return
        }

        // Obtener dispositivos ya conectados al sistema con servicios conocidos
        let connectedList = centralManager?.retrieveConnectedPeripherals(withServices: allowedServiceUUIDs) ?? []
        for peripheral in connectedList {
            let name = peripheral.name ?? "Unknown"
            let deviceEntry = "\(name)#\(peripheral.identifier.uuidString)"
            if !discoveredDevices.contains(deviceEntry) {
                discoveredDevices.append(deviceEntry)
            }
        }

        // Iniciar escaneo BLE general
        centralManager?.scanForPeripherals(withServices: nil, options: nil)

        // Detener escaneo tras 4 segundos y devolver resultados
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
            guard let self = self else { return }
            self.centralManager?.stopScan()
            result(self.discoveredDevices)
        }
    }

    private func handleConnect(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let macAddress = call.arguments as? String,
              let uuid = UUID(uuidString: macAddress) else {
            result(false)
            return
        }

        let peripherals = centralManager?.retrievePeripherals(withIdentifiers: [uuid])
        guard let peripheral = peripherals?.first else {
            result(false)
            return
        }

        connectedPeripheral = peripheral
        connectedPeripheral?.delegate = self
        centralManager?.connect(peripheral, options: nil)

        // Esperar conexión y descubrir servicios
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
            guard let self = self else { return }
            if self.connectedPeripheral?.state == .connected {
                self.connectedPeripheral?.discoverServices(self.allowedServiceUUIDs)
                result(true)
            } else {
                result(false)
            }
        }
    }

    private func handleWriteBytes(call: FlutterMethodCall, result: @escaping FlutterResult) {
        var rawData: Data?

        if let typedData = call.arguments as? FlutterStandardTypedData {
            rawData = typedData.data
        } else if let intList = call.arguments as? [Int] {
            rawData = Data(intList.map { UInt8($0 & 0xFF) })
        } else if let numList = call.arguments as? [NSNumber] {
            rawData = Data(numList.map { UInt8($0.intValue & 0xFF) })
        }

        guard let data = rawData else {
            result(false)
            return
        }

        // Queue + flow-controlled drain instead of a tight, fire-and-forget loop.
        enqueueWrite(data, result: result)
    }

    private func handlePrintString(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let stringPrint = call.arguments as? String else {
            result(false)
            return
        }

        var size = 2
        var texto = stringPrint
        let linea = stringPrint.components(separatedBy: "///")

        if linea.count > 1 {
            let parsedSize = Int(linea[0]) ?? 2
            size = (parsedSize >= 1 && parsedSize <= 5) ? parsedSize : 2
            texto = linea[1]
        }

        let sizeBytes: [[UInt8]] = [
            [0x1d, 0x21, 0x00],
            [0x1b, 0x4d, 0x01],
            [0x1b, 0x4d, 0x00],
            [0x1d, 0x21, 0x11],
            [0x1d, 0x21, 0x22],
            [0x1d, 0x21, 0x33]
        ]
        let resetBytes: [UInt8] = [0x1b, 0x40]

        // Build one ordered payload (size + text + reset) and send it through the
        // same flow-controlled path so the three writes can no longer be dropped
        // or reordered under load.
        var payload = Data()
        payload.append(Data(sizeBytes[size]))
        if let textData = texto.data(using: .isoLatin1) ?? texto.data(using: .utf8) {
            payload.append(textData)
        }
        payload.append(Data(resetBytes))

        enqueueWrite(payload, result: result)
    }

    private func handleDisconnect(result: @escaping FlutterResult) {
        failAllJobs()
        if let peripheral = connectedPeripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
        connectedPeripheral = nil
        targetCharacteristic = nil
        result(true)
    }

    // =======================================================
    // Cola de escritura con control de flujo (BLE)
    // =======================================================

    private func enqueueWrite(_ data: Data, result: @escaping FlutterResult) {
        guard let peripheral = connectedPeripheral,
              peripheral.state == .connected,
              targetCharacteristic != nil else {
            result(false)
            return
        }
        guard !data.isEmpty else {
            result(true)
            return
        }

        let writeType: CBCharacteristicWriteType =
            targetCharacteristic!.properties.contains(.writeWithoutResponse) ? .withoutResponse : .withResponse
        writeJobs.append(WriteJob(data: data, offset: 0, writeType: writeType, result: result))
        drainWriteQueue()
    }

    /// Sends as many chunks as CoreBluetooth will currently accept, then parks
    /// until the relevant delegate callback resumes it. Runs on the CoreBluetooth
    /// callback queue (main), so no locking is needed.
    private func drainWriteQueue() {
        guard let peripheral = connectedPeripheral,
              peripheral.state == .connected,
              let characteristic = targetCharacteristic else {
            failAllJobs()
            return
        }

        while !writeJobs.isEmpty {
            let writeType = writeJobs[0].writeType

            // For write-without-response, only send while the controller has room.
            if writeType == .withoutResponse && !peripheral.canSendWriteWithoutResponse {
                scheduleWatchdog()
                return
            }

            let data = writeJobs[0].data
            let offset = writeJobs[0].offset
            // Never exceed the negotiated max write length for this write type
            // (a small ATT MTU can make 150 too large -> another silent drop).
            let maxLen = max(20, peripheral.maximumWriteValueLength(for: writeType))
            let chunkLen = min(preferredChunkSize, maxLen)
            let end = min(offset + chunkLen, data.count)
            let chunk = data.subdata(in: offset..<end)

            peripheral.writeValue(chunk, for: characteristic, type: writeType)
            writeJobs[0].offset = end
            writeProgress += 1

            if writeType == .withResponse {
                // Wait for didWriteValueFor; the peripheral paces us.
                scheduleWatchdog()
                return
            }

            // write-without-response: chunk handed to the controller.
            if writeJobs[0].offset >= data.count {
                let job = writeJobs.removeFirst()
                job.result(true)
                // fall through to start the next queued job (if any)
            }
            // else loop and re-check canSendWriteWithoutResponse
        }
    }

    /// Fails the head job if no write progress happens within the timeout window,
    /// so a stalled or powered-off printer can never hang the Dart future.
    private func scheduleWatchdog() {
        let snapshot = writeProgress
        DispatchQueue.main.asyncAfter(deadline: .now() + writeStallTimeout) { [weak self] in
            guard let self = self, !self.writeJobs.isEmpty else { return }
            if self.writeProgress == snapshot {
                let job = self.writeJobs.removeFirst()
                job.result(false)
                self.drainWriteQueue()
            }
        }
    }

    private func failAllJobs() {
        guard !writeJobs.isEmpty else { return }
        let jobs = writeJobs
        writeJobs.removeAll()
        for job in jobs {
            job.result(false)
        }
    }

    // =======================================================
    // CBCentralManagerDelegate
    // =======================================================

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("CoreBluetooth: Encendido y listo")
        case .poweredOff:
            print("CoreBluetooth: Apagado")
            failAllJobs()
            connectedPeripheral = nil
            targetCharacteristic = nil
        case .unauthorized:
            print("CoreBluetooth: No autorizado")
        default:
            break
        }
    }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let deviceName = peripheral.name, !deviceName.isEmpty {
            let deviceAddress = peripheral.identifier.uuidString
            let deviceEntry = "\(deviceName)#\(deviceAddress)"
            if !discoveredDevices.contains(deviceEntry) {
                discoveredDevices.append(deviceEntry)
            }
        }
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        failAllJobs()
        connectedPeripheral = nil
        targetCharacteristic = nil
    }

    // =======================================================
    // CBPeripheralDelegate
    // =======================================================

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error descubriendo servicios: \(error.localizedDescription)")
            return
        }

        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error descubriendo características: \(error.localizedDescription)")
            return
        }

        guard let characteristics = service.characteristics else { return }

        for characteristic in characteristics {
            if allowedCharacteristicUUIDs.contains(characteristic.uuid) ||
               characteristic.properties.contains(.write) ||
               characteristic.properties.contains(.writeWithoutResponse) {
                targetCharacteristic = characteristic
                print("Característica de impresión seleccionada: \(characteristic.uuid)")
                break
            }
        }
    }

    // Ack for .withResponse writes: advance to the next chunk / job.
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard !writeJobs.isEmpty else { return }
        writeProgress += 1

        if error != nil {
            let job = writeJobs.removeFirst()
            job.result(false)
            drainWriteQueue()
            return
        }

        if writeJobs[0].offset >= writeJobs[0].data.count {
            let job = writeJobs.removeFirst()
            job.result(true)
        }
        drainWriteQueue()
    }

    // Controller drained enough to accept more .withoutResponse writes: resume.
    public func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        drainWriteQueue()
    }
}
