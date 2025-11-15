import 'package:flutter/material.dart';
import 'package:unicup_display/pixel_map.dart';

class PixelMapPainter extends CustomPainter {
  final PixelMap pixelMap;

  PixelMapPainter(this.pixelMap);

  @override
  void paint(Canvas canvas, Size size) {
    final pixelWidth = size.width / pixelMap.width;
    final pixelHeight = size.height / pixelMap.height;

    final paint = Paint();

    for (int y = 0; y < pixelMap.height; y++) {
      for (int x = 0; x < pixelMap.width; x++) {
        paint.color = pixelMap.pixels[y][x];
        canvas.drawRect(
          Rect.fromLTWH(
            x * pixelWidth,
            y * pixelHeight,
            pixelWidth,
            pixelHeight,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant PixelMapPainter oldDelegate) =>
      oldDelegate.pixelMap != pixelMap;
}
