import 'package:flutter/material.dart';

import '../core/models/workspace_quick_action.dart';
import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';
import 'add_workspace_command_dialog.dart';
import 'glass_card.dart';

class EditWorkspaceActionDialog extends StatefulWidget {
  const EditWorkspaceActionDialog({
    super.key,
    required this.action,
  });

  final WorkspaceQuickAction action;

  @override
  State<EditWorkspaceActionDialog> createState() =>
      _EditWorkspaceActionDialogState();
}

class _EditWorkspaceActionDialogState extends State<EditWorkspaceActionDialog> {
  late final TextEditingController _commandController;
  var _usesGitProject = true;

  bool get _isShell => widget.action.rawAction['type'] == 'shell';

  @override
  void initState() {
    super.initState();
    final cmd = widget.action.shellCommand ?? '';
    _commandController = TextEditingController(text: cmd);
    _usesGitProject = widget.action.usesGitProject ||
        widget.action.usesFlutterProject ||
        cmd.startsWith('git ');
  }

  @override
  void dispose() {
    _commandController.dispose();
    super.dispose();
  }

  WorkspaceCommandFormData? _buildShellResult() {
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
                'Redigera workspace-action',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.action.workspace.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_isShell) ...[
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
              ] else ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(widget.action.icon, color: widget.action.accentColor),
                  title: Text(widget.action.title),
                  subtitle: Text(
                    widget.action.appName ?? 'App',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop('delete'),
                    child: const Text(
                      'Ta bort',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Avbryt'),
                  ),
                  if (_isShell) ...[
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton(
                      onPressed: () {
                        final result = _buildShellResult();
                        if (result == null) return;
                        Navigator.of(context).pop(result);
                      },
                      child: const Text('Spara'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
