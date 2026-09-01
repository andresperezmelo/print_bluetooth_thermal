import FlutterMacOS
import AppKit
import CoreBluetooth

@objc(PrintBluetoothThermalPlugin)
public class PrintBluetoothThermalPlugin: NSObject, FlutterPlugin, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    private var centralManager: CBCentralManager?
    private var connectedPeripheral: CBPeripheral?
    private var targetCharacteristic: CBCharacteristic?
    private var discoveredDevices: [String] = []

    // Callbacks pendientes si el estado inicial de Bluetooth es .unknown
    private var pendingBluetoothEnabledResult: FlutterResult?
    private var pendingPermissionResult: FlutterResult?

    // UUIDs de servicios comunes en impresoras térmicas BLE
    private let allowedServices = [
        CBUUID(string: "00001101-0000-1000-8000-00805F9B34FB"),
        CBUUID(string: "49535343-FE7D-4AE5-8FA9-9FAFD205E455"),
        CBUUID(string: "A76EB9E0-F3AC-4990-84CF-3A94D2426B2B"),
        CBUUID(string: "E7810A71-73AE-499D-8C15-FAA9AEF0C3F2"),
        CBUUID(string: "18F0")
    ]
    
    // UUIDs de características de escritura
    private let allowedCharacteristics = [
        CBUUID(string: "00001101-0000-1000-8000-00805F9B34FB"),
        CBUUID(string: "49535343-8841-43F4-A8D4-ECBE34729BB3"),
        CBUUID(string: "A76EB9E2-F3AC-4990-84CF-3A94D2426B2B"),
        CBUUID(string: "E7810A71-73AE-499D-8C15-FAA9AEF0C3F2"),
        CBUUID(string: "BEF8D6C9-9C21-4C9E-B632-BD58C1009F9F")
    ]

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "groons.web.app/print", binaryMessenger: registrar.messenger)
        let instance = PrintBluetoothThermalPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }

        switch call.method {
        case "getPlatformVersion":
            let osVersion = ProcessInfo.processInfo.operatingSystemVersion
            result("macOS \(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)")

        case "bluetoothenabled":
            if centralManager?.state == .unknown {
                pendingBluetoothEnabledResult = result
            } else {
                result(centralManager?.state == .poweredOn)
            }

        case "ispermissionbluetoothgranted":
            handlePermissionCheck(result: result)

        case "pairedbluetooths":
            handleScanDevices(result: result)

        case "connect":
            handleConnect(call: call, result: result)

        case "connectionstatus":
            result(connectedPeripheral?.state == .connected)

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

    private func handlePermissionCheck(result: @escaping FlutterResult) {
        if #available(macOS 10.15, *) {
            let auth = CBCentralManager.authorization
            if auth == .allowedAlways {
                result(true)
                return
            } else if auth == .denied || auth == .restricted {
                result(false)
                return
            }
        }

        // Fallback si aún no se determina el estado
        if centralManager?.state == .unknown {
            pendingPermissionResult = result
        } else {
            switch centralManager?.state {
            case .poweredOn:
                result(true)
            case .unauthorized:
                result(false)
            default:
                result(centralManager?.state != .unsupported)
            }
        }
    }

    private func handleScanDevices(result: @escaping FlutterResult) {
        discoveredDevices.removeAll()

        guard centralManager?.state == .poweredOn else {
            result(discoveredDevices)
            return
        }

        // Recuperar periféricos ya conectados con servicios compatibles
        let connectedList = centralManager?.retrieveConnectedPeripherals(withServices: allowedServices) ?? []
        for peripheral in connectedList {
            let name = peripheral.name ?? "Unknown"
            let entry = "\(name)#\(peripheral.identifier.uuidString)"
            if !discoveredDevices.contains(entry) {
                discoveredDevices.append(entry)
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

        connectedPeripheral = peripheral
        connectedPeripheral?.delegate = self
        centralManager?.connect(peripheral, options: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
            guard let self = self else { return }
            if self.connectedPeripheral?.state == .connected {
                self.connectedPeripheral?.discoverServices(self.allowedServices)
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

        guard let data = rawData,
              let peripheral = connectedPeripheral,
              let characteristic = targetCharacteristic else {
            result(false)
            return
        }

        let chunkSize = 150
        var offset = 0
        let writeType: CBCharacteristicWriteType = characteristic.properties.contains(.writeWithoutResponse) ? .withoutResponse : .withResponse

        while offset < data.count {
            let chunkRange = offset..<min(offset + chunkSize, data.count)
            let chunkData = data.subdata(in: chunkRange)
            peripheral.writeValue(chunkData, for: characteristic, type: writeType)
            offset += chunkSize
        }

        result(true)
    }

    private func handlePrintString(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let rawString = call.arguments as? String,
              let peripheral = connectedPeripheral,
              let characteristic = targetCharacteristic else {
            result(false)
            return
        }

        var size = 2
        var texto = rawString
        let parts = rawString.components(separatedBy: "///")

        if parts.count > 1 {
            let parsedSize = Int(parts[0]) ?? 2
            size = (parsedSize >= 1 && parsedSize <= 5) ? parsedSize : 2
            texto = parts[1]
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

        let writeType: CBCharacteristicWriteType = characteristic.properties.contains(.writeWithoutResponse) ? .withoutResponse : .withResponse

        peripheral.writeValue(Data(sizeBytes[size]), for: characteristic, type: writeType)
        if let textData = texto.data(using: .isoLatin1) ?? texto.data(using: .utf8) {
            peripheral.writeValue(textData, for: characteristic, type: writeType)
        }
        peripheral.writeValue(Data(resetBytes), for: characteristic, type: writeType)

        result(true)
    }

    private func handleDisconnect(result: @escaping FlutterResult) {
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
        // Resolver peticiones pendientes de estado
        if let pendingResult = pendingBluetoothEnabledResult {
            pendingResult(central.state == .poweredOn)
            pendingBluetoothEnabledResult = nil
        }

        if let pendingResult = pendingPermissionResult {
            switch central.state {
            case .poweredOn:
                pendingResult(true)
            case .unauthorized:
                pendingResult(false)
            default:
                pendingResult(central.state != .unsupported)
            }
            pendingPermissionResult = nil
        }
    }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if let name = peripheral.name, !name.isEmpty {
            let entry = "\(name)#\(peripheral.identifier.uuidString)"
            if !discoveredDevices.contains(entry) {
                discoveredDevices.append(entry)
            }
        }
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectedPeripheral = nil
        targetCharacteristic = nil
    }

    // =======================================================
    // CBPeripheralDelegate
    // =======================================================

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("macOS BT: Error descubriendo servicios: \(error.localizedDescription)")
            return
        }

        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("macOS BT: Error descubriendo características: \(error.localizedDescription)")
            return
        }

        guard let characteristics = service.characteristics else { return }

        for characteristic in characteristics {
            // 1. Coincidencia con UUIDs conocidos
            if allowedCharacteristics.contains(characteristic.uuid) {
                targetCharacteristic = characteristic
                break
            }
            // 2. Fallback: cualquier característica que permita escritura
            if targetCharacteristic == nil {
                if characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse) {
                    targetCharacteristic = characteristic
                }
            }
        }
    }
}