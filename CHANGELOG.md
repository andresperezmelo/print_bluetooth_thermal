## [1.1.7] - 2025-10-16

### 🔧 Improvements
- Increased Bluetooth data transfer limit from **4 KB to 16 KB**, allowing stable printing of longer texts and images.  
- Updated to **Android Gradle Plugin 8.6.0** and **Kotlin 2.1.0** for full compatibility with **Flutter 3.35+**.  
- Optimized native Kotlin code for safer `OutputStream` handling and chunked data transmission.  
- Removed deprecated or unavailable properties (`sendBufferSize`) from `BluetoothSocket`.  
- Verified full build compatibility with **Android Studio Koala (AGP 8.6 / Gradle 8.9)**.

### ✅ Compatibility
- Compatible with **Android 5.0 (API 21)** and above.  
- Tested with **Flutter 3.35.5** and **Dart 3.9.2**.

---

## [1.1.6]
1. Update Api v2 de flutter for Android
2. 2025/02/14

## [1.1.5]
1. Update desing new flutter
2. 2025/01/16

## [1.1.4]
1. Delete package web
2. update code pull request #52

## [1.1.3]

1. Update folder ios and update platform suport

## [1.1.2]

1. Updated to support the new Android versions in new Flutter projects.

## [1.1.1]

1. Update readme.md

## [1.1.0]

1. Add support for Windows print

## [1.0.9]

1. Update README.md

## [1.0.8]

1. Update README.md

## [1.0.7]

1. Added support for IOS
2. Updated the gradle version to 7.2.0
3. Kotlin version was updated to 1.8.0


## [1.0.6]

1. Fixed a bug that when validating bluetooth permission on devices with android sdk less than 31 showed false, and it should be true since those devices do not need the access permission to nearby devices

## [1.0.5]

1. Fixed an error that in versions of android with decimals, for example android 7.1.1, did not work.

## [1.0.3]

1. Added support for android 12
2. Added BLUETOOTH_CONNECT permission for android 12 onwards
3. Added isPermissionBluetoothGranted function to detect if permission is enabled, works only on android 12 and up
4. Changed Kotlin from 1.3.50 to 1.6.10

## [1.0.2]

Added a method to disconnect the printer

## [1.0.1]

Shareability with null security was added and all methods were changed to English.
if you want to migrate to this version you must read the README.md file

## [1.0.0]

Shareability with null security was added and all methods were changed to English.
if you want to migrate to this version you must read the README.md file

## [0.0.8]

Se cambio el modo de separar el tamaño en texto personalizado por (//) antes (/)

## [0.0.7]

Se agrego que ahora se detecta el estado del bluetooth getBluetoothState

## [0.0.6]

Se agrego que ahora se detecta claramente el estado de la conexion

## [0.0.5]

Se agrego la opcion de detectar la conexion de la impresora con el metodo estadoConexion

## [0.0.4]

Se agrego que la el metodo getNivelbateria retorne un int

## [0.0.3]

cambio del contexto para no causar conflictos con otros paquetes

## [0.0.2]

# print_bluetooth_thermal

Se cambio de dart a pluning

