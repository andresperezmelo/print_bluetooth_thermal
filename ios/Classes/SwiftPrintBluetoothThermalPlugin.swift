import Flutter
import UIKit

public class SwiftPrintBluetoothThermalPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "print_bluetooth_thermal", binaryMessenger: registrar.messenger())
    let instance = SwiftPrintBluetoothThermalPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
