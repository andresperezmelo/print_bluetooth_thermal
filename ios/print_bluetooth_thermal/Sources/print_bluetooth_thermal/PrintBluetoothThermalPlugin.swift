import Flutter
import UIKit
import CoreBluetooth

@objc(PrintBluetoothThermalPlugin)
public class PrintBluetoothThermalPlugin: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate,  FlutterPlugin {
    var centralManager: CBCentralManager?  // Define una variable para guardar el gestor central de bluetooth
    var discoveredDevices: [String] = []  //lista de bluetooths encontrados
    var connectedPeripheral: CBPeripheral!  //dispositivo conectado
    var targetService: CBService? // Variable global para el servicio objetivo
    //var characteristics: [CBCharacteristic] = [] // Variable global para almacenar las características encontradas
    var targetCharacteristic: CBCharacteristic? // Variable global para almacenar la característica objetivo


    var flutterResult: FlutterResult? //para el resul de flutter
    var bytes: [UInt8]? //variable para almacenar los bytes que llegan
    var stringprint = ""; //variable para almacenar los string que llegan
    var pendingConnectResult: FlutterResult?
    var pendingConnectTimeout: DispatchWorkItem?
    var pendingConnectPeripheral: CBPeripheral?

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

    // En el método init, inicializa el gestor central con un delegado
    //para solicitar el permiso del bluetooth
    override init() {
        super.init()
    }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "groons.web.app/print", binaryMessenger: registrar.messenger())
    let instance = PrintBluetoothThermalPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    // En el método init, inicializa el gestor central con un delegado
    //para solicitar el permiso del bluetooth
    if (self.centralManager == nil) {
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    //result("iOS " + UIDevice.current.systemVersion)
    //let argumento = call.arguments as! String //leer el argumento recibido
    if call.method == "getPlatformVersion" { // Verifica si se está llamando el método "getPlatformVersion"
      let iosVersion = UIDevice.current.systemVersion // Obtiene la versión de iOS
      result("iOS " + iosVersion) // Devuelve el resultado como una cadena de texto
    } else if call.method == "getBatteryLevel" {
      let device = UIDevice.current
      let batteryState = device.batteryState
      let batteryLevel = device.batteryLevel * 100
      result(Int(batteryLevel))
    } else if call.method == "bluetoothenabled"{
      switch centralManager?.state {
      case .poweredOn:
          result(true)
      default:
          result(false)
      }
    } else if call.method == "ispermissionbluetoothgranted"{
      //let centralManager = CBCentralManager()
      if #available(iOS 10.0, *) {
        switch centralManager?.state {
        case .poweredOn:
          print("Bluetooth is on")
          result(true)
        default:
          print("Bluetooth is off")
          result(false)
        }
      }
    } else if call.method == "pairedbluetooths" {
      //print("buscando bluetooths");
      //let discoveredDevices = scanForBluetoothDevices(duration: 5.0)
      //print("Discovered devices: \(discoveredDevices)")
      switch centralManager?.state {
        case .unknown:
            //print("El estado del bluetooth es desconocido")
            break
        case .resetting:
            //print("El bluetooth se está reiniciando")
            break
        case .unsupported:
            //print("El bluetooth no es compatible con este dispositivo")
            break
        case .unauthorized:
            //print("El bluetooth no está autorizado para esta app")
            break
        case .poweredOff:
            //print("El bluetooth está apagado")
            centralManager?.stopScan()
        case .poweredOn:
            //print("El bluetooth está encendido")
            //Escanea todos los bluetooths disponibles
            centralManager?.scanForPeripherals(withServices: nil, options: nil)
            // Escanea todos los dispositivos Bluetooth vinculados
            centralManager?.retrieveConnectedPeripherals(withServices: [])
        @unknown default:
            //print("El estado del bluetooth es desconocido (default)")
            break
      }

        // despues de 5 segundos se para la busqueda y se devuelve la lista de dispositivos disponibles
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.centralManager?.stopScan()
            print("Stopped scanning -> Discovered devices: \(self.discoveredDevices.count)")
            result(self.discoveredDevices)
        }

    }
    else if call.method == "connect"{
        guard pendingConnectResult == nil else {
          result(false)
          return
        }
        guard let macAddress = call.arguments as? String,
              let uuid = UUID(uuidString: macAddress) else {
          result(false)
          return
        }
        // Busca el dispositivo con la dirección MAC dada
        let peripherals = centralManager?.retrievePeripherals(withIdentifiers: [uuid])
        guard let peripheral = peripherals?.first else {
          //print("No se encontró ningún dispositivo con la dirección MAC \(macAddress)")
          result(false)
          return
        }

        if peripheral.state == .connected && targetCharacteristic != nil {
            connectedPeripheral = peripheral
            result(true)
            return
        }

        targetService = nil
        targetCharacteristic = nil
        connectedPeripheral = peripheral
        connectedPeripheral.delegate = self
        pendingConnectResult = result
        pendingConnectPeripheral = peripheral

        let timeout = DispatchWorkItem { [weak self] in
            self?.completePendingConnect(false)
        }
        pendingConnectTimeout = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: timeout)

        if peripheral.state == .connected {
            peripheral.discoverServices(nil)
        } else {
            centralManager?.connect(peripheral, options: nil)
        }

    }else if call.method == "connectionstatus"{
      if connectedPeripheral?.state == CBPeripheralState.connected {
          //print("El dispositivo periférico está conectado.")
          result(true)
      } else {
          //print("El dispositivo periférico no está conectado.")
          result(false)
      }
    }else if call.method == "writebytes"{
        guard let arguments = call.arguments as? [Int] else {
          // Manejar el caso en que los argumentos no son del tipo esperado
          result(false)
          return
        }
        //let bytes = arguments
        self.bytes = arguments.map { UInt8($0 & 0xFF) } //No se esta usando

        if let characteristic = targetCharacteristic {
            guard connectedPeripheral != nil else {
                print("No hay periferico conectado")
                result(false)
                return
            }
            // Utiliza la variable characteristic desempaquetada aquí
            //print("bytes count: \(self.bytes?.count)")
            let listbytes = arguments.map { UInt8($0 & 0xFF) }
            //self.connectedPeripheral?.writeValue(Data(listbytes), for: characteristic, type: .withoutResponse) //.withResponse, .withoutResponse

            //Imprimir bloques de 150 bytes en la impresora para que no se sature
            let data: Data = Data(listbytes) // Datos que deseas imprimir
            let chunkSize = 150 // Tamaño de cada fragmento en bytes

            var offset = 0
            while offset < data.count {
                let chunkRange = offset..<min(offset + chunkSize, data.count)
                let chunkData = data.subdata(in: chunkRange)
                //print("chunkData count: \(chunkData.count)")
                // Envía el fragmento para imprimir utilizando la característica deseada

                var writeType = CBCharacteristicWriteType.withoutResponse;
                if characteristic.properties.contains(.write) {
                   writeType = CBCharacteristicWriteType.withResponse;
                }

                 self.connectedPeripheral?.writeValue(chunkData, for: characteristic, type: writeType)

                offset += chunkSize
            }
            result(true)
        } else {
            print("No hay caracteristica para imprimir")
            result(false)
        }

      } else if call.method == "printstring"{
        guard let stringArg = call.arguments as? String else {
            result(false)
            return
        }
        self.stringprint = stringArg
        //print("llego a printstring\(self.stringprint)")
        if let characteristic = targetCharacteristic {
            guard connectedPeripheral != nil else {
                print("No hay periferico conectado")
                result(false)
                return
            }

            if self.stringprint.count > 0 {
                    //ver el tamaño del texto
                    var size = 0
                    var texto = ""
                    let linea = self.stringprint.components(separatedBy: "///")
                    if linea.count > 1 {
                        size = Int(linea[0]) ?? 0
                        texto = String(linea[1])
                        if size < 1 || size > 5 {
                            size = 2
                        }
                    } else {
                        size = 2
                        texto = self.stringprint
                    }
                    let sizeBytes: [[UInt8]] = [
                                [0x1d, 0x21, 0x00], // La fuente no se agranda 0
                                [0x1b, 0x4d, 0x01], // Fuente ASCII comprimida 1
                                [0x1b, 0x4d, 0x00], //Fuente estándar ASCII    2
                                [0x1d, 0x21, 0x11], // Altura doblada 3
                                [0x1d, 0x21, 0x22], // Altura doblada 4
                                [0x1d, 0x21, 0x33] // Altura doblada 5
                            ]
                    let resetBytes: [UInt8] = [0x1b, 0x40]

                    // Envío de los datos
                    let datasize = Data(sizeBytes[size])

                    var writeType = CBCharacteristicWriteType.withoutResponse;
                    if characteristic.properties.contains(.write) {
                        writeType = CBCharacteristicWriteType.withResponse;
                    }

                    connectedPeripheral?.writeValue(datasize, for: characteristic, type: writeType)

                    let data = Data(texto.utf8)
                    connectedPeripheral?.writeValue(data, for: characteristic, type: writeType)

                    // reseteo de la impresora
                    let datareset = Data(resetBytes)
                    connectedPeripheral?.writeValue(datareset, for: characteristic, type: writeType)
                    stringprint = ""

                    result(true)
                } else {
                    result(false)
                }
        } else {
            print("No hay caracteristica para imprimir")
            result(false)
        }
        } else if call.method == "disconnect"{
        if connectedPeripheral != nil {
            centralManager?.cancelPeripheralConnection(connectedPeripheral)
        }
        targetCharacteristic = nil
        result(true)
      } else {
        result(FlutterMethodNotImplemented) // Si se llama otro método que no está implementado, se devuelve un error
      }
  }

    private func completePendingConnect(_ success: Bool) {
        guard let result = pendingConnectResult else {
            return
        }

        pendingConnectTimeout?.cancel()
        pendingConnectTimeout = nil
        pendingConnectResult = nil
        pendingConnectPeripheral = nil
        result(success)
    }


    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        //print("Discovered \(peripheral.name ?? "Unknown") at \(RSSI) dBm")
        if let deviceName = peripheral.name {
            let deviceAddress = peripheral.identifier.uuidString
            //print("name \(deviceName) Address: \(deviceAddress)")
            let device = "\(deviceName)#\(deviceAddress)"
            if !discoveredDevices.contains(device) {
                discoveredDevices.append(device)
            }
        }
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        connectedPeripheral.delegate = self
        targetService = nil
        targetCharacteristic = nil
        peripheral.discoverServices(nil)
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if pendingConnectPeripheral?.identifier == peripheral.identifier {
            completePendingConnect(false)
        }
    }

    //funcion para verificar si desconecto el dispositivo
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if pendingConnectPeripheral?.identifier == peripheral.identifier {
            completePendingConnect(false)
        }

        if connectedPeripheral?.identifier == peripheral.identifier {
            connectedPeripheral = nil
            targetService = nil
            targetCharacteristic = nil
        }
    }

     //detectar los servicios descubiertos y guardarlo para poder imprimir
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
           if let error = error {
               print("Error discovering services: \(error.localizedDescription)")
               if pendingConnectPeripheral?.identifier == peripheral.identifier {
                   completePendingConnect(false)
               }
               return
           }

           if let services = peripheral.services {
               for service in services {
                   print("Service discovered: \(service.uuid)")

                   if allowedServices.contains(service.uuid) {
                       print("Service found: \(service.uuid)")
                       // También puedes almacenar el servicio en una variable para futuras referencias
                       // targetService = service
                       self.targetService = service;
                   }

                   // Aquí puedes realizar operaciones adicionales con cada servicio encontrado, como descubrir características
                   peripheral.discoverCharacteristics(nil, for: service)
               }
           }
    }

    // Implementación del método peripheral(_:didDiscoverCharacteristicsFor:error:) para buscar las caracteristicas del dispositivo bluetooth
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error discovering characteristics: \(error.localizedDescription)")
            if pendingConnectPeripheral?.identifier == peripheral.identifier {
                completePendingConnect(false)
            }
            return
        }

        if let discoveredCharacteristics = service.characteristics {
            for characteristic in discoveredCharacteristics {
                //print("characteristics found: \(characteristic.uuid)")

                if allowedCharacteristics.contains(characteristic.uuid) {
                    targetCharacteristic = characteristic // Guarda la característica objetivo en la variable global
                    print("Target characteristic found: \(characteristic.uuid)")

                    if characteristic.properties.contains(.write) {
                        // La característica admite escritura
                        print("characteristics found: \(characteristic.uuid) La característica admite escritura")
                    } else {
                        // La característica no admite escritura
                        print("characteristics found: \(characteristic.uuid) La característica no admite escritura")
                    }
                    completePendingConnect(true)
                    return
                }

                if targetCharacteristic == nil && targetService?.uuid == service.uuid {
                    if characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse) {
                        targetCharacteristic = characteristic
                        print("Using fallback writable characteristic: \(characteristic.uuid)")
                        completePendingConnect(true)
                    }
                }
            }
        }
    }

    // Implementación del método peripheral(_:didWriteValueFor:error:) para saber si la impresion fue exitosa si se pasa .withResponse
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
           print("Error al escribir en la característica: \(error.localizedDescription)")
           return
        }
        print("Escritura exitosa en la característica: \(characteristic.uuid)")
        // Aquí puedes realizar operaciones adicionales con la respuesta de la escritura
    }

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
            case .poweredOn:
                // El bluetooth está encendido y listo para usar
                print("Bluetooth está encendido")
            case .poweredOff:
                // El bluetooth está apagado
                print("Bluetooth está apagado")
            case .resetting:
                // El bluetooth está reiniciándose
                print("Bluetooth está reiniciándose")
            case .unauthorized:
                // La app no tiene permiso para usar el bluetooth
                print("La app no tiene permiso para usar el bluetooth")
            case .unsupported:
                // El dispositivo no soporta el bluetooth
                print("El dispositivo no soporta el bluetooth")
            case .unknown:
                // El estado del bluetooth es desconocido
                print("El estado del bluetooth es desconocido")
            @unknown default:
                // Otro caso no esperado
                print("Otro caso no esperado")
        }
    }

}


