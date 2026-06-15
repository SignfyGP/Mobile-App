import 'package:flutter/material.dart';
import 'package:signfy/core/constants/colors.dart';
import 'package:signfy/screens/avatar_screen.dart';
import 'package:signfy/screens/settings_screen.dart';
import 'package:signfy/screens/speech_to_video_screen.dart';
import 'package:signfy/screens/video_to_speech_screen.dart';
import 'package:signfy/widgets/explore_card.dart';
import 'package:signfy/widgets/home_header.dart';
import 'package:signfy/widgets/section_label.dart';
import 'package:signfy/widgets/translation_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _go(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
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
                    onPressed: () => _go(context, const SettingsScreen()),
                    icon: const Icon(Icons.settings_outlined),
                    color: AppColors.secondaryText,
                    tooltip: 'Settings',
                  ),
                ],
              ),
              const SizedBox(height: 40),
              const SectionLabel('Translation Modes'),
              const SizedBox(height: 16),
              TranslationCard(
                title: 'Speech to Sign',
                subtitle: 'Speak or type — watch the avatar sign it back',
                iconTop: Icons.mic_rounded,
                iconBottom: Icons.sign_language_rounded,
                gradientColors: const [Color(0xFF0077A8), Color(0xFF004D70)],
                accentColor: AppColors.cyan,
                onTap: () => _go(context, const SpeechToVideoPage()),
              ),
              const SizedBox(height: 16),
              TranslationCard(
                title: 'Sign to Speech',
                subtitle: 'Show your hands — get spoken words back',
                iconTop: Icons.sign_language_rounded,
                iconBottom: Icons.volume_up_rounded,
                gradientColors: const [Color(0xFF5B21B6), Color(0xFF3B0764)],
                accentColor: AppColors.purple,
                onTap: () => _go(context, const VideoToSpeechPage()),
              ),
              const SizedBox(height: 32),
              const SectionLabel('Explore'),
              const SizedBox(height: 16),
              ExploreCard(
                onTap: () => _go(context, const ViewerPage()),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
