import 'package:flutter/material.dart';

import '../core/services/settings_service.dart';
import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';
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
  late final TextEditingController _gitProjectPathController;
  late final TextEditingController _backendCorePathController;
  late bool _autoStartBackend;

  @override
  void initState() {
    super.initState();
    _backendUrlController =
        TextEditingController(text: widget.initialSettings.backendUrl);
    _flutterProjectPathController = TextEditingController(
      text: widget.initialSettings.flutterProjectPath ?? '',
    );
    _gitProjectPathController = TextEditingController(
      text: widget.initialSettings.gitProjectPath ?? '',
    );
    _backendCorePathController = TextEditingController(
      text: widget.initialSettings.backendCorePath ??
          SettingsService.defaultBackendCorePath,
    );
    _autoStartBackend = widget.initialSettings.autoStartBackend;
  }

  @override
  void dispose() {
    _backendUrlController.dispose();
    _flutterProjectPathController.dispose();
    _gitProjectPathController.dispose();
    _backendCorePathController.dispose();
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
        gitProjectPath: _gitProjectPathController.text.trim(),
        backendCorePath: _backendCorePathController.text.trim(),
        autoStartBackend: _autoStartBackend,
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
        constraints: const BoxConstraints(maxWidth: 520),
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: SingleChildScrollView(
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
                  'Configure backend, project paths and auto-start.',
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
                  controller: _backendCorePathController,
                  decoration: const InputDecoration(
                    labelText: 'Backend core path',
                    hintText: '../superdock-core',
                    helperText: 'Used for auto-starting superdock-core.',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Auto-start backend'),
                  subtitle: const Text('Start superdock-core if it is offline'),
                  value: _autoStartBackend,
                  onChanged: (value) => setState(() => _autoStartBackend = value),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _flutterProjectPathController,
                  decoration: const InputDecoration(
                    labelText: 'Flutter project path',
                    hintText: '/Users/you/projects/my_app',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _gitProjectPathController,
                  decoration: const InputDecoration(
                    labelText: 'Git project path',
                    hintText: '/Users/you/projects/my_repo',
                    helperText: 'Used for Git Pull and git commands.',
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
      ),
    );
  }
}
