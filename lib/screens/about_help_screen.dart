import 'package:flutter/material.dart';
import 'package:signfy/core/constants/app_config.dart';
import 'package:signfy/core/constants/colors.dart';
import 'package:signfy/core/constants/strings.dart';
import 'package:signfy/widgets/section_label.dart';

class AboutHelpScreen extends StatelessWidget {
  const AboutHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(S.aboutHelp)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _AppHeader(),
          const SizedBox(height: 24),
          SectionLabel(S.about),
          const SizedBox(height: 12),
          _Card(
            child: Text(
              S.aboutIntro,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: AppColors.secondaryText,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SectionLabel(S.howToUse),
          const SizedBox(height: 12),
          _Card(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                _HelpTile(
                  icon: Icons.mic_rounded,
                  accent: AppColors.cyan,
                  title: S.helpSpeechTitle,
                  body: S.helpSpeechBody,
                ),
                _HelpTile(
                  icon: Icons.keyboard_rounded,
                  accent: const Color(0xFF10B981),
                  title: S.helpTextTitle,
                  body: S.helpTextBody,
                ),
                _HelpTile(
                  icon: Icons.sign_language_rounded,
                  accent: AppColors.purple,
                  title: S.helpSignTitle,
                  body: S.helpSignBody,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SectionLabel(S.tipsTitle),
          const SizedBox(height: 12),
          _Card(
            child: Column(
              children: [
                _TipRow(text: S.tipLighting),
                const SizedBox(height: 14),
                _TipRow(text: S.tipPermissions),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SectionLabel(S.credits),
          const SizedBox(height: 12),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  S.gradProject,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  S.madeWith,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
          ),
          padding: const EdgeInsets.all(14),
          child: Image.asset(AppConfig.logo),
        ),
        const SizedBox(height: 14),
        Text(
          AppConfig.appName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${AppConfig.description} · v1.0.0',
          style: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
        ),
      ],
    );
  }
}

class _HelpTile extends StatelessWidget {
  const _HelpTile({
    required this.icon,
    required this.accent,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
        iconColor: accent,
        collapsedIconColor: AppColors.secondaryText,
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: accent, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              body,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.lightbulb_outline, size: 18, color: AppColors.cyan),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.secondaryText,
            ),
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: child,
    );
  }
}
