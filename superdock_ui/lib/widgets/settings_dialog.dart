import 'package:flutter/material.dart';

import '../services/settings_service.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import 'glass_card.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({
    super.key,
    required this.initialSettings,
  });

  final AppSettings initialSettings;

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late final TextEditingController _backendUrlController;
  late final TextEditingController _flutterProjectPathController;

  @override
  void initState() {
    super.initState();
    _backendUrlController =
        TextEditingController(text: widget.initialSettings.backendUrl);
    _flutterProjectPathController = TextEditingController(
      text: widget.initialSettings.flutterProjectPath ?? '',
    );
  }

  @override
  void dispose() {
    _backendUrlController.dispose();
    _flutterProjectPathController.dispose();
    super.dispose();
  }

  void _save() {
    final backendUrl = _backendUrlController.text.trim();
    if (backendUrl.isEmpty) {
      _showError('Backend URL cannot be empty.');
      return;
    }

    Navigator.of(context).pop(
      AppSettings(
        backendUrl: backendUrl,
        flutterProjectPath: _flutterProjectPathController.text.trim(),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Configure backend connection and Flutter project path.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: _backendUrlController,
                decoration: const InputDecoration(
                  labelText: 'Backend URL',
                  hintText: 'http://127.0.0.1:4545',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _flutterProjectPathController,
                decoration: const InputDecoration(
                  labelText: 'Flutter project path',
                  hintText: '/Users/you/projects/my_app',
                  helperText: 'Required for Flutter Run and Flutter Dev workspace.',
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
