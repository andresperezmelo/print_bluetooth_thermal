import 'dart:convert';
import 'package:flutter/services.dart';
//import 'package:image/image.dart' as img;

class PostCode {
  static List<int> text({required String text, AlignPos align = AlignPos.left, bool bold = false, bool inverse = false, FontSize fontSize = FontSize.normal}) {
    String enter = "\n";
    String reset = '\x1B@';
    String alignmentCode = "";

    const cAlignLeft = '\x1Ba0'; // Alinear a la izquierda
    const cAlignCenter = '\x1Ba1'; // Alinear al centro
    const cAlignRight = '\x1Ba2'; // Alinear a la derecha

    const cBoldOn = '\x1BE\x01'; // Turn emphasized mode on
    const cBoldOff = '\x1BE\x00'; // Turn emphasized mode off

    const cInverseOn = '\x1dB\x01'; // Activar texto invertido
    const cInverseOff = '\x1dB\x00'; // Desactivar texto invertido

    //const cFontNormal = '\x1D!\x00'; // Tamaño de fuente normal
    //const cFontNormal = '\x1d\x21\x00'; // La fuente no se agranda (0)
    const cFontNormal = '\x1b\x4d\x00'; // Fuente estándar ASCII (2)
    const cFontCompressed = '\x1b\x4d\x01'; // Fuente comprimida
    const cDoubleHeightFont = '\x1d\x21\x11'; // Altura doblada
    const cDoubleWidthFont = '\x1d\x21\x22'; // Ancho doblado
    const cBigFont = '\x1d\x21\x33'; // Ancho y alto doblados
    const cTripleHeightFont = '\x1d\x21\x33'; // Altura doblada (5)

    // Aplicar los comandos según los parámetros
    if (align == AlignPos.left) {
      alignmentCode = cAlignLeft;
    } else if (align == AlignPos.center) {
      alignmentCode = cAlignCenter;
    } else if (align == AlignPos.right) {
      alignmentCode = cAlignRight;
    }

    String fontSizeCode = "";
    switch (fontSize) {
      case FontSize.normal:
        fontSizeCode = cFontNormal;
        break;
      case FontSize.compressed:
        fontSizeCode = cFontCompressed;
        break;
      case FontSize.doubleHeight:
        fontSizeCode = cDoubleHeightFont;
        break;
      case FontSize.doubleWidth:
        fontSizeCode = cDoubleWidthFont;
        break;
      case FontSize.big:
        fontSizeCode = cBigFont;
        break;
      case FontSize.superBig:
        fontSizeCode = cTripleHeightFont;
        break;
    }

    if (inverse) {
      text = '$cInverseOn$text$cInverseOff';
    }

    if (bold) {
      text = '$reset$cBoldOn$alignmentCode$fontSizeCode$text$enter$cBoldOff';
    } else {
      text = '$reset$alignmentCode$fontSizeCode$text$enter';
    }

    return text.codeUnits;
  }

  static List<int> barcode({required String barcodeData, AlignPos align = AlignPos.center}) {
    // Comando para restablecer la impresora
    String reset = '\x1B@';
    String enter = '\n';

    // Comando para imprimir un código de barras Code 128
    String barcodeCommand = '\x1D\x68\x64\x1D\x77\x02\x1D\x48\x02\x1D\x6B\x49\x0C$barcodeData\x00';

    // Aplicar los comandos según los parámetros
    const cAlignLeft = '\x1Ba0'; // Alinear a la izquierda
    const cAlignCenter = '\x1Ba1'; // Alinear al centro
    const cAlignRight = '\x1Ba2'; // Alinear a la derecha

    String alignmentCode = "";
    if (align == AlignPos.left) {
      alignmentCode = cAlignLeft;
    } else if (align == AlignPos.center) {
      alignmentCode = cAlignCenter;
    } else if (align == AlignPos.right) {
      alignmentCode = cAlignRight;
    }

    // Concatena los comandos y los convierte en una lista de bytes
    String combinedCommand = '$reset$alignmentCode$barcodeCommand$enter';
    List<int> commandBytes = combinedCommand.codeUnits;

    return commandBytes;
  }

