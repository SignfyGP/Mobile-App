import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:signfy/core/constants/colors.dart';
import 'package:signfy/core/services/settings_service.dart';

const _cyan = AppColors.cyan;

class SpeechToVideoPage extends StatefulWidget {
  const SpeechToVideoPage({super.key});

  @override
  State<SpeechToVideoPage> createState() => _SpeechToVideoPageState();
}

class _SpeechToVideoPageState extends State<SpeechToVideoPage> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Flutter3DController _avatarController = Flutter3DController();

  String get _backendEndpoint =>
      '${SettingsService.instance.backendBaseUrl}/speech-to-skeleton-video';

  String? _recordedFilePath;
  String? _transcribedText;
  List<String> _signIds = [];
  bool _isRecording = false;
  bool _isPlayingAudio = false;
  bool _isTranslating = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() => _isPlayingAudio = false);
    });
  }

  @override
  void dispose() {
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
        const SnackBar(content: Text('Microphone permission is required.')),
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
    final recordedFilePath = _recordedFilePath;
    if (recordedFilePath == null) return;

    setState(() {
      _isTranslating = true;
      _signIds = [];
      _transcribedText = null;
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

      await _playAvatarAnimations(ids);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Translation failed: $error')));
    } finally {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  Future<void> _playAvatarAnimations(List<String> animations) async {
    final available = (await _avatarController.getAvailableAnimations())
        .map((e) => e.toString())
        .toSet();

    if (available.isEmpty || animations.isEmpty) return;

    setState(() => _isPlaying = true);

    for (final name in animations) {
      if (!mounted) break;
      if (!available.contains(name)) continue;
      _avatarController.playAnimation(animationName: name);
      await Future.delayed(const Duration(milliseconds: 1200));
    }

    await Future.delayed(const Duration(milliseconds: 300));
    _avatarController.stopAnimation();

    if (mounted) setState(() => _isPlaying = false);
  }

  Future<void> _replay() async {
    if (_signIds.isEmpty || _isPlaying || _isTranslating) return;
    await _playAvatarAnimations(_signIds);
  }

  @override
  Widget build(BuildContext context) {
    final busy = _isTranslating || _isPlaying;
    final hasRecording = _recordedFilePath != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Speech to Sign')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_signIds.isEmpty && !_isTranslating && !_isRecording)
              const Center(child: _IdleHint()),
            if (_isRecording) const Center(child: _RecordingHint()),
            if (_isPlaying)
              const Positioned(top: 12, right: 12, child: _SigningBadge()),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    Flutter3DViewer(
                      activeGestureInterceptor: true,
                      progressBarColor: _cyan,
                      enableTouch: true,
                      controller: _avatarController,
                      src: 'assets/models/sign_avatar.glb',
                    ),
                  ],
                ),
              ),
            ),

            if (_transcribedText != null) ...[
              const SizedBox(height: 10),
              _TranscriptionCard(text: _transcribedText!),
            ],

            if (_signIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              _ChipRow(ids: _signIds, onReplay: busy ? null : _replay),
            ],

            const SizedBox(height: 12),

            if (hasRecording) ...[
              _AudioPlaybackRow(
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
              onPressed: !hasRecording || busy ? null : _translateToSign,
              icon: _isTranslating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : _isPlaying
                  ? const Icon(Icons.sign_language_rounded)
                  : const Icon(Icons.translate_rounded),
              label: Text(
                _isTranslating
                    ? 'Translating…'
                    : _isPlaying
                    ? 'Signing…'
                    : 'Translate to Sign',
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

class _IdleHint extends StatelessWidget {
  const _IdleHint();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mic_rounded,
            size: 52,
            color: AppColors.secondaryText.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 10),
          Text(
            'Record your voice below and tap Translate',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.secondaryText.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordingHint extends StatelessWidget {
  const _RecordingHint();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.graphic_eq_rounded,
            size: 52,
            color: Colors.redAccent.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 10),
          Text(
            'Listening…',
            style: TextStyle(
              fontSize: 13,
              color: Colors.redAccent.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SigningBadge extends StatelessWidget {
  const _SigningBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _cyan.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cyan.withValues(alpha: 0.4)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 8,
            height: 8,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: _cyan),
          ),
          SizedBox(width: 6),
          Text(
            'Signing',
            style: TextStyle(
              fontSize: 12,
              color: _cyan,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TranscriptionCard extends StatelessWidget {
  const _TranscriptionCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.record_voice_over_rounded, size: 16, color: _cyan),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _AudioPlaybackRow extends StatelessWidget {
  const _AudioPlaybackRow({required this.isPlaying, required this.onToggle});
  final bool isPlaying;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPlaying
                ? _cyan.withValues(alpha: 0.5)
                : AppColors.cardBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isPlaying
                  ? Icons.stop_circle_outlined
                  : Icons.play_circle_outline_rounded,
              color: _cyan,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              isPlaying ? 'Stop playback' : 'Play recorded audio',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.audiotrack_rounded,
              size: 14,
              color: AppColors.secondaryText.withValues(alpha: 0.5),
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

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.ids, required this.onReplay});
  final List<String> ids;
  final VoidCallback? onReplay;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: ids.map((id) => _Chip(id)).toList(),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Replay',
          child: GestureDetector(
            onTap: onReplay,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _cyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _cyan.withValues(alpha: 0.3)),
              ),
              child: Icon(
                Icons.replay_rounded,
                size: 18,
                color: onReplay != null ? _cyan : AppColors.secondaryText,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.id);
  final String id;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        id,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.secondaryText,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
