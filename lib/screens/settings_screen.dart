import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:signfy/core/constants/app_config.dart';
import 'package:signfy/core/constants/colors.dart';
import 'package:signfy/core/services/settings_service.dart';
import 'package:signfy/widgets/section_label.dart';
import '../widgets/info_row.dart';

enum _ConnStatus { idle, testing, success, failed }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _urlController;
  _ConnStatus _connStatus = _ConnStatus.idle;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(
      text: SettingsService.instance.backendBaseUrl,
    );
    _urlController.addListener(_onUrlChanged);
  }

  @override
  void dispose() {
    _urlController.removeListener(_onUrlChanged);
    _urlController.dispose();
    super.dispose();
  }

  void _onUrlChanged() {
    final changed =
        _urlController.text.trim() != SettingsService.instance.backendBaseUrl;
    if (changed != _hasChanges) {
      setState(() {
        _hasChanges = changed;
        _connStatus = _ConnStatus.idle;
      });
    }
  }

  Future<void> _testConnection() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() => _connStatus = _ConnStatus.testing);

    try {
      await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      if (!mounted) return;
      setState(() => _connStatus = _ConnStatus.success);
    } catch (_) {
      if (!mounted) return;
      setState(() => _connStatus = _ConnStatus.failed);
    }
  }

  Future<void> _save() async {
    final url = _urlController.text.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL must start with http:// or https://'),
        ),
      );
      return;
    }

    await SettingsService.instance.setBackendBaseUrl(url);
    if (!mounted) return;
    setState(() => _hasChanges = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Settings saved')));
  }

  Future<void> _resetToDefaults() async {
    await SettingsService.instance.resetToDefaults();
    if (!mounted) return;
    _urlController.text = SettingsService.instance.backendBaseUrl;
    setState(() {
      _hasChanges = false;
      _connStatus = _ConnStatus.idle;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reset to defaults')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SectionLabel('Backend'),
          const SizedBox(height: 12),
          _SettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Base URL',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryText,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'http://10.0.2.2:8000',
                    hintStyle: const TextStyle(color: Color(0xFF3A5570)),
                    filled: true,
                    fillColor: const Color(0xFF0A1628),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.cyan),
                    ),
                    suffixIcon: _connStatus != _ConnStatus.idle
                        ? Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: _ConnStatusIcon(status: _connStatus),
                          )
                        : null,
                    suffixIconConstraints: const BoxConstraints(
                      maxHeight: 36,
                      maxWidth: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _connStatus == _ConnStatus.testing
                        ? null
                        : _testConnection,
                    icon: _connStatus == _ConnStatus.testing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.cyan,
                            ),
                          )
                        : const Icon(Icons.wifi_tethering_rounded, size: 18),
                    label: const Text('Test Connection'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.cyan,
                      side: const BorderSide(color: AppColors.cardBorder),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (_connStatus == _ConnStatus.success ||
                    _connStatus == _ConnStatus.failed) ...[
                  const SizedBox(height: 10),
                  _ConnStatusBanner(status: _connStatus),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionLabel('About'),
          const SizedBox(height: 12),
          _SettingsCard(
            child: Column(
              children: [
                InfoRow(label: 'App', value: AppConfig.appName),
                const _Divider(),
                const InfoRow(label: 'Version', value: '1.0.0'),
                const _Divider(),
                InfoRow(label: 'Description', value: AppConfig.description),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetToDefaults,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Color(0xFF3A2020)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Reset to Defaults'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _hasChanges ? _save : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: AppColors.cardBorder,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ConnStatusIcon extends StatelessWidget {
  const _ConnStatusIcon({required this.status});
  final _ConnStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == _ConnStatus.testing) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyan),
      );
    }
    if (status == _ConnStatus.success) {
      return const Icon(
        Icons.check_circle_rounded,
        color: Color(0xFF22C55E),
        size: 20,
      );
    }
    return const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 20);
  }
}

class _ConnStatusBanner extends StatelessWidget {
  const _ConnStatusBanner({required this.status});
  final _ConnStatus status;

  @override
  Widget build(BuildContext context) {
    final isSuccess = status == _ConnStatus.success;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSuccess ? const Color(0xFF052E16) : const Color(0xFF2D0A0A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSuccess ? const Color(0xFF166534) : const Color(0xFF7F1D1D),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess
                ? Icons.check_circle_outline_rounded
                : Icons.error_outline_rounded,
            size: 16,
            color: isSuccess ? const Color(0xFF22C55E) : Colors.redAccent,
          ),
          const SizedBox(width: 8),
          Text(
            isSuccess ? 'Server is reachable' : 'Could not reach server',
            style: TextStyle(
              fontSize: 13,
              color: isSuccess ? const Color(0xFF22C55E) : Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      color: AppColors.cardBorder,
      height: 1,
      thickness: 1,
    );
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