  // Generate code QR
  static List<int> qr(
    String text, {
    AlignPos align = AlignPos.center,
    QRSize size = QRSize.size4,
    QRCorrection cor = QRCorrection.L,
  }) {
    List<int> bytes = <int>[];

    const cQrHeader = '\x1D(k';

    String reset = '\x1B@';

    bytes += reset.codeUnits;

    // FN 167. QR Code: Set the size of module
    // pL pH cn fn n
    bytes += cQrHeader.codeUnits + [0x03, 0x00, 0x31, 0x43] + [QRSize.size5.value];

    // FN 169. QR Code: Select the error correction level
    // pL pH cn fn n
    bytes += cQrHeader.codeUnits + [0x03, 0x00, 0x31, 0x45] + [QRCorrection.L.value];

    // FN 180. QR Code: Store the data in the symbol storage area
    List<int> textBytes = latin1.encode(text);
    // pL pH cn fn m
    bytes += cQrHeader.codeUnits + [textBytes.length + 3, 0x00, 0x31, 0x50, 0x30];
    bytes += textBytes;

    // FN 182. QR Code: Transmit the size information of the symbol data in the symbol storage area
    // pL pH cn fn m
    bytes += cQrHeader.codeUnits + [0x03, 0x00, 0x31, 0x52, 0x30];

    // FN 181. QR Code: Print the symbol data in the symbol storage area
    // pL pH cn fn m
    bytes += cQrHeader.codeUnits + [0x03, 0x00, 0x31, 0x51, 0x30];

    return bytes;
  }

  /// Returns a string for a printing line depending on the amount of text.
  /// @texts = List of texts to place on the line.
  /// @porportions = List of proportions between (1 and 100) %.
  /// @fontSize = FontSize.normal
  static List<int> row({required List<String> texts, required List<int> proportions, FontSize fontSize = FontSize.normal, AlignPos align = AlignPos.left}) {
    String textadd = "";
    String reset = '\x1B@';
    String enter = "\n";

    //revisar si los textops y las proporciones estan en la misma cantidad
    if (proportions.length != texts.length) {
      String msj = "error: La cantidad de proporciones y texts debe ser mayor igual (proportions: ${proportions.length} texts: ${texts.length})";
      throw Exception(msj);
    }
    //revisar el total de proporciones
    int totalProporciones = 0;
    for (int p in proportions) {
      totalProporciones += p;
    }

    const cFontNormal = '\x1b\x4d\x00'; // Fuente estándar ASCII (2)
    const cFontCompressed = '\x1b\x4d\x01'; // Fuente comprimida
    const cDoubleHeightFont = '\x1d\x21\x11'; // Altura doblada
    const cDoubleWidthFont = '\x1d\x21\x22'; // Ancho doblado
    const cBigFont = '\x1d\x21\x33'; // Ancho y alto doblados
    const cTripleHeightFont = '\x1d\x21\x33'; // Altura doblada (5)

    //80 mm
    String fontSizeCode = "";
    int maxCaracteres = 48; //normal
    switch (fontSize) {
      case FontSize.compressed:
        maxCaracteres = 64;
        fontSizeCode = cFontCompressed;
        break;
      case FontSize.normal:
        maxCaracteres = 48;
        fontSizeCode = cFontNormal;
        break;
      case FontSize.doubleWidth:
        maxCaracteres = 32;
        fontSizeCode = cDoubleWidthFont;
        break;
      case FontSize.doubleHeight:
        maxCaracteres = 32;
        fontSizeCode = cDoubleHeightFont;
        break;
      case FontSize.big:
        maxCaracteres = 24;
        fontSizeCode = cBigFont;
        break;
      case FontSize.superBig:
        maxCaracteres = 16;
        fontSizeCode = cTripleHeightFont;
    }

    /*if (_paperSize == PaperSize.mm58) {
      return (font == null || font == PosFontType.fontA) ? 32 : 42;
    } else if (_paperSize == PaperSize.mm72) {
      return (font == null || font == PosFontType.fontA) ? 42 : 56;
    } else {
      return (font == null || font == PosFontType.fontA) ? 48 : 64;
    }*/

    if (totalProporciones != 100) {
      String msj = "error: el total de proporciones debe ser igual a 100% ($totalProporciones %)";
      throw Exception(msj);
    }

    // Aplicar los comandos según los parámetros
    const cAlignLeft = '\x1Ba0'; // Alinear a la izquierda
    const cAlignCenter = '\x1Ba1'; // Alinear al centro
    const cAlignRight = '\x1Ba2'; // Alinear a la derecha

    String alignmentCode = "";
    if (align == AlignPos.left) {
      alignmentCode = cAlignLeft;
    } else if (align == AlignPos.center) {
      alignmentCode = cAlignCenter;
    } else if (align == AlignPos.right) {
      alignmentCode = cAlignRight;
    }

    textadd = "";

    //sacar cuantos caracteres por proporcion
    List<int> caracteres = [];
    for (int proporcion in proportions) {
      int ctrs = (proporcion * maxCaracteres) ~/ 100;
      //print("ctrs: $ctrs proporcion: $proporcion % max caracteres: $maxCaracteres");
      caracteres.add(ctrs);
    }

    for (int i = 0; i < texts.length; i++) {
      String text = texts[i];
      int ctrs = caracteres[i];
      //print("ctrs: $ctrs text: $text textadd: $textadd");
      if (text.length >= ctrs) {
        text = "${text.substring(0, ctrs - 2)}  ";
      } else {
        int espacios = ctrs - text.length;
        for (int j = 0; j < espacios; j++) {
          text += " ";
        }
      }

      textadd += text;
    }
    String textfinal = "$reset$fontSizeCode$alignmentCode$textadd$enter";

    return textfinal.codeUnits;
  }

