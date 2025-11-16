import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:unicup_display/pixel_map.dart';

Future<ui.Image> renderTextToImage(String text, double size, Color color) async {
  const int workWidth = 450;
  const int workHeight = 250;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  // Fill background (e.g. black)
  final backgroundPaint = Paint()..color = Colors.black;
  canvas.drawRect(
    Rect.fromLTWH(0, 0, workWidth.toDouble(), workHeight.toDouble()),
    backgroundPaint,
  );

  // Setup text style (pixel/monospace font)
  final textStyle = TextStyle(
    color: color,
    fontFamily: 'PixelFont', // your pixel font
    fontSize: size,            // adjust until it looks good
  );

  final textSpan = TextSpan(text: text, style: textStyle);
  final tp = TextPainter(
    text: textSpan,
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  );

  tp.layout(maxWidth: workWidth.toDouble());

  // Center text within the working area
  final offset = Offset(
    (workWidth - tp.width) / 2,
    (workHeight - tp.height) / 2,
  );

  tp.paint(canvas, offset);

  final picture = recorder.endRecording();
  return picture.toImage(workWidth, workHeight);
}






Future<ui.Image> scaleImageToPixelSize(ui.Image source,
    {int targetWidth = 45, int targetHeight = 25}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  final srcRect = Rect.fromLTWH(
    0,
    0,
    source.width.toDouble(),
    source.height.toDouble(),
  );
  final dstRect = Rect.fromLTWH(
    0,
    0,
    targetWidth.toDouble(),
    targetHeight.toDouble(),
  );

  final paint = Paint()
    ..filterQuality = FilterQuality.none; // keep it blocky / sharp

  canvas.drawImageRect(source, srcRect, dstRect, paint);

  final picture = recorder.endRecording();
  return picture.toImage(targetWidth, targetHeight);
}







Future<PixelMap> imageToPixelMap(ui.Image image) async {
  final byteData =
      await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (byteData == null) {
    throw Exception('Failed to get image bytes');
  }

  final width = image.width;
  final height = image.height;

  final Uint8List bytes = byteData.buffer.asUint8List();

  int index(int x, int y) => (y * width + x) * 4; // RGBA

  final pixels = List.generate(
    height,
    (y) => List.generate(
      width,
      (x) {
        final i = index(x, y);
        final r = bytes[i];
        final g = bytes[i + 1];
        final b = bytes[i + 2];
        final a = bytes[i + 3];

        return Color.fromARGB(a, r, g, b);
      },
    ),
  );

  var pixelMap = PixelMap(width: width, height: height);
  pixelMap.fillPixels(pixels);
  return pixelMap;
}






Future<PixelMap> textToPixelMap(String text, double size, Color color) async {
  // 1. Render high-res text
  final fullImage = await renderTextToImage(text, size, color);

  // 2. Scale to 45x25
  final scaled = await scaleImageToPixelSize(fullImage,
      targetWidth: 45, targetHeight: 25);

  // 3. Extract pixels
  final pixelMap = await imageToPixelMap(scaled);

  return pixelMap;
}
