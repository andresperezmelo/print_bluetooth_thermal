#include "include/print_bluetooth_thermal/print_bluetooth_thermal_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "print_bluetooth_thermal_plugin.h"

void PrintBluetoothThermalPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  print_bluetooth_thermal::PrintBluetoothThermalPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
