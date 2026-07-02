# print_bluetooth_thermal

Flutter plugin for printing tickets on 58 mm and 80 mm Bluetooth thermal printers.

The plugin supports Android, iOS, macOS, and Windows. On Android it works with paired Bluetooth devices and does not require location permission for printer connections. On iOS and macOS it uses CoreBluetooth and discovers nearby BLE peripherals.

## Features

- Check Bluetooth permission and power state.
- List available Bluetooth devices.
- Connect and disconnect a printer.
- Send ESC/POS byte data to a printer.
- Print plain text with built-in text size support.
- Read connection status.
- Read basic platform and battery information where supported.
- Expose device type metadata for UI icons, such as printer, mobile, computer, audio, wearable, peripheral, imaging, or unknown.

## Platform Support

| API | Android | iOS | macOS | Windows |
| --- | :---: | :---: | :---: | :---: |
| `isPermissionBluetoothGranted` | Yes | Yes | Yes | Yes |
| `bluetoothEnabled` | Yes | Yes | Yes | Yes |
| `pairedBluetooths` | Yes | Yes | Yes | Yes |
| `connectionStatus` | Yes | Yes | Yes | Yes |
| `connect` | Yes | Yes | Yes | Yes |
| `writeBytes` | Yes | Yes | Yes | Yes |
| `writeString` | Yes | Yes | Yes | No |
| `disconnect` | Yes | Yes | Yes | Yes |
| `platformVersion` | Yes | Yes | Yes | No |
| `batteryLevel` | Yes | Yes | No | No |

## Requirements

- Dart SDK `>=3.2.0 <4.0.0`
- Flutter SDK `>=3.44.0`
- A Bluetooth thermal printer that supports writable ESC/POS-compatible services or characteristics.

For images, QR codes, barcodes, and advanced ESC/POS layouts, use an ESC/POS helper package such as `esc_pos_utils_plus` to generate bytes, then send them with `PrintBluetoothThermal.writeBytes`.

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  print_bluetooth_thermal: ^1.2.2
```

Then run:

```sh
flutter pub get
```

Import the package:

```dart
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
```

## Android Setup

The plugin manifest includes the required Bluetooth permissions:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
```

For Android 12 and newer, make sure the app has Nearby Devices permission enabled before scanning or connecting.

Android device type detection is based on `BluetoothClass` and available UUID metadata. This is the most accurate platform for showing printer, mobile, headset/audio, computer, and other icons.

## iOS Setup

Add Bluetooth usage descriptions to `ios/Runner/Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Bluetooth access to connect 58mm or 80mm thermal printers</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>Bluetooth access to interact with thermal printers</string>
```

iOS does not expose Bluetooth MAC addresses or Android-style Bluetooth class values. The plugin uses `CBPeripheral.identifier` as `macAdress` and detects device type best-effort from advertised services and device names.

## macOS Setup

Add Bluetooth usage descriptions to `macos/Runner/Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Bluetooth access to connect 58mm or 80mm thermal printers</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>Bluetooth access to interact with thermal printers</string>
```

Add the Bluetooth entitlement in `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements`:

```xml
<key>com.apple.security.device.bluetooth</key>
<true/>
```

## Apple SPM Notice

Starting with version `1.2.2`, the iOS and macOS implementations use pure Swift with Swift Package Manager support for Flutter 3.44+.

If your project requires legacy CocoaPods integration, pin the package to version `1.2.1`:

```yaml
dependencies:
  print_bluetooth_thermal: 1.2.1
```

## Basic Usage

### Check Bluetooth State

```dart
final bool enabled = await PrintBluetoothThermal.bluetoothEnabled;
```

### Check Permission

```dart
final bool granted = await PrintBluetoothThermal.isPermissionBluetoothGranted;
```

### List Devices

```dart
final List<BluetoothInfo> devices = await PrintBluetoothThermal.pairedBluetooths;

for (final device in devices) {
  print('Name: ${device.name}');
  print('Address: ${device.macAdress}');
  print('Type: ${device.type}');
  print('Type label: ${device.typeLabel}');
}
```

On Android, `pairedBluetooths` returns paired Bluetooth devices. Pair the printer in Android Bluetooth settings first.

On iOS and macOS, `pairedBluetooths` scans nearby Bluetooth peripherals for a short time and returns discovered devices.

### Show Device Icons

`BluetoothInfo.type` can be used to choose icons in your UI:

