import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signfy/core/constants/strings.dart';
import 'package:signfy/core/services/settings_service.dart';
import 'package:video_player/video_player.dart';

class VideoToSpeechPage extends StatefulWidget {
  const VideoToSpeechPage({super.key});

  @override
  State<VideoToSpeechPage> createState() => _VideoToSpeechPageState();
}

class _VideoToSpeechPageState extends State<VideoToSpeechPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  String get _backendEndpoint =>
      '${SettingsService.instance.backendBaseUrl}/video-to-speech';

  VideoPlayerController? _videoController;
  String? _recordedVideoPath;
  String? _generatedSpeechPath;
  String? _translatedText;
  bool _isPlayingVideo = false;
  bool _isPlayingSpeech = false;
  bool _isTranslating = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() => _isPlayingSpeech = false);
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo(String videoPath) async {
    _videoController?.dispose();
    _videoController = VideoPlayerController.file(File(videoPath))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _recordedVideoPath = videoPath;
          _isPlayingVideo = false;
        });
      }).catchError((error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.videoError(error))),
        );
      });
  }

  Future<void> _recordNewVideo() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.noCameraAvailable)),
        );
        return;
      }

      if (!mounted) return;
      final videoPath = await Navigator.push<String>(
        context,
        MaterialPageRoute(
            builder: (_) => CameraRecorderPage(camera: cameras[0])),
      );

      if (videoPath != null) {
        await _initializeVideo(videoPath);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.videoRecordedOk)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.recordError(e))),
      );
    }
  }

  Future<void> _selectVideoFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
      if (pickedFile != null) {
        await _initializeVideo(pickedFile.path);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.videoLoadedOk)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.selectError(e))),
      );
    }
  }

  Future<void> _toggleVideoPlayback() async {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;

    controller.value.isPlaying
        ? await controller.pause()
        : await controller.play();
    if (!mounted) return;
    setState(() => _isPlayingVideo = controller.value.isPlaying);
  }

  Future<void> _translateToSpeech() async {
    final recordedVideoPath = _recordedVideoPath;
    if (recordedVideoPath == null ||
        _videoController == null ||
        !_videoController!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.loadVideoFirst)),
      );
      return;
    }

    setState(() => _isTranslating = true);

    try {
      final request = http.MultipartRequest('POST', Uri.parse(_backendEndpoint))
        ..headers['accept'] = 'application/json'
        ..files.add(await http.MultipartFile.fromPath(
          'video_file',
          recordedVideoPath,
          filename: 'video.mp4',
        ));

      final streamedResponse = await request.send();
      if (streamedResponse.statusCode < 200 ||
          streamedResponse.statusCode >= 300) {
        throw Exception('Server returned ${streamedResponse.statusCode}');
      }

      final responseBytes = await streamedResponse.stream.toBytes();
      final tempDir = await getTemporaryDirectory();
      final outputPath =
          '${tempDir.path}/speech_${DateTime.now().millisecondsSinceEpoch}.wav';
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(responseBytes, flush: true);

      final encodedText = streamedResponse.headers['x-translated-text'];
      final decodedText =
          encodedText == null ? null : Uri.decodeComponent(encodedText);

      await _audioPlayer.stop();

      if (!mounted) return;
      setState(() {
        _generatedSpeechPath = outputFile.path;
        _translatedText = decodedText;
        _isPlayingSpeech = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.videoTranslatedOk)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.translationFailed(error))),
      );
    } finally {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  Future<void> _toggleSpeechPlayback() async {
    if (_generatedSpeechPath == null) return;

    if (_isPlayingSpeech) {
      await _audioPlayer.stop();
      setState(() => _isPlayingSpeech = false);
      return;
    }

    await _audioPlayer.play(DeviceFileSource(_generatedSpeechPath!));
    setState(() => _isPlayingSpeech = true);
  }

  @override
  Widget build(BuildContext context) {
    final videoController = _videoController;
    final hasVideo =
        videoController != null && videoController.value.isInitialized;
    final isArabic = SettingsService.instance.appLanguage == 'ar';

    return Scaffold(
      appBar: AppBar(title: Text(S.signToSpeechTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                S.inputVideo,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w600),
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
                    color: const Color(0xFF162235),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      S.noVideoSelected,
                      style: const TextStyle(
                          fontSize: 16, color: Colors.white54),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _recordNewVideo,
                      icon: const Icon(Icons.videocam),
                      label: Text(S.recordVideo),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _selectVideoFromGallery,
                      icon: const Icon(Icons.folder_open),
                      label: Text(S.selectVideo),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: hasVideo ? _toggleVideoPlayback : null,
                icon: Icon(hasVideo && _isPlayingVideo
                    ? Icons.pause
                    : Icons.play_arrow),
                label: Text(hasVideo && _isPlayingVideo
                    ? S.pauseVideo
                    : S.playVideo),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed:
                    _isTranslating || !hasVideo ? null : _translateToSpeech,
                icon: _isTranslating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.language),
                label: Text(
                    _isTranslating ? S.translating : S.translateToSpeech),
              ),
              const SizedBox(height: 24),
              Text(
                S.generatedSpeech,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w600),
              ),
              if (_translatedText != null) ...[
                const SizedBox(height: 8),
                Text(
                  S.translatedLabel(_translatedText!),
                  textDirection:
                      isArabic ? TextDirection.rtl : TextDirection.ltr,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _generatedSpeechPath == null
                    ? null
                    : _toggleSpeechPlayback,
                icon: Icon(_isPlayingSpeech
                    ? Icons.stop_circle
                    : Icons.play_arrow),
                label: Text(
                    _isPlayingSpeech ? S.stopSpeech : S.playGeneratedSpeech),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CameraRecorderPage extends StatefulWidget {
  const CameraRecorderPage({super.key, required this.camera});
  final CameraDescription camera;

  @override
  State<CameraRecorderPage> createState() => _CameraRecorderPageState();
}

class _CameraRecorderPageState extends State<CameraRecorderPage> {
  late final CameraController _cameraController;
  late final Future<void> _initFuture;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _cameraController =
        CameraController(widget.camera, ResolutionPreset.high);
    _initFuture = _cameraController.initialize();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        final file = await _cameraController.stopVideoRecording();
        if (mounted) Navigator.pop(context, file.path);
      } else {
        await _cameraController.startVideoRecording();
        setState(() => _isRecording = true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.recordVideoTitle)),
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              Expanded(child: CameraPreview(_cameraController)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _toggleRecording,
                      icon: Icon(_isRecording
                          ? Icons.stop_circle
                          : Icons.videocam),
                      label: Text(_isRecording
                          ? S.stopRecording
                          : S.startRecording),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: Text(S.cancel),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
