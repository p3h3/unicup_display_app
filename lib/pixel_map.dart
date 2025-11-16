import 'dart:typed_data';
import 'dart:ui';

class PixelMap {
  final int width;
  final int height;
  List<List<Color>>? pixels; // pixels[y][x]

  PixelMap({
    required this.width,
    required this.height,
  });

  fillPixels(List<List<Color>> pixelsParam){
    pixels = pixelsParam;
  }

  getRawLine(int y){
    Uint8List rawPixelData = Uint8List(width * 3);

    for (var x = 0; x < width; x++) {
      /*
      if(x % 2 == 0){
        rawPixelData[x*3 + 0] = 100;
        rawPixelData[x*3 + 1] = 0;
        rawPixelData[x*3 + 2] = 0;
      }else{
        rawPixelData[x*3 + 0] = 0;
        rawPixelData[x*3 + 1] = 100;
        rawPixelData[x*3 + 2] = 0;
      }
      */
      rawPixelData[x*3 + 0] = (pixels![y][x].r * 255).toInt();
      rawPixelData[x*3 + 1] = (pixels![y][x].g * 255).toInt();
      rawPixelData[x*3 + 2] = (pixels![y][x].b * 255).toInt();
      
    }

    return rawPixelData;
  }
}