import 'dart:async';

import 'package:flutter/material.dart';

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
    required this.color, // Placeholder for image; replace with your image type
    required this.duration,
  });

  Color color; // In your real app, replace this with an ImageProvider or path
  Duration duration;
}

class FrameEditorScreen extends StatefulWidget {
  const FrameEditorScreen({super.key});

  @override
  State<FrameEditorScreen> createState() => _FrameEditorScreenState();
}

class _FrameEditorScreenState extends State<FrameEditorScreen> {
  final List<FrameData> _frames = [
    FrameData(color: Colors.red, duration: const Duration(milliseconds: 200)),
    FrameData(color: Colors.green, duration: const Duration(milliseconds: 300)),
    FrameData(color: Colors.blue, duration: const Duration(milliseconds: 400)),
  ];

  int _currentFrameIndex = 0;
  Timer? _playbackTimer;
  bool _isPlaying = false;

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
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
        _currentFrameIndex =
            (_currentFrameIndex + 1) % _frames.length; // loop
      });
      _scheduleNextFrame();
    });
  }

  void _addFrame() {
    setState(() {
      _frames.add(
        FrameData(
          color: Colors.primaries[_frames.length % Colors.primaries.length],
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
    final currentFrame =
        hasFrames ? _frames[_currentFrameIndex] : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Animation Creator'),
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
          // Preview area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                child: Center(
                  child: hasFrames
                      ? AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 200,
                          height: 200,
                          // In a real app, replace this Container with Image(...)
                          decoration: BoxDecoration(
                            color: currentFrame!.color,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        )
                      : const Text('No frames yet'),
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
                  onPressed: hasFrames
                      ? (_isPlaying ? _pause : _play)
                      : null,
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
                              // thumbnail
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    // In a real app, replace with Image(image: frame.image)
                                    color: frame.color,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
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
