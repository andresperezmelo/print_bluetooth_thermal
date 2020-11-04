import 'dart:typed_data';

import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import 'package:image/image.dart' as Imagen;
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  bool conceted = false;
  List items = new List();

  Future<void> getBluetoots()async{
    final List bluetooths = await PrintBluetoothThermal.getBluetooths;
    print("impresion $bluetooths");
    setState(() {
      items = bluetooths;
    });
  }

  Future<void> setConectar(String mac)async{
    final String result = await PrintBluetoothThermal.conectar(mac);
    print("impresion $result");
    if(result=="true") conceted = true;
    setState(() {

    });

  }

  Future<void> imprimirTicket()async{
    Ticket ticket = await reciboPrueba();
    final result = await PrintBluetoothThermal.writeBytes(ticket.bytes);
    print("impresion $result");
  }

  Future<void> imprimirTextoPersonalizado()async{
    String size1 = "1/Impresora térmica ñ \n *";
    String size2 = "2/Impresora térmica ñ \n ";
    String size3 = "3/Impresora térmica ñ \n *";
    String size4 = "4/Impresora térmica ñ \n *";
    String size5 = "5/Impresora térmica ñ \n *";
    final result1 = await PrintBluetoothThermal.writeText(size1);
    final result2 = await PrintBluetoothThermal.writeText(size2);
    final result3 = await PrintBluetoothThermal.writeText(size3);
    final result4 = await PrintBluetoothThermal.writeText(size4);
    final result5 = await PrintBluetoothThermal.writeText(size5);
    //print("impresion $result");
  }

  Future<Ticket> reciboPrueba()async{

    CapabilityProfile profile = await CapabilityProfile.load();
    final Ticket ticket = Ticket(PaperSize.mm58, profile);

    ticket.text('Regular: aA bB cC dD eE fF gG hH iI jJ kK lL mM nN oO pP qQ rR sS tT uU vV wW xX yY zZ');
    ticket.text('Special 1: àÀ èÈ éÉ ûÛ üÜ çÇ ôÔ', styles: PosStyles(codeTable: 'CP1252'));
    ticket.text('Special 2: blåbærgrød', styles: PosStyles(codeTable: 'CP1252'));
    ticket.text('Special 3: Impresora térmica ñ', styles: PosStyles(codeTable: 'CP1252'));

    ticket.text('Bold text', styles: PosStyles(bold: true));
    ticket.text('Reverse text', styles: PosStyles(reverse: true));
    ticket.text('Underlined text',
        styles: PosStyles(underline: true), linesAfter: 1);
    ticket.text('Align left', styles: PosStyles(align: PosAlign.left));
    ticket.text('Align center', styles: PosStyles(align: PosAlign.center));
    ticket.text('Align right', styles: PosStyles(align: PosAlign.right), linesAfter: 1);

    ticket.row([
      PosColumn(
        text: 'col3',
        width: 3,
        styles: PosStyles(align: PosAlign.center, underline: true),
      ),
      PosColumn(
        text: 'col6',
        width: 6,
        styles: PosStyles(align: PosAlign.center, underline: true),
      ),
      PosColumn(
        text: 'col3',
        width: 3,
        styles: PosStyles(align: PosAlign.center, underline: true),
      ),
    ]);

    ticket.text('Text size 200%', styles: PosStyles(
      height: PosTextSize.size2,
      width: PosTextSize.size2,
    ));

    // Print image:
    final ByteData data = await rootBundle.load('assets/logo.png');
    final Uint8List bytes = data.buffer.asUint8List();
    final Imagen.Image imagen = Imagen.decodeImage(bytes);
    ticket.image(imagen);
    // Print image using an alternative (obsolette) command
    // ticket.imageRaster(image);

    // Print barcode
    final List<int> barData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 4];
    ticket.barcode(Barcode.upcA(barData));

    // Print mixed (chinese + latin) text. Only for printers supporting Kanji mode
    // ticket.text(
    //   'hello ! 中文字 # world @ éphémère &',
    //   styles: PosStyles(codeTable: PosCodeTable.westEur),
    //   containsChinese: true,
    // );

    //ticket.feed(2);

    ticket.cut();

    return ticket;
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await PrintBluetoothThermal.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Running on: $_platformVersion\n'),
              Text("Buscar bluetooth vinculados"),
              OutlineButton(
                onPressed: (){
                  this.getBluetoots();
                },
                child: Text("Buscar"),
              ),
              Container(
                height: 200,
                child: ListView.builder(
                  itemCount: items.length>0?items.length:0,
                  itemBuilder: (context, index) {
                    return ListTile(
                      onTap: (){
                        String select = items[index];
                        List lista = select.split("#");
                        String name = lista[0];
                        String mac = lista[1];
                        this.setConectar(mac);
                      },
                      title: Text('${items[index]}'),
                    );
                  },
                ),
              ),
              SizedBox(
                height: 30,
              ),
              OutlineButton(
                onPressed: conceted? this.imprimirTicket:null,
                child: Text("Imprimir ticket"),
              ),
              OutlineButton(
                onPressed: conceted?this.imprimirTextoPersonalizado:null,
                child: Text("Imprimir texto"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
