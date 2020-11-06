import 'dart:io';

import 'package:flutter/material.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:prestagroons/meTodo.dart';

Future<ByteData> generarRecibo() async {

  Paint redPaint = new Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromPoints(Offset(0.0, 0.0), Offset(kCanvasSize, kCanvasSize)));
  canvas.drawPaint(redPaint); //fondo

  final stroke = Paint()
    ..color = Colors.grey
    ..style = PaintingStyle.stroke;

  canvas.drawRect(Rect.fromLTWH(0.0, 0.0, kCanvasSize, kCanvasSize), stroke);

  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4.0
    ..color = Colors.indigo;

  canvas.drawRect(Rect.fromLTWH(20, 40, 100, 100), paint);
  canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(120,40,100,100), Radius.circular(20)), paint,);
  canvas.drawOval(Rect.fromLTWH(220, 40,100,100), paint);

  TextSpan span = new TextSpan(style: new TextStyle(color: Colors.green,fontSize: 30), text: "Mi empresa",);
    TextPainter tp = new TextPainter(text: span, textAlign: TextAlign.left, textDirection: TextDirection.rtl);
    tp.layout();
    tp.paint(canvas, new Offset(5.0,5.0));

  final p1 = Offset(50, 250); //inica left 50 top 150
  final p2 = Offset(300, 250); //termina letf 300 top 150
  final paintl = Paint()
    ..color = Colors.blueGrey
    ..strokeWidth = 4;
  canvas.drawLine(p1, p2, paintl);



  final picture = recorder.endRecording();
  final img = await picture.toImage(200, 200);
  ByteData pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

  await crearFile(pngBytes,"prueba.png");

  return pngBytes;

  //final ByteData bytes = await rootBundle.load("assets/logo216.png");
  //await Share.file('esys imagen', 'prueba.png', pngBytes.buffer.asUint8List(), 'image/png');
}

class ProfileCardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {

   final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.indigo;
    final redPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.red;

    canvas.drawRect(Rect.fromLTWH(20, 40, 100, 100), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(120,40,100,100), Radius.circular(20)), paint,);
    canvas.drawOval(Rect.fromLTWH(220, 40,100,100), paint);

    TextSpan span = new TextSpan(style: new TextStyle(color: Colors.green,fontSize: 30), text: "Mi empresa",);
    TextPainter tp = new TextPainter(text: span, textAlign: TextAlign.left, textDirection: TextDirection.rtl);
    tp.layout();
    tp.paint(canvas, new Offset(5.0,5.0));

    final p1 = Offset(50, 250); //inica left 50 top 150
    final p2 = Offset(300, 250); //termina letf 300 top 150
    final paintl = Paint()
      ..color = Colors.blueGrey
      ..strokeWidth = 4;
    canvas.drawLine(p1, p2, paintl);

  }

  @override
  bool shouldRepaint(ProfileCardPainter oldDelegate) {
    return false;
  }
}


void main() => runApp(Appcanvas());

const kCanvasSize = 200.0;

class Appcanvas extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ImageGenerator(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ImageGenerator extends StatefulWidget {
  final Random rd;
  final int numColors;

  ImageGenerator()
      : rd = Random(),
        numColors = Colors.primaries.length;

  @override
  _ImageGeneratorState createState() => _ImageGeneratorState();
}

class _ImageGeneratorState extends State<ImageGenerator> {
  ByteData imgBytes;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: RaisedButton(
                child: Text('Generate image'), onPressed: generateImage),
          ),
          imgBytes != null
              ? Center(
              child: Image.memory(
                Uint8List.view(imgBytes.buffer),
                width: kCanvasSize,
                height: kCanvasSize,
              ))
              : Container()
        ],
      ),
    );
  }

  void generateImage() async {
    final color = Colors.primaries[widget.rd.nextInt(widget.numColors)];

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromPoints(Offset(0.0, 0.0), Offset(kCanvasSize, kCanvasSize)));

    final stroke = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke;

    canvas.drawRect(Rect.fromLTWH(0.0, 0.0, kCanvasSize, kCanvasSize), stroke);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
        Offset(
          widget.rd.nextDouble() * kCanvasSize,
          widget.rd.nextDouble() * kCanvasSize,
        ),
        20.0,
        paint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(200, 200);
    final pngBytes = await img.toByteData(format: ImageByteFormat.png);

    setState(() {
      imgBytes = pngBytes;
    });

    //final ByteData bytes = await rootBundle.load("assets/logo216.png");
    await Share.file('esys imagen', 'prueba.png', imgBytes.buffer.asUint8List(), 'image/png');
  }

}

