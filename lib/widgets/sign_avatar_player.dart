import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:signfy/core/constants/colors.dart';
import 'package:signfy/core/constants/strings.dart';
import 'package:signfy/core/services/sign_avatar_player_service.dart';

const _cyan = AppColors.cyan;

/// Playback speeds offered in the UI.
const signAvatarSpeeds = <double>[0.5, 1.0, 1.5, 2.0];

class SignAvatarPlayerController extends ChangeNotifier {
  SignAvatarPlayerController({SignAvatarPlayerService? service})
      : _service = service ?? SignAvatarPlayerService.instance;

  final SignAvatarPlayerService _service;
  InAppWebViewController? _webController;

  bool _serverReady = false;
  bool _modelReady = false;
  double _loadProgress = 0;
  List<String> _availableAnimations = <String>[];
  List<String> _currentSequence = <String>[];
  bool _isPlaying = false;
  bool _isPaused = false;
  double _speed = 1.0;
  String? _currentSign;
  String? _lastError;

  bool get serverReady => _serverReady;
  bool get modelReady => _modelReady;
  double get loadProgress => _loadProgress;
  List<String> get availableAnimations => List.unmodifiable(_availableAnimations);
  List<String> get currentSequence => List.unmodifiable(_currentSequence);
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  double get speed => _speed;
  String? get currentSign => _currentSign;

  Uri get viewerUri => _service.viewerUri;

  Future<void> initialize() async {
    await _service.ensureStarted();
    if (_serverReady) return;
    _serverReady = true;
    notifyListeners();
  }

  void attachWebViewController(InAppWebViewController controller) {
    _webController = controller;
    _registerHandlers(controller);
  }

  String? consumeError() {
    final error = _lastError;
    _lastError = null;
    return error;
  }

  Future<void> playSequence(
    List<String> ids, {
    double crossFadeDuration = 0.3,
  }) async {
    if (ids.isEmpty || !_modelReady) return;

    _currentSequence = List<String>.from(ids);
    _isPlaying = true;
    _isPaused = false;
    notifyListeners();

    await _callPlayer('playSignSequence', [
      {
        'signs': ids,
        'crossFadeDuration': crossFadeDuration,
        'playbackSpeed': _speed,
      },
    ]);
  }

  Future<void> replay() async {
    await playSequence(_currentSequence);
  }

  Future<void> togglePause() async {
    if (!_isPlaying) return;

    if (_isPaused) {
      await _callPlayer('resumePlayback');
    } else {
      await _callPlayer('pausePlayback');
    }

    _isPaused = !_isPaused;
    notifyListeners();
  }

  Future<void> setSpeed(double speed) async {
    _speed = speed;
    notifyListeners();
    await _callPlayer('setPlaybackSpeed', [speed]);
  }

  Future<void> resetToRestPose([double duration = 0.4]) async {
    await _callPlayer('resetToRestPose', [duration]);
  }

  void _registerHandlers(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'FlutterBridge',
      callback: (args) {
        if (args.isEmpty) return;

        Map<String, dynamic> msg;
        try {
          msg = Map<String, dynamic>.from(
            jsonDecode(args.first.toString()) as Map,
          );
        } catch (_) {
          return;
        }

        _onPlayerEvent(msg['event']?.toString(), msg);
      },
    );
  }

  void _onPlayerEvent(String? event, Map<String, dynamic> data) {
    switch (event) {
      case 'load_start':
        _loadProgress = 0;
        notifyListeners();
        break;
      case 'load_progress':
        final loaded = (data['loaded'] as num?)?.toDouble() ?? 0;
        final total = (data['total'] as num?)?.toDouble() ?? 0;
        if (total > 0) {
          _loadProgress = (loaded / total).clamp(0, 1);
          notifyListeners();
        }
        break;
      case 'ready':
        final names = (data['animations'] as List?)
            ?.map((animation) => animation.toString())
            .toList();
        _modelReady = true;
        _loadProgress = 1;
        if (names != null) {
          _availableAnimations = names;
        }
        notifyListeners();
        break;
      case 'sign_start':
        _currentSign = data['name']?.toString();
        _isPlaying = true;
        notifyListeners();
        break;
      case 'sequence_complete':
        _isPlaying = false;
        _isPaused = false;
        _currentSign = null;
        notifyListeners();
        break;
      case 'paused':
        _isPaused = true;
        notifyListeners();
        break;
      case 'resumed':
        _isPaused = false;
        notifyListeners();
        break;
      case 'speed_changed':
        final speed = (data['speed'] as num?)?.toDouble();
        if (speed != null) {
          _speed = speed;
          notifyListeners();
        }
        break;
      case 'error':
        _lastError = data['message']?.toString() ?? 'render error';
        _isPlaying = false;
        _isPaused = false;
        notifyListeners();
        break;
    }
  }

  Future<void> _callPlayer(String method, [List<Object?> args = const []]) async {
    final controller = _webController;
    if (controller == null) return;

    final encodedArgs = args.map(jsonEncode).join(', ');
    await controller.evaluateJavascript(
      source: "if (typeof window.$method === 'function') { window.$method($encodedArgs); }",
    );
  }
}

class SignAvatarPlayerView extends StatefulWidget {
  const SignAvatarPlayerView({super.key, required this.controller});

  final SignAvatarPlayerController controller;

  @override
  State<SignAvatarPlayerView> createState() => _SignAvatarPlayerViewState();
}

