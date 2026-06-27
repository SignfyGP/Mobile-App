import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:signfy/core/constants/app_config.dart';
import 'package:signfy/core/constants/colors.dart';
import 'package:signfy/core/constants/strings.dart';
import 'package:signfy/core/services/settings_service.dart';
import 'package:signfy/widgets/sign_avatar_player.dart';

const _cyan = AppColors.cyan;

class SpeechToVideoPage extends StatefulWidget {
  const SpeechToVideoPage({super.key});

  @override
  State<SpeechToVideoPage> createState() => _SpeechToVideoPageState();
}

class _SpeechToVideoPageState extends State<SpeechToVideoPage> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final SignAvatarPlayerController _avatarController =
      SignAvatarPlayerController();

  String get _transcribeEndpoint => '${AppConfig.backendBaseUrl}/v1/speech/transcribe';
  String get _text2glossEndpoint =>'${AppConfig.backendBaseUrl}/v1/gloss';

  String? _recordedFilePath;
  String? _transcribedText;
  List<String> _signIds = [];
  bool _isRecording = false;
  bool _isTranslating = false;

  @override
  void initState() {
    super.initState();
    _avatarController.addListener(_handleAvatarUpdate);
    _avatarController.initialize();
  }

  void _handleAvatarUpdate() {
    if (!mounted) return;

    final error = _avatarController.consumeError();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.translationFailed(error))),
      );
    }
    setState(() {});
  }

  @override
  void dispose() {
    _avatarController.removeListener(_handleAvatarUpdate);
    _avatarController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        if (path != null) _recordedFilePath = path;
      });
      if (path != null && _avatarController.modelReady) {
        await _translateToSign();
      }
      return;
    }

    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.micPermission)),
      );
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final path =
        '${tempDir.path}/speech_${DateTime.now().millisecondsSinceEpoch}.wav';

    await _audioRecorder.start(
      const RecordConfig(encoder: AudioEncoder.wav),
      path: path,
    );

    setState(() {
      _isRecording = true;
      _recordedFilePath = null;
      _transcribedText = null;
      _signIds = [];
    });
  }

  Future<String?> _transcribeAudio(String filePath) async {
  try {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(_transcribeEndpoint),
    );

    request.headers['accept'] = 'application/json';

    request.files.add(
      await http.MultipartFile.fromPath(
        'file', // Must match FastAPI parameter name
        filePath,
        contentType: http.MediaType('audio', 'wav'),
      ),
    );

    final streamedResponse = await request.send();
    final response =
        await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception(
          'Transcribe server returned ${response.statusCode}');
    }

    final decodedJson = jsonDecode(response.body);
    return decodedJson['text']?.toString();
  } catch (e) {
    rethrow;
  }
}

  Future<List<String>> _textToGlosses(String text) async {
    try {
      final response = await http
          .post(
            Uri.parse(_text2glossEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'accept': 'application/json',
            },
            body: jsonEncode({'text': text}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Text-to-gloss server returned ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected text-to-sign response format');
      }

      final raw = decoded['glosses'];
      return raw is List ? raw.map((e) => e.toString()).toList() : <String>[];
    } catch (error) {
      rethrow;
    }
  }

  Future<void> _translateToSign() async {
    print("TRanslate");
    // return;
    final recordedFilePath = _recordedFilePath;
    if (recordedFilePath == null || !_avatarController.modelReady) return;

    setState(() {
      _isTranslating = true;
      _signIds = [];
      _transcribedText = null;
    });

    try {
      final transcript = await _transcribeAudio(recordedFilePath);
      if (transcript == null || transcript.isEmpty) {
        throw Exception('No transcript received');
      }

      if (!mounted) return;
      setState(() => _transcribedText = transcript);
      final signIds = await _textToGlosses(transcript);

      final signsPadded =paddSigns(signIds);
      setState(() => _signIds = signsPadded);
      await _avatarController.playSequence(signsPadded);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.translationFailed(error))),
      );
    } finally {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  List<String> paddSigns(List<String> signs){
    return signs.map((sign) => sign.padLeft(4, '0')).toList();
  }

  Future<void> _setSpeed(double speed) async {
    await _avatarController.setSpeed(speed);
  }

  @override
  Widget build(BuildContext context) {
    final busy = _isTranslating || _avatarController.isPlaying;
    final hasRecording = _recordedFilePath != null;
    final isArabic = SettingsService.instance.appLanguage == 'ar';

    return Scaffold(
      appBar: AppBar(title: Text(S.speechToSignTitle)),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),

            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: SignAvatarPlayerView(controller: _avatarController),
                    ),
                    if (_isRecording)
                      Center(
                        child: SignAvatarHint(
                          icon: Icons.graphic_eq_rounded,
                          message: S.listening,
                          iconColor: Colors.redAccent.withValues(alpha: 0.6),
                          textColor: Colors.redAccent.withValues(alpha: 0.7),
                        ),
                      )
                    else if (_signIds.isEmpty && !_isTranslating && _avatarController.modelReady)
                      Center(
                        child: SignAvatarHint(
                          icon: Icons.mic_rounded,
                          message: S.recordHint,
                          iconColor: AppColors.secondaryText.withValues(alpha: 0.3),
                          textColor: AppColors.secondaryText.withValues(alpha: 0.5),
                        ),
                      ),
                    if (!_avatarController.modelReady)
                      Positioned.fill(
                        child: SignAvatarLoadingOverlay(
                          progress: _avatarController.loadProgress,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),
            SignAvatarSpeedSelector(
              speed: _avatarController.speed,
              enabled: _avatarController.modelReady,
              onChanged: _setSpeed,
            ),



            const SizedBox(height: 12),

            _RecordButton(
              isRecording: _isRecording,
              onTap: busy ? null : _toggleRecording,
            ),

          ],
        ),
      ),
    );
  }
}

class _RecordButton extends StatelessWidget {
  const _RecordButton({required this.isRecording, required this.onTap});

  final bool isRecording;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isRecording
                ? Colors.redAccent.withValues(alpha: 0.15)
                : _cyan.withValues(alpha: 0.12),
            border: Border.all(
              color: isRecording ? Colors.redAccent : _cyan,
              width: 2,
            ),
          ),
          child: Icon(
            isRecording ? Icons.stop_rounded : Icons.mic_rounded,
            size: 32,
            color: isRecording ? Colors.redAccent : _cyan,
          ),
        ),
      ),
    );
  }
}