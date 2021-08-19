#import "PrintBluetoothThermalPlugin.h"
#if __has_include(<print_bluetooth_thermal/print_bluetooth_thermal-Swift.h>)
#import <print_bluetooth_thermal/print_bluetooth_thermal-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "print_bluetooth_thermal-Swift.h"
#endif

@implementation PrintBluetoothThermalPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftPrintBluetoothThermalPlugin registerWithRegistrar:registrar];
}
@end