  static List<int> enter({int nEnter = 1}) {
    String enter = "\n";
    for (int i = 0; i < nEnter; i++) {
      enter += "\n";
    }

    return enter.codeUnits;
  }

  static List<int> line({String typeLine = "-", FontSize fontSize = FontSize.normal}) {
    String reset = '\x1B@';
    String enter = "\n";

    const cFontNormal = '\x1b\x4d\x00'; // Fuente estándar ASCII (2)
    const cFontCompressed = '\x1b\x4d\x01'; // Fuente comprimida
    const cDoubleHeightFont = '\x1d\x21\x11'; // Altura doblada
    const cDoubleWidthFont = '\x1d\x21\x22'; // Ancho doblado
    const cBigFont = '\x1d\x21\x33'; // Ancho y alto doblados
    const cTripleHeightFont = '\x1d\x21\x33'; // Altura doblada (5)

    //80 mm
    String fontSizeCode = "";
    int maxCaracteres = 48; //normal
    switch (fontSize) {
      case FontSize.compressed:
        maxCaracteres = 64;
        fontSizeCode = cFontCompressed;
        break;
      case FontSize.normal:
        maxCaracteres = 48;
        fontSizeCode = cFontNormal;
        break;
      case FontSize.doubleWidth:
        maxCaracteres = 32;
        fontSizeCode = cDoubleWidthFont;
        break;
      case FontSize.doubleHeight:
        maxCaracteres = 32;
        fontSizeCode = cDoubleHeightFont;
        break;
      case FontSize.big:
        maxCaracteres = 24;
        fontSizeCode = cBigFont;
        break;
      case FontSize.superBig:
        maxCaracteres = 16;
        fontSizeCode = cTripleHeightFont;
    }

    String textfinal = "$reset$fontSizeCode";
    for (int i = 0; i < maxCaracteres; i++) {
      textfinal += typeLine;
    }
    textfinal += enter;

    return textfinal.codeUnits;
  }

