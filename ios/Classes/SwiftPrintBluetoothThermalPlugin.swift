import Flutter
import UIKit
import CoreBluetooth

public class SwiftPrintBluetoothThermalPlugin: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate,  FlutterPlugin {

    var centralManager: CBCentralManager?  // Define una variable para guardar el gestor central de bluetooth
    var discoveredDevices: [String] = []  //lista de bluetooths encontrados
    var connectedPeripheral: CBPeripheral!  //dispositivo conectado
    var targetService: CBService? // Variable global para el servicio objetivo
    //var characteristics: [CBCharacteristic] = [] // Variable global para almacenar las características encontradas
    var targetCharacteristic: CBCharacteristic? // Variable global para almacenar la característica objetivo


    var flutterResult: FlutterResult? //para el resul de flutter
    var bytes: [UInt8]? //variable para almacenar los bytes que llegan
    var stringprint = ""; //variable para almacenar los string que llegan

    // En el método init, inicializa el gestor central con un delegado
    //para solicitar el permiso del bluetooth
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "groons.web.app/print", binaryMessenger: registrar.messenger())
    let instance = SwiftPrintBluetoothThermalPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    //para iniciar la variable result
    self.flutterResult = result
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
        let macAddress = call.arguments as! String 
        // Busca el dispositivo con la dirección MAC dada
        let peripherals = centralManager?.retrievePeripherals(withIdentifiers: [UUID(uuidString: macAddress)!])
        guard let peripheral = peripherals?.first else {
          //print("No se encontró ningún dispositivo con la dirección MAC \(macAddress)")
          result(false)
          return
        }

        // Intenta conectar con el dispositivo
        centralManager?.connect(peripheral, options: nil)

        // Verifica si la conexión fue exitosa después de un tiempo de espera
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if peripheral.state == .connected {
                //print("Conexión exitosa con el dispositivo \(peripheral.name ?? "Desconocido")")
                self.connectedPeripheral = peripheral

                self.connectedPeripheral.delegate = self
                // Discover services of the connected peripheral
                //se ejecuta los servicios descubiertos en primer peripheral
                self.connectedPeripheral?.discoverServices(nil)
                result(true)
            } else {
                //print("La conexión con el dispositivo \(peripheral.name ?? "Desconocido") falló")
                result(false)
            }
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
          return
        }
        //let bytes = arguments
        self.bytes = arguments.map { UInt8($0) } //No se esta usando

        if let characteristic = targetCharacteristic {
            // Utiliza la variable characteristic desempaquetada aquí
            //print("bytes count: \(self.bytes?.count)")
            guard let listbytes = call.arguments as? [UInt8] else {
                // Manejar el caso en que los argumentos no son del tipo esperado
                return
            }
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
                self.connectedPeripheral?.writeValue(chunkData, for: characteristic, type: .withoutResponse)

                offset += chunkSize
            }
            //la respuesta va en peripheral
            //self.flutterResult?(true)
        } else {
            print("No hay caracteristica para imprimir")
            result(false)
        }

      } else if call.method == "printstring"{
        self.stringprint = call.arguments as! String
        //print("llego a printstring\(self.stringprint)")
        if let characteristic = targetCharacteristic {
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
                    connectedPeripheral?.writeValue(datasize, for: characteristic, type: .withoutResponse)

                    let data = Data(texto.utf8)
                    connectedPeripheral?.writeValue(data, for: characteristic, type: .withResponse) //.withResponse, .withoutResponse

                    // reseteo de la impresora
                    let datareset = Data(resetBytes)
                    connectedPeripheral?.writeValue(datareset, for: characteristic, type: .withoutResponse)
                    stringprint = ""

                    //la respuesta va en peripheral si es .withResponse
                    //self.flutterResult?(true)
                }
        } else {
            print("No hay caracteristica para imprimir")
            result(false)
        }
        } else if call.method == "disconnect"{
        centralManager?.cancelPeripheralConnection(connectedPeripheral)
        targetCharacteristic = nil
        //la respuesta va en centralManager segunda funcion
        //result(true)
      } else {
        result(FlutterMethodNotImplemented) // Si se llama otro método que no está implementado, se devuelve un error
      }
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

    //funcion para verificar si desconecto el dispositivo
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if error != nil {
            //print("Error al desconectar del dispositivo: \(error!.localizedDescription)")
            self.flutterResult?(false)
        } else {
        //print("Se ha desconectado del dispositivo con éxito")
         self.flutterResult?(true)
        }
    }

     //detectar los servicios descubiertos y guardarlo para poder imprimir
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
           if let error = error {
               print("Error discovering services: \(error.localizedDescription)")
               return
           }

           if let services = peripheral.services {
               for service in services {
                   print("Service discovered: \(service.uuid)")

                   // Verifica si el servicio es el que estás buscando
                   let targetServiceUUID = CBUUID(string: "00001101-0000-1000-8000-00805F9B34FB")
                   let targetServiceUUID2 =  CBUUID(string: "49535343-FE7D-4AE5-8FA9-9FAFD205E455")
                   if service.uuid == targetServiceUUID || service.uuid == targetServiceUUID2 {
                       print("Service found: \(service.uuid)") 
                       // Por ejemplo, puedes descubrir las características del servicio
                       peripheral.discoverCharacteristics(nil, for: service)

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
            return
        }

        if let discoveredCharacteristics = service.characteristics {
            for characteristic in discoveredCharacteristics {
                //print("characteristics found: \(characteristic.uuid)")
                if let characteristic = targetCharacteristic {
                    if characteristic.properties.contains(.write) {
                        // La característica admite escritura
                        print("characteristics found: \(characteristic.uuid) La característica admite escritura")
                    } else {
                        // La característica no admite escritura
                        print("characteristics found: \(characteristic.uuid) La característica no admite escritura")
                    }
                }

                let targetCharacteristicUUID = CBUUID(string: "00001101-0000-1000-8000-00805F9B34FB")
                let targetCharacteristicUUID2 =  CBUUID(string: "49535343-8841-43F4-A8D4-ECBE34729BB3")

                if characteristic.uuid == targetCharacteristicUUID || characteristic.uuid == targetCharacteristicUUID2 {
                    targetCharacteristic = characteristic // Guarda la característica objetivo en la variable global
                    print("Target characteristic found: \(characteristic.uuid)")
                    break
                }
            }
        }
    }

    // Implementación del método peripheral(_:didWriteValueFor:error:) para saber si la impresion fue exitosa si se pasa .withResponse
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
           print("Error al escribir en la característica: \(error.localizedDescription)")
            self.flutterResult?(false)
           return
        }
         self.flutterResult?(true)
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


