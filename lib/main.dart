import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:o3d/o3d.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:video_player/video_player.dart';

import './screens/speechToVideo.dart';
import './screens/videoToSpeech.dart';
import './screens/avatar.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext c) =>
      MaterialApp(
        theme: ThemeData(colorSchemeSeed: Colors.blueAccent),
        home: const HomePage(),
      );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text('Signfiy'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _LargeNavButton(
              label: 'Speech to Video',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SpeechToVideoPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _LargeNavButton(
              label: 'Video to Speech',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VideoToSpeechPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _LargeNavButton(
              label: '3D animation',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ViewerPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LargeNavButton extends StatelessWidget {
  const _LargeNavButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 100,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
/*
class SpeechToVideoPage extends StatefulWidget {
  const SpeechToVideoPage({super.key});

  @override
  State<SpeechToVideoPage> createState() => _SpeechToVideoPageState();
}

class _SpeechToVideoPageState extends State<SpeechToVideoPage> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  VideoPlayerController? _videoController;
  String? _recordedFilePath;
  bool _isRecording = false;
  bool _isPlayingAudio = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlayingAudio = false;
      });
    });

    _videoController = VideoPlayerController.networkUrl(
      Uri.parse('https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4'),
    )..initialize().then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        if (path != null) {
          _recordedFilePath = path;
        }
      });
      return;
    }

    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission is required.')),
      );
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final path = '${tempDir.path}/speech_to_video_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _audioRecorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );

    setState(() {
      _isRecording = true;
    });
  }

  Future<void> _toggleAudioPlayback() async {
    if (_recordedFilePath == null) return;

    if (_isPlayingAudio) {
      await _audioPlayer.stop();
      setState(() {
        _isPlayingAudio = false;
      });
      return;
    }

    await _audioPlayer.play(DeviceFileSource(_recordedFilePath!));
    setState(() {
      _isPlayingAudio = true;
    });
  }

  Future<void> _toggleVideoPlayback() async {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;

    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoController = _videoController;

    return Scaffold(
      appBar: AppBar(title: const Text('Speech to Sign Video')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            
            const Text(
              'Sign Video',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (videoController != null && videoController.value.isInitialized)
              AspectRatio(
                aspectRatio: videoController.value.aspectRatio,
                child: VideoPlayer(videoController),
              )
            else
              const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _toggleVideoPlayback,
              icon: Icon(
                videoController != null && videoController.value.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
              ),
              label: Text(
                videoController != null && videoController.value.isPlaying
                    ? 'Pause Video'
                    : 'Play Video',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _toggleRecording,
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              label: Text(_isRecording ? 'Stop Recording' : 'Record Voice'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _recordedFilePath == null ? null : _toggleAudioPlayback,
              icon: Icon(_isPlayingAudio ? Icons.stop_circle : Icons.play_arrow),
              label: Text(_isPlayingAudio ? 'Stop Voice' : 'Play Recorded Voice'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _recordedFilePath == null ? null : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Translate to Sign feature coming soon!')),
                );
              },
              icon: const Icon(Icons.gesture),
              label: const Text('Translate to Sign'),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoToSpeechPage extends StatefulWidget {
  const VideoToSpeechPage({super.key});

  @override
  State<VideoToSpeechPage> createState() => _VideoToSpeechPageState();
}

class _VideoToSpeechPageState extends State<VideoToSpeechPage> {
  VideoPlayerController? _videoController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  String? _recordedVideoPath;
  String? _generatedSpeechPath;
  bool _isPlayingVideo = false;
  bool _isPlayingSpeech = false;
  bool _isTranslating = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlayingSpeech = false;
      });
    });
  }

  Future<void> _initializeVideo(String videoPath) async {
    // Dispose old controller
    _videoController?.dispose();
    
    _videoController = VideoPlayerController.file(
      File(videoPath),
    )..initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _recordedVideoPath = videoPath;
        _isPlayingVideo = false;
      });
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading video: $error')),
      );
    });
  }

  Future<void> _recordNewVideo() async {
    try {
      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No camera available on this device')),
        );
        return;
      }

      // Navigate to camera recording page
      if (!mounted) return;
      final videoPath = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => CameraRecorderPage(camera: cameras[0]),
        ),
      );

      if (videoPath != null) {
        await _initializeVideo(videoPath);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video recorded successfully!')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error recording video: $e')),
      );
    }
  }

  Future<void> _selectVideoFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickVideo(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        await _initializeVideo(pickedFile.path);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video loaded successfully!')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting video: $e')),
      );
    }
  }

  Future<void> _toggleVideoPlayback() async {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;

    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    if (!mounted) return;
    setState(() {
      _isPlayingVideo = controller.value.isPlaying;
    });
  }

  Future<void> _translateToSpeech() async {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please load a video first')),
      );
      return;
    }

    setState(() {
      _isTranslating = true;
    });

    // Simulate translation process
    await Future.delayed(const Duration(seconds: 2));

    // TODO: Replace with actual translation API call
    // For now, just show a success message
    if (!mounted) {
      setState(() {
        _isTranslating = false;
      });
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Video translated to speech!')),
    );

    setState(() {
      _isTranslating = false;
      _generatedSpeechPath = 'path_to_generated_speech'; // Placeholder
    });
  }

  Future<void> _toggleSpeechPlayback() async {
    if (_generatedSpeechPath == null) return;

    if (_isPlayingSpeech) {
      await _audioPlayer.stop();
      setState(() {
        _isPlayingSpeech = false;
      });
      return;
    }

    // TODO: Replace with actual generated speech file path
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Speech playback coming soon!')),
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoController = _videoController;
    final hasVideo = videoController != null && videoController.value.isInitialized;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Video to Speech'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Video Section
              const Text(
                'Input Video',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              if (hasVideo)
                AspectRatio(
                  aspectRatio: videoController.value.aspectRatio,
                  child: VideoPlayer(videoController),
                )
              else
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'No video selected',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              
              // Video Control Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _recordNewVideo,
                      icon: const Icon(Icons.videocam),
                      label: const Text('Record Video'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _selectVideoFromGallery,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Select Video'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: hasVideo ? _toggleVideoPlayback : null,
                icon: Icon(
                  hasVideo && _isPlayingVideo ? Icons.pause : Icons.play_arrow,
                ),
                label: Text(
                  hasVideo && _isPlayingVideo ? 'Pause Video' : 'Play Video',
                ),
              ),
              const SizedBox(height: 24),
              
              // Translation Section
              ElevatedButton.icon(
                onPressed: _isTranslating || !hasVideo ? null : _translateToSpeech,
                icon: _isTranslating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.language),
                label: Text(
                  _isTranslating ? 'Translating...' : 'Translate to Speech',
                ),
              ),
              const SizedBox(height: 24),
              
              // Speech Output Section
              const Text(
                'Generated Speech',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _generatedSpeechPath == null ? null : _toggleSpeechPlayback,
                icon: Icon(
                  _isPlayingSpeech ? Icons.stop_circle : Icons.play_arrow,
                ),
                label: Text(
                  _isPlayingSpeech ? 'Stop Speech' : 'Play Generated Speech',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ViewerPage extends StatefulWidget {
  const ViewerPage({super.key});
  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  final O3DController controller = O3DController();
  final TextEditingController textController = TextEditingController();
  var animateCounter=0;

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = ElevatedButton.styleFrom(
      textStyle: const TextStyle(fontSize: 28),
    );
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.blueAccent,
          title: const Text('Signfiy')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SizedBox(
                child: O3D(
                  controller: controller,
                  src: 'assets/models/hero.glb',
                  autoPlay: false,
                  cameraControls: false,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter text',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                  },
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    // example: list animations and play first
                    final animations = await controller.availableAnimations();
                    if (animations.isNotEmpty) {
                      controller.animationName = animations[0];
                      controller.play(repetitions: 1);
                    }
                  },
                  style: style,
                  child: const Text('لا اعلم'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final animations = await controller.availableAnimations();
                    if (animations.isNotEmpty) {
                      controller.animationName = animations[1];
                      controller.play(repetitions: 1);
                    }
                  },
                  style: style,
                  child: const Text('مرحبا'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final animations = await controller.availableAnimations();
                    if (animations.isNotEmpty) {
                      controller.animationName = animations[2];
                      controller.play(repetitions: 1);
                    }
                  },
                  style: style,
                  child: const Text('احترام'),
                ),
              ],
            ),
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   child: const Icon(Icons.play_arrow),
      //   onPressed: () async {
      //     // example: list animations and play first
      //     final animations = await controller.availableAnimations();
      //     if (animations.isNotEmpty) {
      //       controller.animationName = animations[animateCounter];
      //       controller.play(repetitions: 1);
      //     }
      //     animateCounter++;
      //     animateCounter%=animations.length;
      //   },
      // ),
    );
  }
}

class CameraRecorderPage extends StatefulWidget {
  final CameraDescription camera;

  const CameraRecorderPage({
    super.key,
    required this.camera,
  });

  @override
  State<CameraRecorderPage> createState() => _CameraRecorderPageState();
}

class _CameraRecorderPageState extends State<CameraRecorderPage> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _cameraController = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _cameraController.initialize();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        final XFile videoFile = await _cameraController.stopVideo();
        if (mounted) {
          Navigator.pop(context, videoFile.path);
        }
      } else {
        await _cameraController.startVideoRecording();
        setState(() {
          _isRecording = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Video'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                Expanded(
                  child: CameraPreview(_cameraController),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _toggleRecording,
                        icon: Icon(
                          _isRecording ? Icons.stop_circle : Icons.videocam,
                        ),
                        label: Text(
                          _isRecording ? 'Stop Recording' : 'Start Recording',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: const Text('Cancel'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
*/