  /*
  static Future<List<int>> image(img.Image imgSrc, {AlignPos align = AlignPos.center}) async {
    const esc = '\x1B';
    const cBitImg = '$esc*'; // Print image - column format

    List<int> bytes = [];
    // Image alignment
    String alignmentCode = "";

    const cAlignLeft = '\x1Ba0'; // Alinear a la izquierda
    const cAlignCenter = '\x1Ba1'; // Alinear al centro
    const cAlignRight = '\x1Ba2'; // Alinear a la derecha
    if (align == AlignPos.left) {
      alignmentCode = cAlignLeft;
    } else if (align == AlignPos.center) {
      alignmentCode = cAlignCenter;
    } else if (align == AlignPos.right) {
      alignmentCode = cAlignRight;
    }
    //bytes += alignmentCode.codeUnits;

    final img.Image image = img.Image.from(imgSrc); // make a copy
    const bool highDensityHorizontal = true;
    const bool highDensityVertical = true;

    img.invert(image);
    img.flip(image, direction: img.FlipDirection.horizontal);
    final img.Image imageRotated = img.copyRotate(image, angle: 270);

    const int lineHeight = highDensityVertical ? 3 : 1;
    final List<List<int>> blobs = _toColumnFormat(imageRotated, lineHeight * 8);

    // Compress according to line density
    // Line height contains 8 or 24 pixels of src image
    // Each blobs[i] contains greyscale bytes [0-255]
    // const int pxPerLine = 24 ~/ lineHeight;
    for (int blobInd = 0; blobInd < blobs.length; blobInd++) {
      blobs[blobInd] = _packBitsIntoBytes(blobs[blobInd]);
    }

    final int heightPx = imageRotated.height;
    const int densityByte = (highDensityHorizontal ? 1 : 0) + (highDensityVertical ? 32 : 0);

    final List<int> header = List.from(cBitImg.codeUnits);
    header.add(densityByte);
    header.addAll(_intLowHigh(heightPx, 2));

    // Adjust line spacing (for 16-unit line feeds): ESC 3 0x10 (HEX: 0x1b 0x33 0x10)
    bytes += [27, 51, 16];
    for (int i = 0; i < blobs.length; ++i) {
      bytes += List.from(header)
        ..addAll(blobs[i])
        ..addAll('\n'.codeUnits);
    }
    // Reset line spacing: ESC 2 (HEX: 0x1b 0x32)
    bytes += [27, 50];
    return bytes;
  }

  /// Extract slices of an image as equal-sized blobs of column-format data.
  ///
  /// [image] Image to extract from
  /// [lineHeight] Printed line height in dots
  static List<List<int>> _toColumnFormat(img.Image imgSrc, int lineHeight) {
    final img.Image image = img.Image.from(imgSrc); // make a copy

    // Determine new width: closest integer that is divisible by lineHeight
    final int widthPx = (image.width + lineHeight) - (image.width % lineHeight);
    final int heightPx = image.height;

    /// Create a black bottom layer
    final biggerImage = img.copyResize(image, width: widthPx, height: heightPx);

    // fill(biggerImage, 0)
    img.fill(biggerImage, color: img.ColorFloat16(0));

    /// Insert source image into bigger one
    // drawImage(biggerImage, image, dstX: 0, dstY: 0);
    img.compositeImage(biggerImage, image, dstX: 0, dstY: 0);

    int left = 0;
    final List<List<int>> blobs = [];

    while (left < widthPx) {
      // final Image slice = copyCrop(biggerImage, left, 0, lineHeight, heightPx);
      final img.Image slice = img.copyCrop(biggerImage, x: left, y: 0, width: lineHeight, height: heightPx);
      // final Uint8List bytes = slice.getBytes(  format: Format.luminance);
      final Uint8List bytes = slice.getBytes(order: img.ChannelOrder.bgr);
      blobs.add(bytes);
      left += lineHeight;
    }

    return blobs;
  }

  /// Merges each 8 values (bits) into one byte
  static List<int> _packBitsIntoBytes(List<int> bytes) {
    const pxPerLine = 8;
    final List<int> res = <int>[];
    const threshold = 127; // set the greyscale -> b/w threshold here
    for (int i = 0; i < bytes.length; i += pxPerLine) {
      int newVal = 0;
      for (int j = 0; j < pxPerLine; j++) {
        newVal = _transformUint32Bool(
          newVal,
          pxPerLine - j,
          bytes[i + j] > threshold,
        );
      }
      res.add(newVal ~/ 2);
    }
    return res;
  }

  /// Generate multiple bytes for a number: In lower and higher parts, or more parts as needed.
  ///
  /// [value] Input number
  /// [bytesNb] The number of bytes to output (1 - 4)
  static List<int> _intLowHigh(int value, int bytesNb) {
    final dynamic maxInput = 256 << (bytesNb * 8) - 1;

    if (bytesNb < 1 || bytesNb > 4) {
      throw Exception('Can only output 1-4 bytes');
    }
    if (value < 0 || value > maxInput) {
      throw Exception('Number is too large. Can only output up to $maxInput in $bytesNb bytes');
    }

    final List<int> res = <int>[];
    int buf = value;
    for (int i = 0; i < bytesNb; ++i) {
      res.add(buf % 256);
      buf = buf ~/ 256;
    }
    return res;
  }

  /// Replaces a single bit in a 32-bit unsigned integer.
  static int _transformUint32Bool(int uint32, int shift, bool newValue) {
    return ((0xFFFFFFFF ^ (0x1 << shift)) & uint32) | ((newValue ? 1 : 0) << shift);
  }
  */

  ///Reset printed
  static List<int> reset() {
    String reset = '\x1B@';

    List<int> bytes = [];
    bytes += reset.codeUnits;
    return bytes;
  }

  ///Create lines empy
  static List<int> emptyLines(int n) {
    List<int> bytes = [];
    if (n > 0) {
      bytes += List.filled(n, '\n').join().codeUnits;
    }
    return bytes;
  }

