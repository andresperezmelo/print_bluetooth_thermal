import 'dart:async';
import 'package:flutter/services.dart';

class PrintBluetoothThermal {
  static const MethodChannel _channel = MethodChannel('groons.web.app/print');

  // Private constructor
  PrintBluetoothThermal._privateConstructor() {
    initializeBluetooth(); // Consider calling initialize here if it's appropriate for your use case.
  }

  // Static private instance of the class
  static final PrintBluetoothThermal _instance =
      PrintBluetoothThermal._privateConstructor();

  // Public static getter for the instance
  static PrintBluetoothThermal get instance => _instance;

  // Initialize Bluetooth connection
  Future<void> initializeBluetooth() async {
    try {
      final String result = await _channel.invokeMethod('initializeBluetooth');
      print(result); // Should print "Bluetooth central manager initialized"
    } on PlatformException catch (e) {
      print("Failed to initialize Bluetooth: '${e.message}'.");
    }
  }

  // Converted instance methods
  Future<bool> isPermissionBluetoothGranted() async {
    bool bluetoothState = false;
    try {
      bluetoothState =
          await _channel.invokeMethod('ispermissionbluetoothgranted');
    } on PlatformException catch (e) {
      print("Failed Bluetooth status: '${e.message}'.");
    }
    return bluetoothState;
  }

  Future<bool> bluetoothEnabled() async {
    bool bluetoothState = false;
    try {
      bluetoothState = await _channel.invokeMethod('bluetoothenabled');
    } on PlatformException catch (e) {
      print("Failed Bluetooth status: '${e.message}'.");
    }
    return bluetoothState;
  }

  Future<List<BluetoothInfo>> pairedBluetooths() async {
    List<BluetoothInfo> items = [];
    try {
      final List<dynamic> result =
          await _channel.invokeMethod('pairedbluetooths');
      for (var element in result) {
        String item = element as String;
        List<String> info = item.split("#");
        items.add(BluetoothInfo(name: info[0], macAdress: info[1]));
      }
    } on PlatformException catch (e) {
      print("Failed pairedBluetooths: '${e.message}'.");
    }
    return items;
  }

  //returns true if you are currently connected to the printer
  Future<bool> get connectionStatus async {
    //estado de la conexion eon el bluetooth
    try {
      final bool result = await _channel.invokeMethod('connectionstatus');
      //print("llego: $result");
      return result;
    } on PlatformException catch (e) {
      print("Failed state conecction: '${e.message}'.");
      return false;
    }
  }

  ///send connection to ticket printer and wait true if it was successful, the mac address of the printer's bluetooth must be sent
  Future<bool> connect({required String macPrinterAddress}) async {
    //conectar impresora bluetooth
    bool result = false;

    String mac = macPrinterAddress; //"66:02:BD:06:18:7B";

    try {
      result = await _channel.invokeMethod('connect', mac);
      print("result status connect: $result");
    } on PlatformException catch (e) {
      print("Failed to connect: ${e.message}");
    }
    return result;
  }

  ///send bytes to print, esc_pos_utils_plus package must be used, returns true if successful
  Future<bool> writeBytes(List<int> bytes) async {
    //enviar bytes a la impresora
    try {
      final bool result = await _channel.invokeMethod('writebytes', bytes);
      //print("llego: $result");
      return result;
    } on PlatformException catch (e) {
      print("Failed to write bytes: '${e.message}'.");
      return false;
    }
  }

  ///Strings are sent to be printed by the PrintTextSize class can print from size 1 (50%) to size 5 (400%)
  Future<bool> writeString({required PrintTextSize printText}) async {
    ///EN: you must send the enter \n to print the complete phrase, it is not sent automatically because you may want to add several
    /// horizontal values ​​of different size
    ///ES: se debe enviar el enter \n para que imprima la frase completa, no se envia automatico por que tal vez quiera agregar varios
    ///valores horizontales de diferente tamaño
    int size = printText.size <= 5 ? printText.size : 2;
    String text = printText.text;

    String textFinal = "$size///$text";

    try {
      final bool result = await _channel.invokeMethod('printstring', textFinal);
      //print("llego: $result");
      return result;
    } on PlatformException catch (e) {
      print("Failed to printsext: '${e.message}'.");
      return false;
    }
  }

  ///gets the android version where it is running, returns String
  Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  ///get the percentage of the battery returns int
  Future<int> get batteryLevel async {
    int result = 0;

    try {
      result = await _channel.invokeMethod('getBatteryLevel');
      //print("llego: $result");
    } on PlatformException catch (e) {
      print("Failed to get battery level: '${e.message}'.");
    }
    return result;
  }

  ///disconnect print
  Future<bool> get disconnect async {
    bool status = false;
    try {
      status = await _channel.invokeMethod('disconnect');
      //print("llego: $result");
    } on PlatformException catch (e) {
      print("Failed to disconnect: '${e.message}'.");
    }

    return status;
  }
}

class BluetoothInfo {
  late String name;
  late String macAdress;
  BluetoothInfo({
    required this.name,
    required this.macAdress,
  });
}

class PrintTextSize {
  ///min size 1 max 5, if the size is different to the range it will be 2
  late int size;
  late String text;

  PrintTextSize({
    required this.size,
    required this.text,
  });
}
