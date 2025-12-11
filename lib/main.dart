import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:unicup_display/animation_creator.dart';
import 'package:unicup_display/device_screen.dart';
import 'package:unicup_display/pixel_map.dart';
import 'package:unicup_display/pixel_map_painter.dart';
import 'package:unicup_display/rendering.dart';
import 'package:unicup_display/save_local.dart';
import 'ble_manager.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniCup Display',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const MyHomePage(title: 'UniCup Display'),
      navigatorKey: navigatorKey,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double _brightnessValue = 128;

  double _pixelMapTextSize = 85;

  final flutterReactiveBle = FlutterReactiveBle();

  late BleManager bleManager;

  final TextEditingController _controller = TextEditingController();

  PixelMap? _pixelMap;
  
  String pixelMapText = "ET Lions";

  Color _currentColor = Colors.blue;

  String currentTime = "";
  Timer? timer;
  bool timeEnabed = false;



  List<FrameData> _frames = [];

  int _currentFrameIndex = 0;
  Timer? _playbackTimer;
  bool _isPlaying = false;


  String? selectedImportFile;
  List<String> _dropdownItems = ["none"];
  String? _selectedItem;


  @override
  void initState() {
    super.initState();

    bleManager = BleManager(flutterReactiveBle);

    _updatePixelMap("ET Lions");

    timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        var now = DateTime.now();
        if(now.second % 2 == 0){
          currentTime = "${now.hour}:${now.minute}";
        }else{
          currentTime = "${now.hour} ${now.minute}";
        }
        if(timeEnabed && bleManager.isConnected){
          _updatePixelMap(currentTime);
        }
      });
    });
  }

    @override
  void dispose() {
    bleManager.dispose();
    super.dispose();
  }

  

  void _updateDropdownItems() async {
    final items = await listDownloadFilesByExtension("json");

    if (!mounted) return;

    setState(() {
      _dropdownItems = items;

      if (!_dropdownItems.contains(_selectedItem)) {
        _selectedItem = null;
        selectedImportFile = null;
      }
    });
  }

  Future<void> _sendPixelMap() async {

      if(!bleManager.isConnected){
        Fluttertoast.showToast(
          msg: "Please connect to a device.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 5,
          backgroundColor: Colors.white,
          textColor: Colors.red,
          fontSize: 15.0,
        );
        return;
      }

      if(_pixelMap == null){
        return;
      }

      // turn pixel map around (fucked up the mounting)
      var pixelMapRotated = new PixelMap(width: 45, height: 25);

      for (var y = 0; y < 25; y++) {
        for (var x = 0; x < 45; x++) {
          pixelMapRotated.pixels![25 - y][45 - x] = _pixelMap!.pixels[y][x];
        }
      }

      int rows_per_packet = ((bleManager.currentMTU - 1) / (1 + 45*3)).floor();

      for(int y = 0; y < 25; y += 0){

        Uint8List data = Uint8List(1 + (1 + 45*3)*rows_per_packet);

        int offset = 0;
        data[0] = rows_per_packet; // one row will be sent
        offset += 1;

        for(int row = 0; row < rows_per_packet; row++){
          if(y >= 25){
            continue;
          }

          Uint8List lineData =  pixelMapRotated!.getRawLine(y);

          data[offset] = y;
          offset += 1;
          data.setRange(offset, offset + lineData.length, lineData);
          offset += lineData.length;

          y++;
        }
        
        await bleManager.writeWithoutResponse(3, data);
      }
  }

  Future<void> _updatePixelMap(String text) async {
    setState(() {
      pixelMapText = text;
    });

    try {
      final map = await textToPixelMap(text, _pixelMapTextSize, _currentColor);
      if (!mounted) return;
      setState(() {
        _pixelMap = map;
      });

      _sendPixelMap();
      
    } finally {
    }
  }


  void _connectDevice() async {

    final connectedDevice = await navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => DeviceScreen(
          bleManager: bleManager,
        ),
      ),
    );

  }

  void _setBrightness(int value) {
    if(!bleManager.isConnected){
        Fluttertoast.showToast(
          msg: "Please connect to a device.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 5,
          backgroundColor: Colors.white,
          textColor: Colors.red,
          fontSize: 15.0,
        );
        return;
      }
    bleManager.write(0, [1, value]);
  }

  void _setAnimation() {
    if(!bleManager.isConnected){
        Fluttertoast.showToast(
          msg: "Please connect to a device.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 5,
          backgroundColor: Colors.white,
          textColor: Colors.red,
          fontSize: 15.0,
        );
        return;
      }
    bleManager.write(1, [01]);
  }

  void _stopAnimation() {
    if(!bleManager.isConnected){
        Fluttertoast.showToast(
          msg: "Please connect to a device.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 5,
          backgroundColor: Colors.white,
          textColor: Colors.red,
          fontSize: 15.0,
        );
        return;
      }
    bleManager.write(1, [00]);
  }



  void _openWheel() {
    Color temp = _currentColor;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: ColorPicker(
            pickerColor: temp,
            onColorChanged: (c) => temp = c,
            pickerAreaHeightPercent: 1.0,
            enableAlpha: false,
            paletteType: PaletteType.hsv,   // circular wheel
            displayThumbColor: true,
            labelTypes: const [],           // hide RGB/HEX labels
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() => _currentColor = temp);
                _updatePixelMap(pixelMapText);
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }




  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final Uint8List bytes = await picked.readAsBytes();
    final uiImage = await decodeImageFromList(bytes);

    final scaled = await scaleImageToPixelSize(uiImage,
      targetWidth: 45, targetHeight: 25);

    // 3. Extract pixels
    _pixelMap = await imageToPixelMap(scaled);

    _sendPixelMap();
  }



  
  Future<void> _importFile() async {

    if(_selectedItem == null){return;}

    var json = await getJsonFromDownloads(_selectedItem!);

    if(json == null){return;}

    List<dynamic> framesJson = json["frames"];

    _frames = [];
    List<FrameData> newFrameData = [];
    for(var i = 0; i < framesJson.length; i++){
      var newPixelMap = PixelMap(width: 45, height: 25);
      var newFrame = FrameData(pixelMap: newPixelMap, duration: Duration(milliseconds: 500));
      newFrame.fromJson(framesJson[i]);
      newFrameData.add(newFrame);
    }

    setState(() {
      _frames = newFrameData;
      _currentFrameIndex = 0;
      _pixelMap = _frames.isNotEmpty ? _frames[0].pixelMap : null;
    });
  }



  void _scheduleNextFrame() {
    if (!_isPlaying || _frames.isEmpty) return;

    final currentFrame = _frames[_currentFrameIndex];
    _playbackTimer = Timer(currentFrame.duration, () {
      if (!_isPlaying) return;
      setState(() {
        _currentFrameIndex = (_currentFrameIndex + 1) % _frames.length; // loop
        _pixelMap = _frames[_currentFrameIndex].pixelMap;
      });
      _scheduleNextFrame();
    });
  }


    void _play() {
      if (_frames.isEmpty) return;
      _playbackTimer?.cancel();
      setState(() {
        _isPlaying = true;
      });
      _scheduleNextFrame();
    }

    void _pause() {
      _playbackTimer?.cancel();
      setState(() {
        _isPlaying = false;
      });
    }




