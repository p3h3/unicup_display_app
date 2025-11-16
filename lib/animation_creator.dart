import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:unicup_display/pixel_map.dart';
import 'package:unicup_display/pixel_map_painter.dart';
import 'package:unicup_display/rendering.dart';

class AnimationCreator extends StatelessWidget {
  const AnimationCreator({super.key});
@override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Frame-by-Frame Animation',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const FrameEditorScreen(),
    );
  }
}

/// Simple model for a frame
class FrameData {
  FrameData({
    required this.pixelMap,
    required this.duration,
  });

  PixelMap pixelMap;
  Duration duration;
}

class FrameEditorScreen extends StatefulWidget {
  const FrameEditorScreen({super.key});

  @override
  State<FrameEditorScreen> createState() => _FrameEditorScreenState();
}

class _FrameEditorScreenState extends State<FrameEditorScreen> {
  final List<FrameData> _frames = [
  ];

  int _currentFrameIndex = 0;
  Timer? _playbackTimer;
  bool _isPlaying = false;
  Color _currentColor = Colors.blue;
  double _pixelMapTextSize = 60;

  
  final TextEditingController _controller = TextEditingController();

  PixelMap? _pixelMap;
  
  String pixelMapText = "test";

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
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

      
    } finally {
    }
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

  void _addFrame() {
    setState(() {
      _frames.add(
        FrameData(
          pixelMap: PixelMap(width: 45, height: 25),
          duration: const Duration(milliseconds: 250),
        ),
      );
    });
  }

  void _removeFrame(int index) {
    if (_frames.length <= 1) return;
    setState(() {
      _frames.removeAt(index);
      if (_currentFrameIndex >= _frames.length) {
        _currentFrameIndex = _frames.length - 1;
      }
    });
  }

  int get _totalDurationMs {
    return _frames.fold<int>(0, (sum, f) => sum + f.duration.inMilliseconds);
  }

  @override
  Widget build(BuildContext context) {
    final hasFrames = _frames.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Frame-by-Frame Animation'),
        actions: [
          IconButton(
            onPressed: _addFrame,
            tooltip: 'Add frame',
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _openWheel,
                child: const Text("Pick Color"),
              ),
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Type text to render',
                  border: OutlineInputBorder(),
                ),
                onChanged: _updatePixelMap, // live updates as you type
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
            ]
            ),

          // === PREVIEW AREA: replaced with your pixel canvas ===
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                // The pixel canvas
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
          ),

          // Playback controls + info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                IconButton.filled(
                  onPressed: hasFrames ? (_isPlaying ? _pause : _play) : null,
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                ),
                const SizedBox(width: 12),
                Text('Frame: ${hasFrames ? _currentFrameIndex + 1 : 0}'
                    '/${_frames.length}'),
                const Spacer(),
                Text('Total: $_totalDurationMs ms'),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Frames list (with timings)
          SizedBox(
            height: 180,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Frames & Timings',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _frames.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final frame = _frames[index];
                      final isSelected = index == _currentFrameIndex;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentFrameIndex = index;
                            _pixelMap = frame.pixelMap;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 140,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              width: 2,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Duration label
                              Text(
                                '${frame.duration.inMilliseconds} ms',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12),
                              ),
                              // Duration slider
                              Slider(
                                value: frame.duration.inMilliseconds
                                    .clamp(50, 2000)
                                    .toDouble(),
                                min: 50,
                                max: 2000,
                                divisions: 39,
                                onChanged: (value) {
                                  setState(() {
                                    frame.duration =
                                        Duration(milliseconds: value.round());
                                  });
                                },
                              ),
                              // Remove button
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                  iconSize: 18,
                                  onPressed: () => _removeFrame(index),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
