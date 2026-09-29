import Flutter
import UIKit
import CoreBluetooth

@objc(PrintBluetoothThermalPlugin)
public class PrintBluetoothThermalPlugin: NSObject, FlutterPlugin, CBCentralManagerDelegate, CBPeripheralDelegate {

    private var centralManager: CBCentralManager?
    private var connectedPeripheral: CBPeripheral?
    private var targetCharacteristic: CBCharacteristic?
    private var pendingConnectResult: FlutterResult?
    private var connectAttempt = 0
    private var remainingCharacteristicServices = 0
    private var fallbackCharacteristic: CBCharacteristic?
    private var discoveredDevices: [String] = []

    // Control de flujo para escritura
    private var pendingData: Data = Data()
    private var pendingResult: FlutterResult?
    private var writeWatchdogTimer: Timer?

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
                result(CBCentralManager.authorization == .allowedAlways)
            } else if #available(iOS 13.0, *) {
                result((centralManager?.authorization ?? .notDetermined) == .allowedAlways)
            } else {
                result(centralManager?.state == .poweredOn)
            }

        case "pairedbluetooths":
            handleScanDevices(result: result)

        case "connect":
            handleConnect(call: call, result: result)

        case "connectionstatus":
            result(connectedPeripheral?.state == .connected && targetCharacteristic != nil)

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
    // Handlers
    // =======================================================

    private func handleScanDevices(result: @escaping FlutterResult) {
        discoveredDevices.removeAll()
        guard centralManager?.state == .poweredOn else {
            result(discoveredDevices)
            return
        }

        let connectedList = centralManager?.retrieveConnectedPeripherals(withServices: allowedServiceUUIDs) ?? []
        for peripheral in connectedList {
            let name = peripheral.name ?? "Unknown"
            let deviceEntry = "\(name)#\(peripheral.identifier.uuidString)"
            if !discoveredDevices.contains(deviceEntry) {
                discoveredDevices.append(deviceEntry)
            }
        }

        centralManager?.scanForPeripherals(withServices: nil, options: nil)

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

        guard pendingConnectResult == nil else {
            result(false)
            return
        }

        if connectedPeripheral?.identifier == peripheral.identifier,
           peripheral.state == .connected,
           targetCharacteristic != nil {
            result(true)
            return
        }

        connectedPeripheral = peripheral
        connectedPeripheral?.delegate = self
        completePendingWrite(success: false)
        targetCharacteristic = nil
        fallbackCharacteristic = nil
        remainingCharacteristicServices = 0
        pendingConnectResult = result
        connectAttempt += 1
        let attempt = connectAttempt

        if peripheral.state == .connected {
            peripheral.discoverServices(nil)
        } else {
            centralManager?.connect(peripheral, options: nil)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) { [weak self] in
            guard let self = self, self.connectAttempt == attempt else { return }
            self.completePendingConnect(success: false)
        }
    }

    private func completePendingConnect(success: Bool) {
        guard let result = pendingConnectResult else { return }
        pendingConnectResult = nil
        result(success)
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

        guard let data = rawData,
              let peripheral = connectedPeripheral,
              let characteristic = targetCharacteristic,
              peripheral.state == .connected else {
            result(false)
            return
        }

        // Si ya había una escritura en proceso, terminamos la anterior con error
        if pendingResult != nil {
            completePendingWrite(success: false)
        }

        self.pendingData = data
        self.pendingResult = result

        // Iniciar un watchdog de 10s para evitar que el Future quede colgado si la impresora se apaga
        startWatchdog()

        // Comenzar a drenar los datos con control de flujo
        sendNextChunk()
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

        // Empaquetar todo en un solo payload y usar el mismo control de flujo
        var fullData = Data(sizeBytes[size])
        if let textData = texto.data(using: .isoLatin1) ?? texto.data(using: .utf8) {
            fullData.append(textData)
        }
        fullData.append(Data(resetBytes))

        guard let peripheral = connectedPeripheral,
              let characteristic = targetCharacteristic,
              peripheral.state == .connected else {
            result(false)
            return
        }

        if pendingResult != nil {
            completePendingWrite(success: false)
        }

        self.pendingData = fullData
        self.pendingResult = result
        startWatchdog()
        sendNextChunk()
    }

    // =======================================================
    // Flujo de Control BLE (Drenado de paquetes)
    // =======================================================

    private func sendNextChunk() {
        guard let peripheral = connectedPeripheral,
              let characteristic = targetCharacteristic,
              pendingResult != nil else { return }

        // Reiniciar watchdog: mientras haya progreso, no se reinicia para evitar el corte en imagenes pesadas
        startWatchdog()

        let writeType: CBCharacteristicWriteType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
        let maxChunk = peripheral.maximumWriteValueLength(for: writeType)
        let chunkSize = min(maxChunk > 0 ? maxChunk : 150, 150)

        if writeType == .withoutResponse {
            // Mientras iOS tenga espacio en el buffer y queden datos por enviar
            while !pendingData.isEmpty && peripheral.canSendWriteWithoutResponse {
                let bytesToSend = min(chunkSize, pendingData.count)
                let chunk = pendingData.subdata(in: 0..<bytesToSend)
                pendingData.removeSubrange(0..<bytesToSend)

                peripheral.writeValue(chunk, for: characteristic, type: .withoutResponse)
            }

            // Si ya no quedan datos, la escritura terminó exitosamente
            if pendingData.isEmpty {
                completePendingWrite(success: true)
            }
            // Si aún quedan datos pero canSendWriteWithoutResponse es false,
            // nos detenemos y esperamos a peripheralIsReady(toSendWriteWithoutResponse:)
        } else {
            // Con respuesta: enviar 1 chunk y esperar didWriteValueFor
            if !pendingData.isEmpty {
                let bytesToSend = min(chunkSize, pendingData.count)
                let chunk = pendingData.subdata(in: 0..<bytesToSend)
                pendingData.removeSubrange(0..<bytesToSend)

                peripheral.writeValue(chunk, for: characteristic, type: .withResponse)
            } else {
                completePendingWrite(success: true)
            }
        }
    }

    private func startWatchdog() {
        writeWatchdogTimer?.invalidate()
        writeWatchdogTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            self?.completePendingWrite(success: false)
        }
    }

    private func completePendingWrite(success: Bool) {
        writeWatchdogTimer?.invalidate()
        writeWatchdogTimer = nil
        pendingData.removeAll()
        pendingResult?(success)
        pendingResult = nil
    }

    private func handleDisconnect(result: @escaping FlutterResult) {
        completePendingConnect(success: false)
        completePendingWrite(success: false)
        if let peripheral = connectedPeripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
        connectedPeripheral = nil
        targetCharacteristic = nil
        result(true)
    }

    // =======================================================
    // CBCentralManagerDelegate
    // =======================================================

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            completePendingConnect(success: false)
            completePendingWrite(success: false)
            connectedPeripheral = nil
            targetCharacteristic = nil
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
        guard connectedPeripheral?.identifier == peripheral.identifier else { return }
        completePendingConnect(success: false)
        completePendingWrite(success: false)
        connectedPeripheral = nil
        targetCharacteristic = nil
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard connectedPeripheral?.identifier == peripheral.identifier else { return }
        peripheral.discoverServices(nil)
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        guard connectedPeripheral?.identifier == peripheral.identifier else { return }
        completePendingConnect(success: false)
        connectedPeripheral = nil
        targetCharacteristic = nil
    }

    // =======================================================
    // CBPeripheralDelegate
    // =======================================================

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard connectedPeripheral?.identifier == peripheral.identifier else { return }
        guard error == nil, let services = peripheral.services, !services.isEmpty else {
            completePendingConnect(success: false)
            return
        }
        remainingCharacteristicServices = services.count
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard connectedPeripheral?.identifier == peripheral.identifier,
              remainingCharacteristicServices > 0 else { return }
        if error == nil, let characteristics = service.characteristics {
            for characteristic in characteristics {
                let writable = characteristic.properties.contains(.write) ||
                    characteristic.properties.contains(.writeWithoutResponse)
                guard writable else { continue }
                if allowedCharacteristicUUIDs.contains(characteristic.uuid) {
                    if targetCharacteristic == nil { targetCharacteristic = characteristic }
                } else if fallbackCharacteristic == nil {
                    fallbackCharacteristic = characteristic
                }
            }
        }
        remainingCharacteristicServices -= 1
        if remainingCharacteristicServices == 0 {
            targetCharacteristic = targetCharacteristic ?? fallbackCharacteristic
            completePendingConnect(success: targetCharacteristic != nil)
        }
    }

    // LLAMADO CUANDO EL BUFFER BLE VUELVE A TENER ESPACIO (.withoutResponse)
    public func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        sendNextChunk()
    }

    // LLAMADO CUANDO LA IMPRESORA CONFIRMA RECEPCIÓN (.withResponse)
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            completePendingWrite(success: false)
        } else {
            sendNextChunk()
        }
    }
}