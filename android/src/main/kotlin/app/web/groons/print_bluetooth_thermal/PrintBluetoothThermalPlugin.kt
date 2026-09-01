package app.web.groons.print_bluetooth_thermal

import android.Manifest
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.BatteryManager
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.OutputStream
import java.util.UUID
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

private const val TAG = "====> print: "
private const val REQUEST_PERMISSION_BT = 34264

class PrintBluetoothThermalPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.RequestPermissionsResultListener {

    private lateinit var context: Context
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var pendingPermissionResult: Result? = null

    private val pluginScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var outputStream: OutputStream? = null
    private var mac: String = ""
    private var state: Boolean = false

    // ==========================================
    // Lifecycle de FlutterPlugin
    // ==========================================
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        this.context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "groons.web.app/print")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        pluginScope.cancel()
        disconnect()
    }

    // ==========================================
    // Lifecycle de ActivityAware (para pedir permisos)
    // ==========================================
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        this.activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        this.activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        this.activity = null
    }

    // ==========================================
    // Manejador de llamadas desde Flutter
    // ==========================================
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> result.success("Android ${Build.VERSION.RELEASE}")

            "getBatteryLevel" -> {
                val batteryLevel = getBatteryLevel()
                if (batteryLevel != -1) {
                    result.success(batteryLevel)
                } else {
                    result.error("UNAVAILABLE", "Battery level not available.", null)
                }
            }

            "ispermissionbluetoothgranted" -> handlePermissionRequest(result)

            else -> {
                // Validación previa para cualquier otra llamada de Bluetooth en Android 12+
                if (!hasBluetoothPermission()) {
                    Log.w(TAG, "Bluetooth permission not granted (BLUETOOTH_CONNECT)")
                    result.error(
                        "PERMISSION_DENIED",
                        "Bluetooth permission not granted. Please request permission first.",
                        null
                    )
                    return
                }

                when (call.method) {
                    "bluetoothenabled" -> {
                        val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
                        result.success(bluetoothAdapter?.isEnabled == true)
                    }

                    "connectionstatus" -> {
                        result.success(checkConnectionStatus())
                    }

                    "connect" -> handleConnect(call, result)

                    "writebytes" -> handleWriteBytes(call, result)

                    "printstring" -> handlePrintString(call, result)

                    "writebytesChinese" -> handleWriteBytesChinese(call, result)

                    "pairedbluetooths" -> {
                        result.success(dispositivosVinculados())
                    }

                    "disconnect" -> {
                        disconnect()
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
        }
    }

    // ==========================================
    // Lógica de Permisos
    // ==========================================
    // 1. Validar usando el Activity si está disponible (evita caché desactualizada)
    private fun hasBluetoothPermission(): Boolean {
        val ctx = activity ?: context
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            ContextCompat.checkSelfPermission(
                ctx,
                Manifest.permission.BLUETOOTH_CONNECT
            ) == PackageManager.PERMISSION_GRANTED &&
                    ContextCompat.checkSelfPermission(
                        ctx,
                        Manifest.permission.BLUETOOTH_SCAN
                    ) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    // 2. Pedir ambos permisos a la vez en Android 12+
    private fun handlePermissionRequest(result: Result) {
        if (hasBluetoothPermission()) {
            result.success(true)
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val act = activity
            if (act != null) {
                pendingPermissionResult = result
                ActivityCompat.requestPermissions(
                    act,
                    arrayOf(
                        Manifest.permission.BLUETOOTH_CONNECT,
                        Manifest.permission.BLUETOOTH_SCAN
                    ),
                    REQUEST_PERMISSION_BT
                )
            } else {
                result.success(false)
            }
        } else {
            result.success(true)
        }
    }

    // 3. Validar que todos los permisos solicitados fueron concedidos
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode == REQUEST_PERMISSION_BT) {
            // Verifica que todos los permisos del array hayan sido aprobados
            val isGranted = grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            pendingPermissionResult?.success(isGranted)
            pendingPermissionResult = null
            return true
        }
        return false
    }

    // ==========================================
    // Lógica de Conexión e Impresión
    // ==========================================
    private fun checkConnectionStatus(): Boolean {
        val stream = outputStream ?: return false
        return try {
            stream.write(" ".toByteArray())
            true
        } catch (e: Exception) {
            disconnect()
            false
        }
    }

    private fun handleConnect(call: MethodCall, result: Result) {
        val macAddress = call.arguments?.toString().orEmpty()
        if (macAddress.isNotEmpty()) {
            mac = macAddress
        } else {
            result.success(false)
            return
        }

        pluginScope.launch {
            if (outputStream != null) {
                disconnect()
            }

            outputStream = connectToDevice()
            result.success(state)
        }
    }

    private suspend fun connectToDevice(): OutputStream? = withContext(Dispatchers.IO) {
        state = false
        var stream: OutputStream? = null
        val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()

        if (bluetoothAdapter != null && bluetoothAdapter.isEnabled) {
            try {
                val bluetoothDevice = bluetoothAdapter.getRemoteDevice(mac)
                val bluetoothSocket = bluetoothDevice.createRfcommSocketToServiceRecord(
                    UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
                )
                bluetoothAdapter.cancelDiscovery()
                bluetoothSocket.connect()

                if (bluetoothSocket.isConnected) {
                    stream = bluetoothSocket.outputStream
                    state = true
                } else {
                    Log.d(TAG, "Socket no conectado")
                }
            } catch (e: Exception) {
                state = false
                Log.e(TAG, "Error connect: ${e.message}")
                stream?.close()
            }
        } else {
            state = false
            Log.d(TAG, "Bluetooth adapter apagado o no disponible")
        }
        stream
    }

    @Suppress("UNCHECKED_CAST")
    private fun handleWriteBytes(call: MethodCall, result: Result) {
        val lista = call.arguments as? List<Int>
        val stream = outputStream

        if (lista == null || stream == null) {
            result.success(false)
            return
        }

        try {
            val bytes = ByteArray(lista.size + 1)
            bytes[0] = '\n'.code.toByte()
            for (i in lista.indices) {
                bytes[i + 1] = lista[i].toByte()
            }

            val chunkSize = 16 * 1024 // 16 KB
            val total = bytes.size
            var offset = 0

            while (offset < total) {
                val end = minOf(offset + chunkSize, total)
                stream.write(bytes, offset, end - offset)
                stream.flush()
                offset = end
            }
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error al imprimir bytes: ${e.message}", e)
            disconnect()
            result.success(false)
        }
    }

    private fun handlePrintString(call: MethodCall, result: Result) {
        val stringLlego = call.arguments?.toString().orEmpty()
        val stream = outputStream

        if (stream == null) {
            result.success(false)
            return
        }

        try {
            val linea = stringLlego.split("///")
            val size: Int
            val texto: String

            if (linea.size > 1) {
                val parsedSize = linea[0].toIntOrNull() ?: 2
                size = if (parsedSize in 1..5) parsedSize else 2
                texto = linea[1]
            } else {
                size = 2
                texto = stringLlego
            }

            stream.run {
                write(setBytes.size[0])
                write(setBytes.cancelar_chino)
                write(setBytes.caracteres_escape)
                write(setBytes.size[size])
                write(texto.toByteArray(charset("ISO-8859-1")))
                flush()
            }
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error al imprimir string: ${e.message}", e)
            disconnect()
            result.success(false)
        }
    }

    @Suppress("UNCHECKED_CAST")
    private fun handleWriteBytesChinese(call: MethodCall, result: Result) {
        val lista = call.arguments as? List<Int>
        val stream = outputStream

        if (lista == null || stream == null) {
            result.success(false)
            return
        }

        try {
            val bytes = ByteArray(lista.size + 1)
            bytes[0] = '\n'.code.toByte()
            for (i in lista.indices) {
                bytes[i + 1] = lista[i].toByte()
            }
            stream.write(bytes)
            stream.flush()
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error write chinese: ${e.message}", e)
            disconnect()
            result.success(false)
        }
    }

    private fun getBatteryLevel(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val batteryManager = context.getSystemService(Context.BATTERY_SERVICE) as? BatteryManager
            batteryManager?.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY) ?: -1
        } else {
            val intent = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            val level = intent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
            val scale = intent?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
            if (level != -1 && scale > 0) (level * 100) / scale else -1
        }
    }

    private fun dispositivosVinculados(): List<String> {
        val listItems = mutableListOf<String>()
        try {
            val bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()
            val pairedDevices: Set<BluetoothDevice>? = bluetoothAdapter?.bondedDevices
            pairedDevices?.forEach { device ->
                listItems.add("${device.name}#${device.address}")
            }
        } catch (e: SecurityException) {
            Log.e(TAG, "SecurityException al obtener dispositivos vinculados: ${e.message}")
        }
        return listItems
    }

    private fun disconnect() {
        try {
            outputStream?.close()
        } catch (_: Exception) {
        }
        outputStream = null
    }

    class setBytes {
        companion object {
            val enter = "\n".toByteArray()
            val resetear_impresora = byteArrayOf(0x1b, 0x40, 0x0a)
            val cancelar_chino = byteArrayOf(0x1C, 0x2E)
            val caracteres_escape = byteArrayOf(0x1B, 0x74, 0x10)

            val size = arrayOf(
                byteArrayOf(0x1d, 0x21, 0x00),
                byteArrayOf(0x1b, 0x4d, 0x01),
                byteArrayOf(0x1b, 0x4d, 0x00),
                byteArrayOf(0x1d, 0x21, 0x11),
                byteArrayOf(0x1d, 0x21, 0x22),
                byteArrayOf(0x1d, 0x21, 0x33)
            )

            const val HT: Byte = 9
            const val LF: Byte = 10
            const val CR: Byte = 13
            const val ESC: Byte = 27
            const val DLE: Byte = 16
            const val GS: Byte = 29
            const val FS: Byte = 28
            const val STX: Byte = 2
            const val US: Byte = 31
            const val CAN: Byte = 24
            const val CLR: Byte = 12
            const val EOT: Byte = 4
            val INIT = byteArrayOf(27, 64)
            var FEED_LINE = byteArrayOf(10)
            var SELECT_FONT_A = byteArrayOf(20, 33, 0)
            var SET_BAR_CODE_HEIGHT = byteArrayOf(29, 104, 100)
            var PRINT_BAR_CODE_1 = byteArrayOf(29, 107, 2)
            var SEND_NULL_BYTE = byteArrayOf(0)
            var SELECT_PRINT_SHEET = byteArrayOf(27, 99, 48, 2)
            var FEED_PAPER_AND_CUT = byteArrayOf(29, 86, 66, 0)
            var SELECT_CYRILLIC_CHARACTER_CODE_TABLE = byteArrayOf(27, 116, 17)
            var SELECT_BIT_IMAGE_MODE = byteArrayOf(27, 42, 33, -128, 0)
            var SET_LINE_SPACING_24 = byteArrayOf(27, 51, 24)
            var SET_LINE_SPACING_30 = byteArrayOf(27, 51, 30)
            var TRANSMIT_DLE_PRINTER_STATUS = byteArrayOf(16, 4, 1)
            var TRANSMIT_DLE_OFFLINE_PRINTER_STATUS = byteArrayOf(16, 4, 2)
            var TRANSMIT_DLE_ERROR_STATUS = byteArrayOf(16, 4, 3)
            var TRANSMIT_DLE_ROLL_PAPER_SENSOR_STATUS = byteArrayOf(16, 4, 4)
            val ESC_FONT_COLOR_DEFAULT = byteArrayOf(27, 114, 0)
            val FS_FONT_ALIGN = byteArrayOf(28, 33, 1, 27, 33, 1)
            val ESC_ALIGN_LEFT = byteArrayOf(27, 97, 0)
            val ESC_ALIGN_RIGHT = byteArrayOf(27, 97, 2)
            val ESC_ALIGN_CENTER = byteArrayOf(27, 97, 1)
            val ESC_CANCEL_BOLD = byteArrayOf(27, 69, 0)
            val ESC_HORIZONTAL_CENTERS = byteArrayOf(27, 68, 20, 28, 0)
            val ESC_CANCLE_HORIZONTAL_CENTERS = byteArrayOf(27, 68, 0)
            val ESC_ENTER = byteArrayOf(27, 74, 64)
            val PRINTE_TEST = byteArrayOf(29, 40, 65)
        }
    }
}