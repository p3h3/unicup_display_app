import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:unicup_display/device_screen.dart';
import 'package:unicup_display/pixel_map.dart';
import 'package:unicup_display/pixel_map_painter.dart';
import 'package:unicup_display/rendering.dart';
import 'ble_manager.dart';

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

  double _pixelMapTextSize = 60;

  final flutterReactiveBle = FlutterReactiveBle();

  late BleManager bleManager;

  final TextEditingController _controller = TextEditingController();

  PixelMap? _pixelMap;
  
  String pixelMapText = "ET-Lions";


  @override
  void initState() {
    super.initState();

    bleManager = BleManager(flutterReactiveBle);

    _updatePixelMap("HELLO");
  }

    @override
  void dispose() {
    bleManager.dispose();
    super.dispose();
  }


  Future<void> _updatePixelMap(String text) async {
    setState(() {
      pixelMapText = text;
    });

    if (text.isEmpty) {
      setState(() {
        _pixelMap = null;
      });
      return;
    }

    try {
      final map = await textToPixelMap(text, _pixelMapTextSize);
      if (!mounted) return;
      setState(() {
        _pixelMap = map;
      });
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
    bleManager.write(0, [1, value]);
  }

  void _setAnimation() {
    bleManager.write(1, [01]);
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: Text(widget.title),
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
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

          ElevatedButton(
            onPressed: _setAnimation,
            child: const Text('Set animation'),
          ),





          TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Type text to render',
                border: OutlineInputBorder(),
              ),
              onChanged: _updatePixelMap, // live updates as you type
            ),
            Slider(
            value: _pixelMapTextSize,
            min: 0,
            max: 250,
            divisions: 250,
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
            const SizedBox(height: 16),
            
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
        ],
      ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _connectDevice,
      tooltip: 'Connect',
      child: const Icon(Icons.bluetooth),
    ),
  );
}
}
