import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
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
  final AudioPlayer _audioPlayer = AudioPlayer();
  final SignAvatarPlayerController _avatarController =
      SignAvatarPlayerController();

  String get _backendEndpoint =>
      '${AppConfig.backendBaseUrl}/speech-to-skeleton-video';
  String get _backendEndpoint =>
      '${AppConfig.backendBaseUrl}/speech-to-skeleton-video';

  String? _recordedFilePath;
  String? _transcribedText;
  List<String> _signIds = [];
  bool _isRecording = false;
  bool _isPlayingAudio = false;
  bool _isTranslating = false;

  @override
  void initState() {
    super.initState();
    _avatarController.addListener(_handleAvatarUpdate);
    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() => _isPlayingAudio = false);
    });
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
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        if (path != null) _recordedFilePath = path;
      });
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

  Future<void> _toggleAudioPlayback() async {
    if (_recordedFilePath == null) return;

    if (_isPlayingAudio) {
      await _audioPlayer.stop();
      setState(() => _isPlayingAudio = false);
      return;
    }

    await _audioPlayer.play(DeviceFileSource(_recordedFilePath!));
    setState(() => _isPlayingAudio = true);
  }

  Future<void> _translateToSign() async {
    // print("TRanslate");
    // return;
    final recordedFilePath = _recordedFilePath;
    if (recordedFilePath == null || !_avatarController.modelReady) return;

    setState(() {
      _isTranslating = true;
      _signIds = [];
      _transcribedText = null;
    });

    try {
      final request = http.MultipartRequest('POST', Uri.parse(_backendEndpoint))
        ..headers['accept'] = 'application/json'
        ..fields['language'] = SettingsService.instance.appLanguage
        ..files.add(
          await http.MultipartFile.fromPath(
            'speech_file',
            recordedFilePath,
            filename: 'speech.wav',
          ),
        );

      final streamedResponse = await request.send();
      if (streamedResponse.statusCode < 200 ||
          streamedResponse.statusCode >= 300) {
        throw Exception('Server returned ${streamedResponse.statusCode}');
      }

      final response = await http.Response.fromStream(streamedResponse);
      final decodedJson = jsonDecode(response.body);
      if (decodedJson is! Map<String, dynamic>) {
        throw Exception('Unexpected response format');
      }

      final transcribedText = decodedJson['transcribed_text']?.toString();
      final signIds = decodedJson['sign_ids'];
      final ids = signIds is List
          ? signIds.map((id) => id.toString()).toList()
          : <String>[];

      if (!mounted) return;
      setState(() {
        _transcribedText = transcribedText;
        _signIds = ids;
      });

      await _avatarController.playSequence(ids);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.translationFailed(error))),
      );
    } finally {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  Future<void> _replay() async {
    if (_signIds.isEmpty || _isTranslating) return;
    await _avatarController.replay();
  }

  Future<void> _togglePause() async {
    await _avatarController.togglePause();
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
                    if (_avatarController.isPlaying)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: SignAvatarSigningBadge(
                          label: _avatarController.currentSign,
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

            if (_transcribedText != null) ...[
              const SizedBox(height: 10),
              SignAvatarTranscriptionCard(
                text: _transcribedText!,
                isArabic: isArabic,
              ),
            ],

            if (_signIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              SignAvatarChipRow(
                ids: _signIds,
                onReplay: (_avatarController.isPlaying || busy) ? null : _replay,
                onPauseToggle:
                    _avatarController.isPlaying ? _togglePause : null,
                isPaused: _avatarController.isPaused,
              ),
            ],

            const SizedBox(height: 12),

            if (hasRecording) ...[
              SignAvatarAudioRow(
                isPlaying: _isPlayingAudio,
                onToggle: _toggleAudioPlayback,
              ),
              const SizedBox(height: 12),
            ],

            _RecordButton(
              isRecording: _isRecording,
              onTap: busy ? null : _toggleRecording,
            ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed:
                  !hasRecording || busy || !_avatarController.modelReady
                      ? null
                      : _translateToSign,
              icon: _isTranslating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : _avatarController.isPlaying
                      ? const Icon(Icons.sign_language_rounded)
                      : const Icon(Icons.translate_rounded),
              label: Text(
                _isTranslating
                    ? S.translating
                    : _avatarController.isPlaying
                        ? S.signingEllipsis
                        : S.translateToSign,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _cyan,
                foregroundColor: Colors.black,
                disabledBackgroundColor: AppColors.cardBorder,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
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