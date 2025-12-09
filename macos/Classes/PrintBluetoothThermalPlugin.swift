import FlutterMacOS
import AppKit
import CoreBluetooth

public class PrintBluetoothThermalPlugin: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, FlutterPlugin {
    var centralManager: CBCentralManager?
    var discoveredDevices: [String] = []
    var connectedPeripheral: CBPeripheral!
    var targetService: CBService?
    var targetCharacteristic: CBCharacteristic?

    var flutterResult: FlutterResult?
    var bytes: [UInt8]?
    var stringprint = ""
    
    // Pending callbacks for Bluetooth state queries
    var pendingBluetoothEnabledResult: FlutterResult?
    var pendingPermissionResult: FlutterResult?
    
    // Allowed service and characteristic UUIDs for thermal printers
    let allowedServices = [
        CBUUID(string: "00001101-0000-1000-8000-00805F9B34FB"),
        CBUUID(string: "49535343-FE7D-4AE5-8FA9-9FAFD205E455"),
        CBUUID(string: "A76EB9E0-F3AC-4990-84CF-3A94D2426B2B")
    ]
    
    let allowedCharacteristics = [
        CBUUID(string: "00001101-0000-1000-8000-00805F9B34FB"),
        CBUUID(string: "49535343-8841-43F4-A8D4-ECBE34729BB3"),
        CBUUID(string: "A76EB9E2-F3AC-4990-84CF-3A94D2426B2B")
    ]

    override init() {
        super.init()
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "groons.web.app/print", binaryMessenger: registrar.messenger)
        let instance = PrintBluetoothThermalPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Initialize the central manager if not yet initialized
        if self.centralManager == nil {
            self.centralManager = CBCentralManager(delegate: self, queue: nil)
        }

        self.flutterResult = result

