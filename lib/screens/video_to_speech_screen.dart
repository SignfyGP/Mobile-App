import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signfy/core/constants/strings.dart';
import 'package:signfy/core/services/settings_service.dart';
import 'package:signfy/screens/camera_recorder_screen.dart';
import 'package:video_player/video_player.dart';

class VideoToSpeechPage extends StatefulWidget {
  const VideoToSpeechPage({super.key});

  @override
  State<VideoToSpeechPage> createState() => _VideoToSpeechPageState();
}

class _VideoToSpeechPageState extends State<VideoToSpeechPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  static const String _apiBaseUrl = 'http://16.16.174.165:8000/api/v1';
  String get _signToTextEndpoint => '$_apiBaseUrl/sign-to-text/recognize';
  String get _textToSpeechEndpoint => '$_apiBaseUrl/text-to-speech/synthesize';

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
      ..addListener(_onVideoTick)
      ..initialize()
          .then((_) {
            if (!mounted) return;
            setState(() {
              _recordedVideoPath = videoPath;
              _isPlayingVideo = false;
            });
          })
          .catchError((error) {
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(S.videoError(error))));
          });
  }

  void _onVideoTick() {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;
    final isPlaying = controller.value.isPlaying;
    if (isPlaying != _isPlayingVideo && mounted) {
      setState(() => _isPlayingVideo = isPlaying);
    }
  }

  Future<void> _recordNewVideo() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(S.noCameraAvailable)));
        return;
      }

      if (!mounted) return;
      final videoPath = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => CameraRecorderPage(cameras: cameras)),
      );

      if (videoPath != null) {
        await _initializeVideo(videoPath);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(S.videoRecordedOk)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.recordError(e))));
    }
  }

  Future<void> _selectVideoFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
      if (pickedFile != null) {
        await _initializeVideo(pickedFile.path);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(S.videoLoadedOk)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.selectError(e))));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.loadVideoFirst)));
      return;
    }

    setState(() => _isTranslating = true);

    try {
      final recognizedText = await _recognizeSignText(recordedVideoPath);

      if (!mounted) return;
      setState(() => _translatedText = recognizedText);

      final speechPath = await _synthesizeSpeech(recognizedText);

      await _audioPlayer.stop();

      if (!mounted) return;
      setState(() {
        _generatedSpeechPath = speechPath;
        _isPlayingSpeech = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.videoTranslatedOk)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.translationFailed(error))));
    } finally {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  Future<String> _recognizeSignText(String videoPath) async {
    final request =
        http.MultipartRequest('POST', Uri.parse(_signToTextEndpoint))
          ..headers['accept'] = 'application/json'
          ..files.add(
            await http.MultipartFile.fromPath(
              'file',
              videoPath,
              filename: 'video.mp4',
              contentType: http.MediaType('video', 'mp4'),
            ),
          );

    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode != 200) {
      throw Exception('Sign-to-text server returned ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected sign-to-text response format');
    }

    final text =
        (decoded['text'] ??
                decoded['recognized_text'] ??
                decoded['transcription'])
            ?.toString();
    if (text == null || text.isEmpty) {
      throw Exception('No text recognized from video');
    }
    return text;
  }

  Future<String> _synthesizeSpeech(String text) async {
    final response = await http.post(
      Uri.parse(_textToSpeechEndpoint),
      headers: {'Content-Type': 'application/json', 'accept': '*/*'},
      body: jsonEncode({'text': text}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Text-to-speech server returned ${response.statusCode}');
    }

    final contentType = response.headers['content-type'] ?? '';
    final extension =
        contentType.contains('mpeg') || contentType.contains('mp3')
        ? 'mp3'
        : 'wav';

    final tempDir = await getTemporaryDirectory();
    final outputPath =
        '${tempDir.path}/speech_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(response.bodyBytes, flush: true);
    return outputFile.path;
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

  bool get _hasVideo =>
      _videoController != null && _videoController!.value.isInitialized;

  @override
  Widget build(BuildContext context) {
    final isArabic = SettingsService.instance.appLanguage == 'ar';
    final previewHeight = (MediaQuery.of(context).size.height * 0.4).clamp(
      180.0,
      360.0,
    );

    return Scaffold(
      appBar: AppBar(title: Text(S.signToSpeechTitle)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stackSourceButtons = constraints.maxWidth < 480;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        S.inputVideo,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildVideoPreview(previewHeight),
                      const SizedBox(height: 12),
                      _buildSourceButtons(stackSourceButtons),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _hasVideo ? _toggleVideoPlayback : null,
                        icon: Icon(
                          _hasVideo && _isPlayingVideo
                              ? Icons.pause
                              : Icons.play_arrow,
                        ),
                        label: Text(
                          _hasVideo && _isPlayingVideo
                              ? S.pauseVideo
                              : S.playVideo,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _isTranslating || !_hasVideo
                            ? null
                            : _translateToSpeech,
                        icon: _isTranslating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.language),
                        label: Text(
                          _isTranslating ? S.translating : S.translateToSpeech,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        S.generatedSpeech,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_translatedText != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          S.translatedLabel(_translatedText!),
                          textDirection: isArabic
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _generatedSpeechPath == null
                            ? null
                            : _toggleSpeechPlayback,
                        icon: Icon(
                          _isPlayingSpeech
                              ? Icons.stop_circle
                              : Icons.play_arrow,
                        ),
                        label: Text(
                          _isPlayingSpeech
                              ? S.stopSpeech
                              : S.playGeneratedSpeech,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideoPreview(double height) {
    final controller = _videoController;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ColoredBox(
          color: const Color(0xFF162235),
          // FittedBox-style centering keeps any aspect ratio inside the box
          // without overflowing, regardless of portrait/landscape source.
          child: _hasVideo && controller != null
              ? Center(
                  child: AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: VideoPlayer(controller),
                  ),
                )
              : Center(
                  child: Text(
                    S.noVideoSelected,
                    style: const TextStyle(fontSize: 16, color: Colors.white54),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSourceButtons(bool stack) {
    final record = ElevatedButton.icon(
      onPressed: _recordNewVideo,
      icon: const Icon(Icons.videocam),
      label: Text(S.recordVideo, overflow: TextOverflow.ellipsis),
    );
    final select = ElevatedButton.icon(
      onPressed: _selectVideoFromGallery,
      icon: const Icon(Icons.folder_open),
      label: Text(S.selectVideo, overflow: TextOverflow.ellipsis),
    );

    if (stack) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [record, const SizedBox(height: 8), select],
      );
    }
    return Row(
      children: [
        Expanded(child: record),
        const SizedBox(width: 8),
        Expanded(child: select),
      ],
    );
  }
}