```dart
IconData bluetoothIcon(String type) {
  switch (type) {
    case 'printer':
      return Icons.print;
    case 'mobile':
    case 'phone':
      return Icons.smartphone;
    case 'computer':
      return Icons.computer;
    case 'audio':
      return Icons.headphones;
    case 'wearable':
      return Icons.watch;
    case 'peripheral':
      return Icons.keyboard;
    case 'imaging':
      return Icons.image;
    default:
      return Icons.bluetooth;
  }
}
```

Available metadata:

| Field | Description |
| --- | --- |
| `name` | Device name. |
| `macAdress` | Bluetooth MAC address on Android and Windows. On iOS and macOS this is the CoreBluetooth peripheral identifier. The spelling is kept for API compatibility. |
| `type` | Machine-readable type, such as `printer`, `mobile`, `computer`, `audio`, `wearable`, `peripheral`, `imaging`, or `unknown`. |
| `typeLabel` | Human-readable device type label. |
| `deviceClass` | Android Bluetooth class value when available. |
| `majorDeviceClass` | Android major Bluetooth class value when available. |
| `services` | Advertised or available service UUIDs when available. |

## Connect and Print

### Connect

```dart
final bool connected = await PrintBluetoothThermal.connect(
  macPrinterAddress: device.macAdress,
);
```

### Check Connection Status

```dart
final bool connected = await PrintBluetoothThermal.connectionStatus;
```

### Print Plain Text

```dart
final bool printed = await PrintBluetoothThermal.writeString(
  printText: PrintTextSize(
    size: 2,
    text: 'Hello printer\n',
  ),
);
```

`PrintTextSize.size` accepts values from `1` to `5`. Values outside that range fall back to size `2`.

### Print ESC/POS Bytes

```dart
final List<int> bytes = <int>[
  ...'Hello printer\n'.codeUnits,
];

final bool printed = await PrintBluetoothThermal.writeBytes(bytes);
```

### Disconnect

```dart
final bool disconnected = await PrintBluetoothThermal.disconnect;
```

## Complete Flow Example

```dart
Future<void> printExample() async {
  final bool bluetoothOn = await PrintBluetoothThermal.bluetoothEnabled;
  if (!bluetoothOn) {
    throw Exception('Bluetooth is disabled');
  }

  final List<BluetoothInfo> devices = await PrintBluetoothThermal.pairedBluetooths;
  if (devices.isEmpty) {
    throw Exception('No Bluetooth devices found');
  }

  final BluetoothInfo printer = devices.firstWhere(
    (device) => device.type == 'printer',
    orElse: () => devices.first,
  );

  final bool connected = await PrintBluetoothThermal.connect(
    macPrinterAddress: printer.macAdress,
  );

  if (!connected) {
    throw Exception('Could not connect to ${printer.name}');
  }

  await PrintBluetoothThermal.writeString(
    printText: PrintTextSize(size: 2, text: 'Test print\n'),
  );

  await PrintBluetoothThermal.disconnect;
}
```

## Troubleshooting

- Android 12 or newer: verify Nearby Devices permission is granted.
- Android: pair the printer in system Bluetooth settings before calling `pairedBluetooths`.
- iOS and macOS: make sure Bluetooth usage descriptions are present in `Info.plist`.
- macOS: make sure the Bluetooth entitlement is enabled.
- If connection succeeds but printing fails, verify the printer supports ESC/POS and exposes a writable service or characteristic.
- If iOS shows `unknown` device types, that is expected for devices that do not advertise recognizable services or names.
- If `writeString` is needed on Windows, use `writeBytes` instead because `writeString` is not implemented for Windows.

## Example App

The `example/` directory contains a Flutter app that scans devices, displays device type icons, connects to a printer, and sends test print data.

Run it with:

```sh
cd example
flutter run
```

## Images

![App example Android](https://raw.githubusercontent.com/andresperezmelo/print_bluetooth_thermal/refs/heads/main/myapp.png)

![Print sizes](https://raw.githubusercontent.com/andresperezmelo/print_bluetooth_thermal/refs/heads/main/size.jpeg)

![Use package print_bluetooth_thermal 58 mm](https://raw.githubusercontent.com/andresperezmelo/print_bluetooth_thermal/refs/heads/main/print.jpeg)

![Use package print_bluetooth_thermal 80 mm](https://raw.githubusercontent.com/andresperezmelo/print_bluetooth_thermal/refs/heads/main/print80mm.jpg)

## License

See [LICENSE](LICENSE).

## Author

Created by [andresperezmelo](https://github.com/andresperezmelo).
