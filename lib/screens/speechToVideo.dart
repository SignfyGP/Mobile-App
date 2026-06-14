import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:video_player/video_player.dart';

import 'package:flutter_3d_controller/flutter_3d_controller.dart';


class SpeechToVideoPage extends StatefulWidget {
  const SpeechToVideoPage({super.key});

  @override
  State<SpeechToVideoPage> createState() => _SpeechToVideoPageState();
}

class _SpeechToVideoPageState extends State<SpeechToVideoPage> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final String _backendEndpoint = Platform.isAndroid
      ? 'http://10.0.2.2:8000/speech-to-skeleton-video'
      : 'http://127.0.0.1:8000/speech-to-skeleton-video';

  VideoPlayerController? _videoController;
  String? _recordedFilePath;
  bool _isRecording = false;
  bool _isPlayingAudio = false;
  bool _isTranslating = false;
  String? _transcribedText;
  List<String> _animationList = [];

  final Flutter3DController controller = Flutter3DController();

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
    final path = '${tempDir.path}/speech_to_video_${DateTime.now().millisecondsSinceEpoch}.wav';
    await _audioRecorder.start(
      const RecordConfig(encoder: AudioEncoder.wav),
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

  Future<void> _translateToSign() async {
    final recordedFilePath = _recordedFilePath;
    if (recordedFilePath == null) return;

    setState(() {
      _isTranslating = true;
    });

    try {
      final request = http.MultipartRequest('POST', Uri.parse(_backendEndpoint))
        ..headers['accept'] = 'application/json'
        ..files.add(
          await http.MultipartFile.fromPath(
            'speech_file',
            recordedFilePath,
            filename: 'speech.wav',
          ),
        );

      final streamedResponse = await request.send();
      if (streamedResponse.statusCode < 200 || streamedResponse.statusCode >= 300) {
        throw Exception('Server returned ${streamedResponse.statusCode}');
      }

      final response = await http.Response.fromStream(streamedResponse);
      final decodedJson = jsonDecode(response.body);
      if (decodedJson is! Map<String, dynamic>) {
        throw Exception('Unexpected response format');
      }

      final decodedText = decodedJson['transcribed_text']?.toString();
      final signIds = decodedJson['sign_ids'];
      final animationList = signIds is List
          ? signIds.map((id) => id.toString()).toList()
          : <String>[];

      if (!mounted) return;
      setState(() {
        _transcribedText = decodedText;
        _animationList = animationList;
      });

      await _playAvatarAnimations(animationList);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Translation failed: $error')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isTranslating = false;
      });
    }
  }

  Future<void> _playAvatarAnimations(List<String> animationsList) async {
    final availableAnimations =
        (await controller.getAvailableAnimations()).map((item) => item.toString()).toSet();
    debugPrint('Available Animations: $availableAnimations');

    if (availableAnimations.isEmpty || animationsList.isEmpty) {
      return;
    }

    for (final animationName in animationsList) {
      if (!availableAnimations.contains(animationName)) {
        continue;
      }

      controller.playAnimation(animationName: animationName);
      await Future.delayed(const Duration(milliseconds: 1200));
    }

    await Future.delayed(const Duration(milliseconds: 300));
    controller.stopAnimation();
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
                child: SizedBox(
                child: Flutter3DViewer(
                  activeGestureInterceptor: true,
                   progressBarColor: const Color(0xFF00CFFF),
                  enableTouch: true,
                  onProgress: (double progressValue) {
                    debugPrint('model loading progress : $progressValue');
                  },
                  onLoad: (String modelAddress) {
                    debugPrint('model loaded : $modelAddress');
                  },
                  onError: (String error) {
                    debugPrint('model failed to load : $error');
                  },
                  controller: controller,
                  src: 'assets/models/sign_avatar.glb',

                ),
              ),
              )
            else
              const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_transcribedText != null) ...[
              const SizedBox(height: 12),
              Text(
                'Transcribed: $_transcribedText',
                style: const TextStyle(fontSize: 14),
              ),
            ],
            if (_animationList.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Animation IDs: ${_animationList.join(', ')}',
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ],
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
              onPressed: _recordedFilePath == null || _isTranslating ? null : _translateToSign,
              icon: const Icon(Icons.gesture),
              label: Text(_isTranslating ? 'Translating...' : 'Translate to Sign'),
            ),
          ],
        ),
      ),
    );
  }
}