@override
Widget build(BuildContext context) {
  
  final hasFrames = _frames.isNotEmpty;

  return Scaffold(
    appBar: AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: Text(widget.title),
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // BRIGHTNESS
              Slider(
                value: _brightnessValue,
                min: 0,
                max: 255,
                divisions: 255,
                label: _brightnessValue.round().toString(),
                onChanged: (value) {
                  setState(() {
                    _brightnessValue = value;
                  });
                },
                onChangeEnd: (value) {
                  _setBrightness(value.toInt());
                },
              ),
              
              // TEXT SIZE
              Slider(
                value: _pixelMapTextSize,
                min: 10,
                max: 200,
                divisions: 190,
                label: _pixelMapTextSize.round().toString(),
                onChanged: (value) {
                  setState(() {
                    _pixelMapTextSize = value;
                  });
                },
                onChangeEnd: (value) {
                  setState(() {
                    _pixelMapTextSize = value;
                  });
                  _updatePixelMap(pixelMapText);
                },
              ),
            ],
          ),
          

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _setAnimation,
                child: const Text('Ohne Strom'),
              ),
              const SizedBox(width: 5), // optionaler Abstand
              ElevatedButton(
                onPressed: _stopAnimation,
                child: const Text('Stop'),
              ),

              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentColor,
                  border: Border.all(color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(width: 5),
              ElevatedButton(
                onPressed: _openWheel,
                child: const Text("Pick Color"),
              ),
            ],
          ),





          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Type text to render',
              border: OutlineInputBorder(),
            ),
            onChanged: _updatePixelMap, // live updates as you type
          ),
        
          // The pixel canvas
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 45 / 25, // keep the same proportions
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                  ),
                  child: _pixelMap == null
                      ? const Center(
                          child: Text(
                            'Pixel output will appear here',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : CustomPaint(
                          painter: PixelMapPainter(_pixelMap!),
                          // `size` is provided by Layout via AspectRatio+Expanded
                        ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // or start / center
            children: [
              IconButton.filled(
                onPressed: hasFrames ? (_isPlaying ? _pause : _play) : null,
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              ),
              const SizedBox(width: 6),
              Text('${hasFrames ? _currentFrameIndex + 1 : 0}'
                  '/${_frames.length}'),
              DropdownButton<String>(
                value: _selectedItem,
                hint: const Text("import"),
                items: _dropdownItems
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedItem = value;
                  });
                  selectedImportFile = value; // store globally
                },
                onTap: () =>{
                  _updateDropdownItems()
                },
              ),
              IconButton.filled(
                onPressed: _importFile,
                icon: Icon(Icons.upload_file),
              ),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center, // or start / center
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    timeEnabed = !timeEnabed;
                  });
                },
                child: const Text("T"),
              ),
              ElevatedButton(
                onPressed: pickImage,
                child: const Text("Img"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AnimationCreator(),
                    ),
                  );
                },
                child: const Text("A C"),
              ),
            ],
          )
        ],
      ),
    ),


    floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    floatingActionButton: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // LEFT FAB
        FloatingActionButton(
          onPressed: _connectDevice,
          tooltip: 'Connect',
          child: const Icon(Icons.bluetooth),
        ),

        // Spacer to keep them at true edges
        const SizedBox(width: 10),

        // RIGHT FAB
        FloatingActionButton(
          onPressed: () {
            setState(() {
              _updatePixelMap("");
            });
            _controller.clear();
          },
          tooltip: 'Delete Map',
          child: const Icon(Icons.delete),
        ),
      ],
    ),
  );
}
}
