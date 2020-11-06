
import 'dart:async';

import 'package:flutter/services.dart';

class PrintBluetoothThermal {
  static const MethodChannel _channel = const MethodChannel('groons.web.app/print');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<List> get getBluetooths async {
    //const platform = const MethodChannel('groons.web.app/print');
    List items = new List();
    try {
      final List result = await _channel.invokeMethod('bluetoothVinculados');
      //print("llego: $result");
      items = result;
    } on PlatformException catch (e) {
      print("Fallo Bluetooth vinculados: '${e.message}'.");
    }

    return items;
  }

  static Future<String> get estadoConexion async {

    try {
      final String result = await _channel.invokeMethod('estadoConexion');
      //print("llego: $result");
      return result;
    } on PlatformException catch (e) {
      print("Failed to write bytes: '${e.message}'.");
      return "false";
    }

  }

  static Future<String> conectar(String mac) async {

    //const platform = const MethodChannel('groons.web.app/print');
    String mac_printen = mac;//"66:02:BD:06:18:7B";
    String result = "false";
    try {
      result = await _channel.invokeMethod('conectarImpresora',mac_printen);
      //print("llego conexion: $result");
    } on PlatformException catch (e) {
      print("Failed to concet: '${e.message}'.");
    }
    return result;
  }

  static Future<String> writeBytes(List<int> bytes) async {

    //const platform = const MethodChannel('groons.web.app/print');

    try {
      final String result = await _channel.invokeMethod('imprimirBytes',bytes);
      //print("llego: $result");
      return result;
    } on PlatformException catch (e) {
      print("Failed to write bytes: '${e.message}'.");
      return "false";
    }

  }

  static Future<String> writeText(String text) async {

    //const platform = const MethodChannel('groons.web.app/print');
    ///size of 1-5
    //String text = "5/Impresora térmica ñ \n";

    try {
      final String result = await _channel.invokeMethod('imprimirTexto',text);
      //print("llego: $result");
      return result;
    } on PlatformException catch (e) {
      print("Failed to writeText: '${e.message}'.");
      return "false";
    }
  }

  static Future<int> get getNivelBateria async {

    //const platform = const MethodChannel('groons.web.app/print');

    try {
      final int result = await _channel.invokeMethod('getBatteryLevel');
      //print("llego: $result");
      return result;
    } on PlatformException catch (e) {
      print("Failed to get battery level: '${e.message}'.");
    }
  }
}
