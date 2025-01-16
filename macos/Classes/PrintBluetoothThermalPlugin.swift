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

    override init() {
        super.init()
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "groons.web.app/print", binaryMessenger: registrar.messenger)
        let instance = PrintBluetoothThermalPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Inicializar el gestor central si aún no está inicializado
        if self.centralManager == nil {
            self.centralManager = CBCentralManager(delegate: self, queue: nil)
        }

        self.flutterResult = result

        if call.method == "getPlatformVersion" {
            let macOSVersion = ProcessInfo.processInfo.operatingSystemVersion
            let versionString = "\(macOSVersion.majorVersion).\(macOSVersion.minorVersion).\(macOSVersion.patchVersion)"
            result("macOS \(versionString)")
        } else if call.method == "bluetoothenabled" {
            switch centralManager?.state {
            case .poweredOn:
                result(true)
            default:
                result(false)
            }
        } else if call.method == "pairedbluetooths" {
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
            centralManager?.cancelPeripheralConnection(connectedPeripheral)
            targetCharacteristic = nil
            result(true)
        } else if call.method == "writebytes" {
            guard let arguments = call.arguments as? [UInt8],
                  let characteristic = targetCharacteristic else {
                result(false)
                return
            }
            let data = Data(arguments)
            let writeType: CBCharacteristicWriteType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
            connectedPeripheral?.writeValue(data, for: characteristic, type: writeType)
        } else if call.method == "printstring" {
            guard let string = call.arguments as? String,
                  let characteristic = targetCharacteristic else {
                result(false)
                return
            }
            let data = Data(string.utf8)
            connectedPeripheral?.writeValue(data, for: characteristic, type: .withoutResponse)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("Bluetooth está encendido")
        } else {
            print("Bluetooth no está disponible")
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
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                targetCharacteristic = characteristic
                break
            }
        }
    }
}

