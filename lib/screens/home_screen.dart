import 'package:flutter/material.dart';
import 'package:signfy/core/constants/colors.dart';
import 'package:signfy/core/constants/strings.dart';
import 'package:signfy/screens/about_help_screen.dart';
import 'package:signfy/screens/settings_screen.dart';
import 'package:signfy/screens/speech_to_video_screen.dart';
import 'package:signfy/screens/text_to_sign_screen.dart';
import 'package:signfy/screens/video_to_speech_screen.dart';
import 'package:signfy/widgets/home_header.dart';
import 'package:signfy/widgets/section_label.dart';
import 'package:signfy/widgets/translation_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _go(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _goSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(child: HomeHeader()),
                  IconButton(
                    onPressed: () =>
                        _go(context, const AboutHelpScreen()),
                    icon: const Icon(Icons.help_outline_rounded),
                    color: AppColors.secondaryText,
                    tooltip: S.aboutHelpTooltip,
                  ),
                  IconButton(
                    onPressed: _goSettings,
                    icon: const Icon(Icons.settings_outlined),
                    color: AppColors.secondaryText,
                    tooltip: S.settingsTooltip,
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SectionLabel(S.translationModes),
              const SizedBox(height: 16),
              TranslationCard(
                title: S.speechToSign,
                subtitle: S.speechToSignSub,
                iconTop: Icons.mic_rounded,
                iconBottom: Icons.sign_language_rounded,
                gradientColors: const [Color(0xFF0077A8), Color(0xFF004D70)],
                accentColor: AppColors.cyan,
                onTap: () => _go(context, const SpeechToVideoPage()),
              ),
              const SizedBox(height: 16),
              TranslationCard(
                title: S.textToSign,
                subtitle: S.textToSignSub,
                iconTop: Icons.keyboard_rounded,
                iconBottom: Icons.sign_language_rounded,
                gradientColors: const [Color(0xFF065F46), Color(0xFF047857)],
                accentColor: const Color(0xFF10B981),
                onTap: () => _go(context, const TextToSignPage()),
              ),
              const SizedBox(height: 16),
              TranslationCard(
                title: S.signToSpeech,
                subtitle: S.signToSpeechSub,
                iconTop: Icons.sign_language_rounded,
                iconBottom: Icons.volume_up_rounded,
                gradientColors: const [Color(0xFF5B21B6), Color(0xFF3B0764)],
                accentColor: AppColors.purple,
                onTap: () => _go(context, const VideoToSpeechPage()),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