        if call.method == "getPlatformVersion" {
            let macOSVersion = ProcessInfo.processInfo.operatingSystemVersion
            let versionString = "\(macOSVersion.majorVersion).\(macOSVersion.minorVersion).\(macOSVersion.patchVersion)"
            result("macOS \(versionString)")
        } else if call.method == "bluetoothenabled" {
            // If state is unknown, wait for the delegate callback
            if centralManager?.state == .unknown {
                self.pendingBluetoothEnabledResult = result
            } else {
                switch centralManager?.state {
                case .poweredOn:
                    result(true)
                default:
                    result(false)
                }
            }
        } else if call.method == "ispermissionbluetoothgranted" {
            // If state is unknown, wait for the delegate callback
            if centralManager?.state == .unknown {
                self.pendingPermissionResult = result
            } else {
                switch centralManager?.state {
                case .poweredOn:
                    result(true)
                case .unauthorized:
                    result(false)
                default:
                    // On macOS, if not unauthorized and not unknown, permission is granted
                    // but Bluetooth might just be off
                    result(centralManager?.state != .unsupported)
                }
            }
        } else if call.method == "pairedbluetooths" {
            // Clear previous discovered devices
            discoveredDevices = []
            centralManager?.scanForPeripherals(withServices: nil, options: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.centralManager?.stopScan()
                result(self.discoveredDevices)
            }
        } else if call.method == "connect" {
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
            centralManager?.connect(peripheral, options: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                if peripheral.state == .connected {
                    self.connectedPeripheral = peripheral
                    self.connectedPeripheral.delegate = self
                    self.connectedPeripheral.discoverServices(nil)
                    result(true)
                } else {
                    result(false)
                }
            }
        } else if call.method == "connectionstatus" {
            result(connectedPeripheral?.state == .connected)
        } else if call.method == "disconnect" {
            if connectedPeripheral != nil {
                centralManager?.cancelPeripheralConnection(connectedPeripheral)
            }
            targetCharacteristic = nil
            result(true)
        } else if call.method == "writebytes" {
            // Flutter sends [Int], we need to convert to [UInt8]
            guard let arguments = call.arguments as? [Int] else {
                print("writebytes: Invalid arguments type")
                result(false)
                return
            }
            
            guard let characteristic = targetCharacteristic else {
                print("writebytes: No characteristic found for printing")
                result(false)
                return
            }
            
            guard connectedPeripheral != nil else {
                print("writebytes: No peripheral connected")
                result(false)
                return
            }
            
            // Convert [Int] to [UInt8]
            let bytesData = arguments.map { UInt8($0 & 0xFF) }
            let data = Data(bytesData)
            
            // Send in chunks of 150 bytes to avoid overwhelming the printer
            let chunkSize = 150
            var offset = 0
            
            while offset < data.count {
                let chunkRange = offset..<min(offset + chunkSize, data.count)
                let chunkData = data.subdata(in: chunkRange)
                
                let writeType: CBCharacteristicWriteType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
                connectedPeripheral.writeValue(chunkData, for: characteristic, type: writeType)
                
                offset += chunkSize
            }
            
            // Return success after sending all chunks
            result(true)
            
        } else if call.method == "printstring" {
            guard let stringArg = call.arguments as? String else {
                result(false)
                return
            }
            
            guard let characteristic = targetCharacteristic else {
                print("printstring: No characteristic found for printing")
                result(false)
                return
            }
            
            guard connectedPeripheral != nil else {
                print("printstring: No peripheral connected")
                result(false)
                return
            }
            
            self.stringprint = stringArg
            
            // Parse size and text
            var size = 2
            var texto = stringprint
            let parts = stringprint.components(separatedBy: "///")
            if parts.count > 1 {
                size = Int(parts[0]) ?? 2
                texto = parts[1]
                if size < 1 || size > 5 {
                    size = 2
                }
            }
            
            // ESC/POS size commands
            let sizeBytes: [[UInt8]] = [
                [0x1d, 0x21, 0x00], // Normal size 0
                [0x1b, 0x4d, 0x01], // Compressed ASCII 1
                [0x1b, 0x4d, 0x00], // Standard ASCII 2
                [0x1d, 0x21, 0x11], // Double height 3
                [0x1d, 0x21, 0x22], // Double height 4
                [0x1d, 0x21, 0x33]  // Double height 5
            ]
            let resetBytes: [UInt8] = [0x1b, 0x40]
            
            let writeType: CBCharacteristicWriteType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
            
            // Send size command
            let dataSize = Data(sizeBytes[size])
            connectedPeripheral.writeValue(dataSize, for: characteristic, type: writeType)
            
            // Send text
            let dataText = Data(texto.utf8)
            connectedPeripheral.writeValue(dataText, for: characteristic, type: writeType)
            
            // Send reset command
            let dataReset = Data(resetBytes)
            connectedPeripheral.writeValue(dataReset, for: characteristic, type: writeType)
            
            stringprint = ""
            result(true)
            
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // Handle pending bluetoothenabled request
        if let pendingResult = self.pendingBluetoothEnabledResult {
            switch central.state {
            case .poweredOn:
                pendingResult(true)
            default:
                pendingResult(false)
            }
            self.pendingBluetoothEnabledResult = nil
        }
        
        // Handle pending permission request
        if let pendingResult = self.pendingPermissionResult {
            switch central.state {
            case .poweredOn:
                pendingResult(true)
            case .unauthorized:
                pendingResult(false)
            default:
                // Permission granted but Bluetooth might be off
                pendingResult(central.state != .unsupported)
            }
            self.pendingPermissionResult = nil
        }
        
        if central.state == .poweredOn {
            print("Bluetooth is on")
        } else {
            print("Bluetooth is not available: \(central.state.rawValue)")
        }
    }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if let name = peripheral.name {
            let device = "\(name)#\(peripheral.identifier.uuidString)"
            if !discoveredDevices.contains(device) {
                discoveredDevices.append(device)
            }
        }
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        flutterResult?(error == nil)
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        
        if let services = peripheral.services {
            for service in services {
                print("Service discovered: \(service.uuid)")
                
                // Check if this is a known printer service
                if allowedServices.contains(service.uuid) {
                    print("Printer service found: \(service.uuid)")
                    self.targetService = service
                }
                
                // Discover characteristics for all services
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error discovering characteristics: \(error.localizedDescription)")
            return
        }
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                print("Characteristic found: \(characteristic.uuid)")
                
                // Check if this is a known printer characteristic
                if allowedCharacteristics.contains(characteristic.uuid) {
                    targetCharacteristic = characteristic
                    print("Target printer characteristic found: \(characteristic.uuid)")
                    
                    if characteristic.properties.contains(.write) {
                        print("Characteristic supports write with response")
                    }
                    if characteristic.properties.contains(.writeWithoutResponse) {
                        print("Characteristic supports write without response")
                    }
                    return // Found the right characteristic, stop searching
                }
                
                // Fallback: if no specific characteristic found, use any writable one
                if targetCharacteristic == nil {
                    if characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse) {
                        targetCharacteristic = characteristic
                        print("Using fallback writable characteristic: \(characteristic.uuid)")
                    }
                }
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error writing to characteristic: \(error.localizedDescription)")
            return
        }
        print("Successfully wrote to characteristic: \(characteristic.uuid)")
    }
}
