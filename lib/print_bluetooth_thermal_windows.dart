import 'dart:async';

import 'package:flutter/services.dart';
import 'package:win_ble/win_ble.dart';
import 'package:win_ble/win_file.dart';

import 'print_bluetooth_thermal.dart';

class PrintBluetoothThermalWindows {
  static bool _isInitialized = false;

  static bool _scanning = false;
  static List<BluetoothInfo> _bluetooths = [];
  static StreamSubscription? _scanStream;

  static StreamSubscription? _connectionStream;
  static String _macAddressConnect = "";

  //para enviar la impresion
  static String _serviceSelect = ""; //"00001101-0000-1000-8000-00805F9B34FB";
  static BleCharacteristic? _bleCharacteristicSelect;

  static Future<void> initialize() async {
    if (!_isInitialized) {
      // Lógica de inicialización que solo debe ejecutarse una vez
      await WinBle.initialize(serverPath: await WinServer.path(), enableLog: false);

      // Marcar como inicializado
      _isInitialized = true;
    }
  }

  static Future<List<BluetoothInfo>> getPariedBluetoohts() async {
    await initialize();
    if (_scanning) return [];

    _bluetooths = [];
    WinBle.startScanning();

    if (_scanStream != null) _scanStream!.cancel();
    _scanStream = WinBle.scanStream.listen((BleDevice event) {
      //print("device name: ${event.name}");
      // Get Devices Here
      bool add = true;
      for (BluetoothInfo bleDevice in _bluetooths) {
        //si el bluetooth address y name es igual no agregar, ya esta agregado
        if (bleDevice.macAdress == event.address) {
          add = false;
          break;
        }
      }
      //add bluetooth in list
      //print("event: ${event.name} add: $add isNotEmpty: ${event.name.trim().isNotEmpty}");
      if (add && event.name.trim().isNotEmpty) {
        _bluetooths.add(BluetoothInfo(name: event.name, macAdress: event.address));
      }
    });

    //Await five seconds for scanning devices
    await Future.delayed(const Duration(seconds: 5));
    WinBle.stopScanning();
    _scanStream?.cancel();
    _scanning = false;

    return _bluetooths;
  }

  static Future<bool> connect({required String macAddress}) async {
    if (_macAddressConnect.isNotEmpty) return true; // Ya está conectado.

    Completer<bool> connectionCompleter = Completer<bool>();

    if (_connectionStream != null) _connectionStream!.cancel();
    _connectionStream = WinBle.connectionStreamOf(macAddress).listen((bool status) async {
      if (status) {
        //_macAddressConnect = macAddress;
        connectionCompleter.complete(true);
        print("connect status: $status");
      } else {
        //print("Finalizó el stream $event");
        if (!connectionCompleter.isCompleted) connectionCompleter.complete(true); // Completar con error la Future en caso de desconexión.
      }
    });

    // Realizar la conexión
    await WinBle.connect(macAddress);

    // Esperar que la conexion finalice
    await connectionCompleter.future;
    //cancelar el stream
    if (_connectionStream != null) _connectionStream?.cancel();

    //print("complete ${DateTime.now().toString()}");
    //buscar el servicio y caracteristica para imprimir
    List<String> services = await WinBle.discoverServices(macAddress);
    //print("Services: ${services.length}");
    for (String service in services) {
      //print("service: $service");
      List<BleCharacteristic> bleCharacteristics = await WinBle.discoverCharacteristics(address: macAddress, serviceId: service);
      //print("bleCharacteristics: ${bleCharacteristics.length}");
      for (BleCharacteristic characteristic in bleCharacteristics) {
        //print("service: $service -> bleCharacteristic: ${characteristic.properties.toJson()}");
        if (characteristic.properties.write ?? false) {
          _serviceSelect = service;
          _bleCharacteristicSelect = characteristic;
          _macAddressConnect = macAddress;
          print("macAddress: $macAddress service: $service");
          break;
        }
      }
    }
    //return if not empty si success connection
    return _macAddressConnect.isNotEmpty;
  }

  static Future<bool> writeBytes({required List<int> bytes}) async {
    // To Write Characteristic
    try {
      print("Writing: _macAddressConnect: $_macAddressConnect service: $_serviceSelect caractericsUid: ${_bleCharacteristicSelect?.uuid}");
      await WinBle.write(
        address: _macAddressConnect,
        service: _serviceSelect,
        characteristic: _bleCharacteristicSelect!.uuid,
        data: Uint8List.fromList(bytes),
        writeWithResponse: true,
      );
      return true;
    } catch (e) {
      print("PrintBluettothTermalWindows.writyBytes -> error: $e");
      disconnect();
      return false;
    }
  }

  static Future<bool> disconnect() async {
    if (_macAddressConnect.isNotEmpty) await WinBle.disconnect(_macAddressConnect);
    _macAddressConnect = "";
    _bluetooths = [];
    return true;
  }

  static bool get connectionStatus {
    return _macAddressConnect.isEmpty ? false : true;
  }

  static Future<void> notImplemented() async {
    print("Not implemented on Windows");
  }
}
