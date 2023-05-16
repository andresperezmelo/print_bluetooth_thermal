#ifndef FLUTTER_PLUGIN_PRINT_BLUETOOTH_THERMAL_PLUGIN_H_
#define FLUTTER_PLUGIN_PRINT_BLUETOOTH_THERMAL_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace print_bluetooth_thermal {

class PrintBluetoothThermalPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  PrintBluetoothThermalPlugin();

  virtual ~PrintBluetoothThermalPlugin();

  // Disallow copy and assign.
  PrintBluetoothThermalPlugin(const PrintBluetoothThermalPlugin&) = delete;
  PrintBluetoothThermalPlugin& operator=(const PrintBluetoothThermalPlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace print_bluetooth_thermal

#endif  // FLUTTER_PLUGIN_PRINT_BLUETOOTH_THERMAL_PLUGIN_H_
