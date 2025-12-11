import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

class PixelMap {
  final int width;
  final int height;
  late List<List<Color>> pixels; // pixels[y][x]

  PixelMap({
    required this.width,
    required this.height,
  }) {
    // 2D-Liste initialisieren: height Zeilen, width Spalten
    pixels = List.generate(
      height,
      (_) => List.generate(
        width,
        (_) => Color(0x00000000),
      ),
    );
  }

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





  // ----------------------------------------------------------
  //                     EXPORT JSON
  // ----------------------------------------------------------
  String exportJson() {
    if (pixels == null) {
      throw Exception("PixelMap pixels not initialized");
    }

    final data = {
      "width": width,
      "height": height,
      "pixels": pixels!.map((row) {
        return row.map((c) {
          return {
            "r": c.r,
            "g": c.g,
            "b": c.b,
            "a": c.a,
          };
        }).toList();
      }).toList(),
    };

    return jsonEncode(data);
  }

  // ----------------------------------------------------------
  //                     IMPORT JSON
  // ----------------------------------------------------------
  static PixelMap importJson(String jsonStr) {
    final decoded = jsonDecode(jsonStr);

    final width = decoded["width"];
    final height = decoded["height"];
    final pixelData = decoded["pixels"];

    PixelMap map = PixelMap(width: width, height: height);

    List<List<Color>> px = List.generate(
      height,
      (y) => List.generate(
        width,
        (x) {
          final p = pixelData[y][x];
          return Color.fromARGB(
            (p["a"] * 255).round(),
            (p["r"] * 255).round(),
            (p["g"] * 255).round(),
            (p["b"] * 255).round(),
          );
        },
      ),
    );

    map.fillPixels(px);
    return map;
  }

}