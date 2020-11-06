# print_bluetooth_thermal

Paquete para imprimir tickets en impresoras termicas de 58 mm en Android.

Este paquete surgio como alternativa a los actuales que usan el permiso de ubicacion y Google Play
bloquea las aplicaciones que no explican para que usan el permiso de ubicacion.

**Este paquete puede cambiar mucho en el futuro**

**Si quieren aportar el codigo de swift, se necesita que reciba bytes sin procesar para usar la clase ticket**

## Getting Started

Como usuarlo?

*Importe el paquete `print_bluetooth_thermal`

*Importe dos paquetes mas

1. [esc_pos_utils](https://pub.dev/packages/esc_pos_utils) paquete para imprimir recibos `import package:esc_pos_utils/esc_pos_utils.dart'`
2. [Image](https://pub.dev/packages/image) //para imprimir las imagenes `import 'package:image/image.dart' as Imagen`

*Llame al paquete  `import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart' as printBluetooth;`

Despues de eso puede usar **printBluetooth**
Las funciones son:
1. `printBluetooth.getBluetooths` Busca los bluetooths vinculados en el dispositivo

2. `printBluetooth.estadoConexion` mira el estado del dispositivo si esta conectado

3. `printBluetooth.conectar()` Se usa para concetar la impresora se debe enviar la mac de la impresora vinculada

4. `printBluetooth.writeBytes()` Se usa para imprimir bytes en la impresora se puede usar con la clase ticket de [esc_pos_utils](https://pub.dev/packages/esc_pos_utils) y el paquete [Image](https://pub.dev/packages/image)

5. `printBluetooth.writeText()` Se usa para imprimir texto personalizado que no tiene la clase tickets por ejemplo letra pequeña o letras muy grande, tiene 5 tamaños desde 1 hasta 5, todos los tamaños doblan al anterior

6. `printBluetooth.getNivelBateria` Se usa para obtener el nivel de bateria es importante por que algunos telefonos si esta bajo la bateria apagan el bluetooth, lo deben implementar ustedes mismos, crear sus condiciones

Aqui el ejemplo simple para un ejemplo completo vea example

```
Future<void> imprimirTesh()async{

    String conexion = await PrintBluetoothThermal.estadoConexion;
    if(conexion=="true"){
      String enter= '\n';
      final result = await PrintBluetoothThermal.writeBytes(enter.codeUnits);
      print("impresion $result");
      //size of 1-5
      String text = "ola";
      await PrintBluetoothThermal.writeText("$text");
      await PrintBluetoothThermal.writeText("5/$text") ;
    }else{
      //desconectado
      print("desconectado $conexion");
    }
  }
```



