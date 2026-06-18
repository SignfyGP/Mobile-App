import 'package:flutter/material.dart';
import 'package:signfy/core/constants/app_config.dart';
import 'package:signfy/core/constants/colors.dart';
import 'package:signfy/core/constants/strings.dart';
import 'package:signfy/core/services/settings_service.dart';
import 'package:signfy/widgets/section_label.dart';
import '../widgets/info_row.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _language;

  @override
  void initState() {
    super.initState();
    _language = SettingsService.instance.appLanguage;
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _setLanguage(String lang) async {
    await SettingsService.instance.setAppLanguage(lang);
    if (!mounted) return;
    setState(() => _language = lang);
  }

  Future<void> _resetToDefaults() async {
    await SettingsService.instance.resetToDefaults();
    if (!mounted) return;
    setState(() => _language = SettingsService.instance.appLanguage);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(S.resetDone)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(S.settings)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SectionLabel(S.language),
          const SizedBox(height: 12),
          _SettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.translationLanguage,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryText,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                _LanguageToggle(selected: _language, onSelect: _setLanguage),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SectionLabel(S.about),
          const SizedBox(height: 12),
          _SettingsCard(
            child: Column(
              children: [
                InfoRow(label: S.appLabel, value: AppConfig.appName),
                const _Divider(),
                InfoRow(label: S.version, value: '1.0.0'),
                const _Divider(),
                InfoRow(label: S.description, value: AppConfig.description),
              ],
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: _resetToDefaults,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Color(0xFF3A2020)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(S.resetToDefaults),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(color: AppColors.cardBorder, height: 1, thickness: 1);
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: child,
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({required this.selected, required this.onSelect});
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LangOption(
          code: 'ar',
          label: 'العربية',
          selected: selected == 'ar',
          onTap: () => onSelect('ar'),
        ),
        const SizedBox(width: 10),
        _LangOption(
          code: 'en',
          label: 'English',
          selected: selected == 'en',
          onTap: () => onSelect('en'),
        ),
      ],
    );
  }
}

class _LangOption extends StatelessWidget {
  const _LangOption({
    required this.code,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String code;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.cyan.withValues(alpha: 0.12)
                : AppColors.bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.cyan : AppColors.cardBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? AppColors.cyan : AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                code.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1,
                  color: selected
                      ? AppColors.cyan.withValues(alpha: 0.7)
                      : AppColors.secondaryText.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