class _SignAvatarPlayerViewState extends State<SignAvatarPlayerView> {
  @override
  void initState() {
    super.initState();
    widget.controller.initialize();
  }

  @override
  void didUpdateWidget(covariant SignAvatarPlayerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      widget.controller.initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.serverReady) {
      return const SignAvatarLoadingOverlay(progress: 0);
    }

    return InAppWebView(
      initialUrlRequest:
          URLRequest(url: WebUri(widget.controller.viewerUri.toString())),
      initialUserScripts: UnmodifiableListView<UserScript>([
        UserScript(
          source:
              'window.FlutterBridge = { postMessage: function(m){ window.flutter_inappwebview.callHandler(\'FlutterBridge\', m); } };',
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
      ]),
      initialSettings: InAppWebViewSettings(
        transparentBackground: true,
        mediaPlaybackRequiresUserGesture: false,
        mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
        allowFileAccessFromFileURLs: true,
        allowUniversalAccessFromFileURLs: true,
        supportZoom: false,
        disableContextMenu: true,
      ),
      onWebViewCreated: widget.controller.attachWebViewController,
    );
  }
}

class SignAvatarHint extends StatelessWidget {
  const SignAvatarHint({
    super.key,
    required this.icon,
    required this.message,
    required this.iconColor,
    required this.textColor,
  });

  final IconData icon;
  final String message;
  final Color iconColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: iconColor),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(fontSize: 13, color: textColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class SignAvatarLoadingOverlay extends StatelessWidget {
  const SignAvatarLoadingOverlay({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).clamp(0, 100).toStringAsFixed(0);
    return ColoredBox(
      color: AppColors.cardDark.withValues(alpha: 0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 38,
              height: 38,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: _cyan,
                value: progress > 0 && progress < 1 ? progress : null,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              progress > 0 ? '${S.translating} $pct%' : S.translating,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SignAvatarSpeedSelector extends StatelessWidget {
  const SignAvatarSpeedSelector({
    super.key,
    required this.speed,
    required this.enabled,
    required this.onChanged,
  });

  final double speed;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.speed_rounded, size: 16, color: AppColors.secondaryText),
        const SizedBox(width: 8),
        for (final s in signAvatarSpeeds) ...[
          _SignAvatarSpeedChip(
            label: s == s.roundToDouble() ? '${s.toInt()}×' : '$s×',
            selected: (s - speed).abs() < 0.001,
            enabled: enabled,
            onTap: () => onChanged(s),
          ),
          const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _SignAvatarSpeedChip extends StatelessWidget {
  const _SignAvatarSpeedChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _cyan.withValues(alpha: 0.18) : AppColors.cardDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? _cyan : AppColors.cardBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: !enabled
                ? AppColors.secondaryText.withValues(alpha: 0.4)
                : selected
                    ? _cyan
                    : AppColors.secondaryText,
          ),
        ),
      ),
    );
  }
}

class SignAvatarSigningBadge extends StatelessWidget {
  const SignAvatarSigningBadge({super.key, this.label});

  final String? label;

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
            child: CircularProgressIndicator(strokeWidth: 1.5, color: _cyan),
          ),
          const SizedBox(width: 6),
          Text(
            label == null || label!.isEmpty ? S.signing : '${S.signing} · $label',
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

class SignAvatarChipRow extends StatelessWidget {
  const SignAvatarChipRow({
    super.key,
    required this.ids,
    required this.onReplay,
    required this.onPauseToggle,
    required this.isPaused,
    this.onRandom,
  });

  final List<String> ids;
  final VoidCallback? onReplay;
  final VoidCallback? onRandom;
  final VoidCallback? onPauseToggle;
  final bool isPaused;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: ids.map((id) => _SignAvatarChip(id)).toList(),
          ),
        ),
        const SizedBox(width: 8),
        if (onRandom != null) ...[
          _SignAvatarIconAction(
            icon: Icons.shuffle_rounded,
            tooltip: 'Random',
            onTap: onRandom,
          ),
          const SizedBox(width: 8),
        ],
        if (onPauseToggle != null) ...[
          _SignAvatarIconAction(
            icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            tooltip: isPaused ? 'Resume' : 'Pause',
            onTap: onPauseToggle,
          ),
          const SizedBox(width: 8),
        ],
        _SignAvatarIconAction(
          icon: Icons.replay_rounded,
          tooltip: 'Replay',
          onTap: onReplay,
        ),
      ],
    );
  }
}

class _SignAvatarIconAction extends StatelessWidget {
  const _SignAvatarIconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _cyan.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _cyan.withValues(alpha: 0.3)),
          ),
          child: Icon(
            icon,
            size: 18,
            color: onTap != null ? _cyan : AppColors.secondaryText,
          ),
        ),
      ),
    );
  }
}

class _SignAvatarChip extends StatelessWidget {
  const _SignAvatarChip(this.id);

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

class SignAvatarTranscriptionCard extends StatelessWidget {
  const SignAvatarTranscriptionCard({
    super.key,
    required this.text,
    required this.isArabic,
  });

  final String text;
  final bool isArabic;

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
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              textAlign: isArabic ? TextAlign.right : TextAlign.left,
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class SignAvatarAudioRow extends StatelessWidget {
  const SignAvatarAudioRow({
    super.key,
    required this.isPlaying,
    required this.onToggle,
  });

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
            color:
                isPlaying ? _cyan.withValues(alpha: 0.5) : AppColors.cardBorder,
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
              isPlaying ? S.stopPlayback : S.playRecordedAudio,
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