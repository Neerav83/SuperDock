import 'package:flutter/material.dart';

import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';
import 'glass_card.dart';

class WorkspaceCommandFormData {
  const WorkspaceCommandFormData({
    required this.command,
    required this.usesGitProject,
  });

  final String command;
  final bool usesGitProject;
}

class AddWorkspaceCommandDialog extends StatefulWidget {
  const AddWorkspaceCommandDialog({super.key});

  @override
  State<AddWorkspaceCommandDialog> createState() =>
      _AddWorkspaceCommandDialogState();
}

class _AddWorkspaceCommandDialogState extends State<AddWorkspaceCommandDialog> {
  late final TextEditingController _commandController;
  var _usesGitProject = true;

  static const _presets = <String, String>{
    'git add': 'Git Add',
    'git commit -m': 'Git Commit',
    'flutter run': 'Flutter Run',
    'git pull': 'Git Pull',
    'git push': 'Git Push',
    'git status': 'Git Status',
    'flutter pub get': 'Pub Get',
  };

  @override
  void initState() {
    super.initState();
    _commandController = TextEditingController();
  }

  @override
  void dispose() {
    _commandController.dispose();
    super.dispose();
  }

  void _applyPreset(String command) {
    setState(() {
      _commandController.text = command;
      _usesGitProject = command.startsWith('git ');
    });
  }

  WorkspaceCommandFormData? _buildResult() {
    final command = _commandController.text.trim();
    if (command.isEmpty) return null;
    return WorkspaceCommandFormData(
      command: command,
      usesGitProject: _usesGitProject,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add workspace command',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Commands run in the active workspace project folder.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _presets.entries
                    .map(
                      (entry) => ActionChip(
                        label: Text(entry.value),
                        onPressed: () => _applyPreset(entry.key),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _commandController,
                decoration: const InputDecoration(
                  labelText: 'Command',
                  hintText: 'git push',
                ),
                onChanged: (value) {
                  final trimmed = value.trim();
                  if (trimmed.startsWith('git ') && !_usesGitProject) {
                    setState(() => _usesGitProject = true);
                  } else if (trimmed.startsWith('flutter ') && _usesGitProject) {
                    setState(() => _usesGitProject = false);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Use workspace project path'),
                subtitle: const Text('Recommended for git and flutter commands'),
                value: _usesGitProject,
                onChanged: (value) => setState(() => _usesGitProject = value),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: () {
                      final result = _buildResult();
                      if (result == null) return;
                      Navigator.of(context).pop(result);
                    },
                    child: const Text('Add'),
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
