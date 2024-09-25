//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <print_bluetooth_thermal/print_bluetooth_thermal_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) print_bluetooth_thermal_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "PrintBluetoothThermalPlugin");
  print_bluetooth_thermal_plugin_register_with_registrar(print_bluetooth_thermal_registrar);
}
