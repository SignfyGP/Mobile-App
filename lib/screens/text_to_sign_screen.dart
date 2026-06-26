import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:signfy/core/constants/app_config.dart';
import 'package:signfy/core/constants/colors.dart';
import 'package:signfy/core/constants/strings.dart';
import 'package:signfy/core/services/settings_service.dart';
import 'package:signfy/widgets/sign_avatar_player.dart';

const _cyan = AppColors.cyan;

final _arabicRegex = RegExp(r'[؀-ۿݐ-ݿࢠ-ࣿ0-9\s،؟.!]+');

class TextToSignPage extends StatefulWidget {
  const TextToSignPage({super.key});

  @override
  State<TextToSignPage> createState() => _TextToSignPageState();
}

class _TextToSignPageState extends State<TextToSignPage> {
  final TextEditingController _textController = TextEditingController();
  final SignAvatarPlayerController _avatarController =
      SignAvatarPlayerController();

  String get _endpoint => '${AppConfig.backendBaseUrl}/text-to-sign';

  List<String> _signIds = [];
  String? _transcribedText;
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
    _textController.dispose();
    super.dispose();
  }

  Future<void> _translate() async {
    final text = _textController.text.trim();
    if (text.isEmpty || !_avatarController.modelReady) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isTranslating = true;
      _signIds = [];
      _transcribedText = null;
    });

    try {
      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'accept': 'application/json',
            },
            body: jsonEncode({'text': text}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Server returned ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected response format');
      }

      final raw = decoded['sign_ids'];
      final ids = raw is List ? raw.map((e) => e.toString()).toList() : <String>[];

      if (!mounted) return;
      setState(() {
        _signIds = ids;
        _transcribedText = text;
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

  Future<void> _togglePause() async {
    await _avatarController.togglePause();
  }

  Future<void> _setSpeed(double speed) async {
    await _avatarController.setSpeed(speed);
  }

  Future<void> _replay() async {
    if (_signIds.isEmpty || _isTranslating) return;
    await _avatarController.replay();
  }

  @override
  Widget build(BuildContext context) {
    final busy = _isTranslating;
    final isArabic = SettingsService.instance.appLanguage == 'ar';

    return Scaffold(
      appBar: AppBar(title: Text(S.textToSignTitle)),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 15),

            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: SignAvatarPlayerView(controller: _avatarController),
                    ),
                    if (_signIds.isEmpty && !_isTranslating && _avatarController.modelReady)
                      Center(
                        child: SignAvatarHint(
                          icon: Icons.sign_language_rounded,
                          message: S.textIdleHint,
                          iconColor: Color(0x4DFFFFFF),
                          textColor: Color(0x80FFFFFF),
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

            if (_signIds.isNotEmpty) ...[
              const SizedBox(height: 10),
              SignAvatarChipRow(
                ids: _signIds,
                onReplay: (_avatarController.isPlaying || busy) ? null : _replay,
                onPauseToggle:
                    _avatarController.isPlaying ? _togglePause : null,
                isPaused: _avatarController.isPaused,
              ),
            ],

            const SizedBox(height: 12),

            if (_transcribedText != null) ...[
              const SizedBox(height: 2),
              SignAvatarTranscriptionCard(
                text: _transcribedText!,
                isArabic: isArabic,
              ),
            ],

            TextField(
              controller: _textController,
              inputFormatters: isArabic
                  ? [FilteringTextInputFormatter.allow(_arabicRegex)]
                  : null,
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              textAlign: isArabic ? TextAlign.right : TextAlign.left,
              keyboardType: TextInputType.text,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 15, color: Colors.white),
              decoration: InputDecoration(
                hintText: S.textHint,
                hintStyle: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 14,
                ),
                hintTextDirection:
                    isArabic ? TextDirection.rtl : TextDirection.ltr,
                filled: true,
                fillColor: AppColors.cardDark,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _cyan),
                ),
                suffixIcon: _textController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          size: 18,
                          color: AppColors.secondaryText,
                        ),
                        onPressed: () {
                          _textController.clear();
                          setState(() => _signIds = []);
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: (busy || !_avatarController.modelReady) ? null : _translate,
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
