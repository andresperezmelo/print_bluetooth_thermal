import 'dart:async';
import 'package:flutter/services.dart';

class PrintBluetoothThermal {
  static const MethodChannel _channel = const MethodChannel('groons.web.app/print');

  /*static Future<bool> get bluetoothAvailable async {
    //bluetooth esta disponible?
    bool bluetoothState = false;
    try {
      bluetoothState = await _channel.invokeMethod('bluetoothavailable');
      //print("llego: $result");
    } on PlatformException catch (e) {
      print("Fallo Bluetooth status: '${e.message}'.");
    }

    return bluetoothState;
  }*/

  static Future<bool> get bluetoothEnabled async {
    //bluetooth esta prendido?
    bool bluetoothState = false;
    try {
      bluetoothState = await _channel.invokeMethod('bluetoothenabled');
    } on PlatformException catch (e) {
      print("Fallo Bluetooth status: '${e.message}'.");
    }

    return bluetoothState;
  }

  static Future<List> get pairedBluetooths async {
    //bluetooth vinculados
    List items = [];
    try {
      final List result = await _channel.invokeMethod('pairedbluetooths');
      //print("llego: $result");
      items = result;
    } on PlatformException catch (e) {
      print("Fallo Bluetooth vinculados: '${e.message}'.");
    }

    return items;
  }

  static Future<bool> get connectionStatus async {
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

  static Future<bool> connect({required String macPrinterAddress}) async {
    //conectar impresora bluetooth
    String mac = macPrinterAddress; //"66:02:BD:06:18:7B";
    bool result = false;
    try {
      result = await _channel.invokeMethod('connect', mac);
      print("llego conexion: $result");
    } on PlatformException catch (e) {
      print("Failed to connect: ${e.message}");
    }
    return result;
  }

  static Future<bool> writeBytes(List<int> bytes) async {
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

  static Future<bool> writeString({required PrintTextSize printText}) async {
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

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<int> get batteryLevel async {
    int result = 0;

    try {
      result = await _channel.invokeMethod('getBatteryLevel');
      //print("llego: $result");

    } on PlatformException catch (e) {
      print("Failed to get battery level: '${e.message}'.");
    }
    return result;
  }
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
