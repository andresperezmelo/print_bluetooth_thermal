#include "print_bluetooth_thermal_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>

// check level de bateria
#include <windows.h>
#include <winbase.h>
#include <winnt.h>
#include <batclass.h>

// cyheck is bluetooth is habiliti
#include <iostream>
#include <wrl/client.h>
#include <windows.devices.radios.h>

namespace print_bluetooth_thermal
{

  // static
  void PrintBluetoothThermalPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarWindows *registrar)
  {
    auto channel =
        std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
            registrar->messenger(), "groons.web.app/print",
            &flutter::StandardMethodCodec::GetInstance());

    auto plugin = std::make_unique<PrintBluetoothThermalPlugin>();

    channel->SetMethodCallHandler(
        [plugin_pointer = plugin.get()](const auto &call, auto result)
        {
          plugin_pointer->HandleMethodCall(call, std::move(result));
        });

    registrar->AddPlugin(std::move(plugin));
  }

  PrintBluetoothThermalPlugin::PrintBluetoothThermalPlugin() {}

  PrintBluetoothThermalPlugin::~PrintBluetoothThermalPlugin() {}

  void PrintBluetoothThermalPlugin::HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
  {
    if (method_call.method_name().compare("getPlatformVersion") == 0)
    {
      std::ostringstream version_stream;
      version_stream << "Windows ";
      if (IsWindows10OrGreater())
      {
        version_stream << "10+";
      }
      else if (IsWindows8OrGreater())
      {
        version_stream << "8";
      }
      else if (IsWindows7OrGreater())
      {
        version_stream << "7";
      }
      result->Success(flutter::EncodableValue(version_stream.str()));
    }
    else if (method_call.method_name().compare("bluetoothenabled") == 0)
    {
      result->Success(flutter::EncodableValue(false));
    }
    else
    {
      result->NotImplemented();
    }
  }

} // namespace print_bluetooth_thermal