  /// [mode] is used to define the full or partial cut (if supported by the priner)
  static List<int> cut({PosCutMode mode = PosCutMode.full}) {
    const gs = '\x1D';
    const cCutFull = '${gs}V0'; // Full cut
    const cCutPart = '${gs}V1'; // Partial cut

    List<int> bytes = [];
    bytes += emptyLines(5);
    if (mode == PosCutMode.partial) {
      bytes += cCutPart.codeUnits;
    } else {
      bytes += cCutFull.codeUnits;
    }
    return bytes;
  }
}

class QRSize {
  const QRSize(this.value);
  final int value;

  static const size1 = QRSize(0x01);
  static const size2 = QRSize(0x02);
  static const size3 = QRSize(0x03);
  static const size4 = QRSize(0x04);
  static const size5 = QRSize(0x05);
  static const size6 = QRSize(0x06);
  static const size7 = QRSize(0x07);
  static const size8 = QRSize(0x08);
}

/// QR Correction level
class QRCorrection {
  const QRCorrection._internal(this.value);
  final int value;

  /// Level L: Recovery Capacity 7%
  static const L = QRCorrection._internal(48);

  /// Level M: Recovery Capacity 15%
  static const M = QRCorrection._internal(49);

  /// Level Q: Recovery Capacity 25%
  static const Q = QRCorrection._internal(50);

  /// Level H: Recovery Capacity 30%
  static const H = QRCorrection._internal(51);
}

enum AlignPos { left, center, right }

enum FontSize { normal, compressed, doubleHeight, doubleWidth, big, superBig }

enum BarcodeType { code128, code39 }

enum PosCutMode { partial, full }

/*class CodeUnit {
  static const esc = '\x1B';
  static const gs = '\x1D';
  static const fs = '\x1C';

  // Miscellaneous
  static const cInit = '$esc@'; // Initialize printer
  static const cBeep = '${esc}B'; // Beeper [count] [duration]

  // Mech. Control
  static const cCutFull = '${gs}V0'; // Full cut
  static const cCutPart = '${gs}V1'; // Partial cut

  // Character
  static const cReverseOn = '${gs}B\x01'; // Turn white/black reverse print mode on
  static const cReverseOff = '${gs}B\x00'; // Turn white/black reverse print mode off
  static const cSizeGSn = '$gs!'; // Select character size [N]
  static const cSizeESCn = '$esc!'; // Select character size [N]
  static const cUnderlineOff = '$esc-\x00'; // Turns off underline mode
  static const cUnderline1dot = '$esc-\x01'; // Turns on underline mode (1-dot thick)
  static const cUnderline2dots = '$esc-\x02'; // Turns on underline mode (2-dots thick)
  static const cBoldOn = '${esc}E\x01'; // Turn emphasized mode on
  static const cBoldOff = '${esc}E\x00'; // Turn emphasized mode off
  static const cFontA = '${esc}M\x00'; // Font A
  static const cFontB = '${esc}M\x01'; // Font B
  static const cTurn90On = '${esc}V\x01'; // Turn 90° clockwise rotation mode on
  static const cTurn90Off = '${esc}V\x00'; // Turn 90° clockwise rotation mode off
  static const cCodeTable = '${esc}t'; // Select character code table [N]
  static const cKanjiOn = '$fs&'; // Select Kanji character mode
  static const cKanjiOff = '$fs.'; // Cancel Kanji character mode

  // Print Position
  static const cAlignLeft = '${esc}a0'; // Left justification
  static const cAlignCenter = '${esc}a1'; // Centered
  static const cAlignRight = '${esc}a2'; // Right justification
  static const cPos = '$esc\$'; // Set absolute print position [nL] [nH]

  // Print
  static const cFeedN = '${esc}d'; // Print and feed n lines [N]
  static const cReverseFeedN = '${esc}e'; // Print and reverse feed n lines [N]

  // Bit Image
  static const cRasterImg = '$gs(L'; // Print image - raster bit format (graphics)
  static const cRasterImg2 = '${gs}v0'; // Print image - raster bit format (bitImageRaster) [obsolete]
  static const cBitImg = '$esc*'; // Print image - column format

  // Barcode
  static const cBarcodeSelectPos = '${gs}H'; // Select print position of HRI characters [N]
  static const cBarcodeSelectFont = '${gs}f'; // Select font for HRI characters [N]
  static const cBarcodeSetH = '${gs}h'; // Set barcode height [N]
  static const cBarcodeSetW = '${gs}w'; // Set barcode width [N]
  static const cBarcodePrint = '${gs}k'; // Print barcode

  // Cash Drawer Open
  static const cCashDrawerPin2 = '${esc}p030';
  static const cCashDrawerPin5 = '${esc}p130';

  // QR Code
  static const cQrHeader = '$gs(k';
}*/
