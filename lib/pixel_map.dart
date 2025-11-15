import 'dart:ui';

class PixelMap {
  final int width;
  final int height;
  final List<List<Color>> pixels; // pixels[y][x]

  PixelMap({
    required this.width,
    required this.height,
    required this.pixels,
  });
}