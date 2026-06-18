import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:http/http.dart' as http;
import 'package:signfy/core/constants/app_config.dart';
import 'package:signfy/core/constants/colors.dart';
import 'package:signfy/core/constants/strings.dart';
import 'package:signfy/core/services/settings_service.dart';

const _cyan = AppColors.cyan;

final _arabicRegex = RegExp(r'[؀-ۿݐ-ݿࢠ-ࣿ0-9\s،؟.!]+');

class TextToSignPage extends StatefulWidget {
  const TextToSignPage({super.key});

  @override
  State<TextToSignPage> createState() => _TextToSignPageState();
}

class _TextToSignPageState extends State<TextToSignPage> {
  final Flutter3DController _avatarController = Flutter3DController();
  final TextEditingController _textController = TextEditingController();

  String get _endpoint => '${AppConfig.backendBaseUrl}/text-to-sign';

  List<String> _signIds = [];
  bool _isTranslating = false;
  bool _isPlaying = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _translate() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isTranslating = true;
      _signIds = [];
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
      final ids =
          raw is List ? raw.map((e) => e.toString()).toList() : <String>[];

      if (!mounted) return;
      setState(() => _signIds = ids);

      await _playAnimations(ids);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.translationFailed(error))),
      );
    } finally {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  Future<void> _playAnimations(List<String> ids) async {
    if (ids.isEmpty) return;

    final available = (await _avatarController.getAvailableAnimations())
        .map((e) => e.toString())
        .toSet();

    if (available.isEmpty) return;

    setState(() => _isPlaying = true);

    for (final id in ids) {
      if (!mounted) break;
      if (!available.contains(id)) continue;
      _avatarController.playAnimation(animationName: id);
      await Future.delayed(const Duration(milliseconds: 1200));
    }

    await Future.delayed(const Duration(milliseconds: 300));
    _avatarController.stopAnimation();

    if (mounted) setState(() => _isPlaying = false);
  }

  Future<void> _replay() async {
    if (_signIds.isEmpty || _isPlaying || _isTranslating) return;
    await _playAnimations(_signIds);
  }

  @override
  Widget build(BuildContext context) {
    final busy = _isTranslating || _isPlaying;
    final isArabic = SettingsService.instance.appLanguage == 'ar';

    return Scaffold(
      appBar: AppBar(title: Text(S.textToSignTitle)),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 15),

            if (_signIds.isEmpty && !_isTranslating)
              const Center(child: _IdleHint()),

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

            if (_signIds.isNotEmpty) ...[
              const SizedBox(height: 10),
              _ChipRow(ids: _signIds, onReplay: busy ? null : _replay),
            ],

            const SizedBox(height: 12),

            TextField(
              controller: _textController,
              inputFormatters: isArabic
                  ? [FilteringTextInputFormatter.allow(_arabicRegex)]
                  : null,
              textDirection:
                  isArabic ? TextDirection.rtl : TextDirection.ltr,
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

            // ── Translate button ───────────────────────────────────────────
            ElevatedButton.icon(
              onPressed: busy ? null : _translate,
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
                    ? S.translating
                    : _isPlaying
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

class _IdleHint extends StatelessWidget {
  const _IdleHint();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sign_language_rounded,
            size: 52,
            color: AppColors.secondaryText.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 10),
          Text(
            S.textIdleHint,
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 8,
            height: 8,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: _cyan,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            S.signing,
            style: const TextStyle(
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
