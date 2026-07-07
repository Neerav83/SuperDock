import 'package:flutter/material.dart';

import '../core/theme/icon_registry.dart';
import '../core/theme/spacing.dart';
import 'glass_card.dart';

class ActionFormData {
  const ActionFormData({
    required this.title,
    required this.status,
    required this.iconKey,
    required this.colorHex,
    required this.type,
    this.appName,
    this.cmd,
    this.cwd,
    this.usesFlutterProject = false,
    this.usesGitProject = false,
  });

  final String title;
  final String status;
  final String iconKey;
  final String colorHex;
  final String type;
  final String? appName;
  final String? cmd;
  final String? cwd;
  final bool usesFlutterProject;
  final bool usesGitProject;

  Map<String, dynamic> toPayload({String? id}) {
    final payload = <String, dynamic>{
      'title': title,
      'status': status,
      'icon': iconKey,
      'accentColor': colorHex,
      'type': type,
    };

    if (id != null) payload['id'] = id;

    if (type == 'open_app') {
      payload['appName'] = appName ?? '';
    } else if (type == 'shell') {
      payload['cmd'] = cmd ?? '';
      if (usesFlutterProject) payload['usesFlutterProject'] = true;
      if (usesGitProject) payload['usesGitProject'] = true;
      if (cwd != null && cwd!.isNotEmpty) payload['cwd'] = cwd;
    }

    return payload;
  }
}

class ActionDialog extends StatefulWidget {
  const ActionDialog({
    super.key,
    this.actionId,
    this.initialTitle = '',
    this.initialStatus = 'Run',
    this.initialIconKey = 'extension',
    this.initialColorHex = '#3B82F6',
    this.initialType = 'open_app',
    this.initialAppName = '',
    this.initialCmd = '',
    this.initialCwd = '',
    this.initialUsesFlutterProject = false,
    this.initialUsesGitProject = false,
    this.isEdit = false,
    this.isDefaultAction = false,
  });

  final String? actionId;
  final String initialTitle;
  final String initialStatus;
  final String initialIconKey;
  final String initialColorHex;
  final String initialType;
  final String initialAppName;
  final String initialCmd;
  final String initialCwd;
  final bool initialUsesFlutterProject;
  final bool initialUsesGitProject;
  final bool isEdit;
  final bool isDefaultAction;

  @override
  State<ActionDialog> createState() => _ActionDialogState();
}

class _ActionDialogState extends State<ActionDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _statusController;
  late final TextEditingController _appNameController;
  late final TextEditingController _cmdController;
  late final TextEditingController _cwdController;
  late String _iconKey;
  late String _colorHex;
  late String _type;
  late bool _usesFlutterProject;
  late bool _usesGitProject;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _statusController = TextEditingController(text: widget.initialStatus);
    _appNameController = TextEditingController(text: widget.initialAppName);
    _cmdController = TextEditingController(text: widget.initialCmd);
    _cwdController = TextEditingController(text: widget.initialCwd);
    _iconKey = _resolveIconKey(widget.initialIconKey);
    _colorHex = normalizeColorHex(widget.initialColorHex);
    _type = widget.initialType;
    _usesFlutterProject = widget.initialUsesFlutterProject;
    _usesGitProject = widget.initialUsesGitProject;
  }

  String _resolveIconKey(String key) {
    return iconOptions.containsKey(key) ? key : 'extension';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _statusController.dispose();
    _appNameController.dispose();
    _cmdController.dispose();
    _cwdController.dispose();
    super.dispose();
  }

  ActionFormData? _buildFormData() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showError('Action title is required.');
      return null;
    }

    if (_type == 'open_app') {
      final appName = _appNameController.text.trim();
      if (appName.isEmpty) {
        _showError('App name is required for open_app action.');
        return null;
      }
    } else if (_type == 'shell') {
      final cmd = _cmdController.text.trim();
      if (cmd.isEmpty) {
        _showError('Command is required for shell action.');
        return null;
      }
    }

    return ActionFormData(
      title: title,
      status: _statusController.text.trim().isEmpty
          ? 'Run'
          : _statusController.text.trim(),
      iconKey: _iconKey,
      colorHex: _colorHex,
      type: _type,
      appName: _appNameController.text.trim(),
      cmd: _cmdController.text.trim(),
      cwd: _cwdController.text.trim(),
      usesFlutterProject: _usesFlutterProject,
      usesGitProject: _usesGitProject,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildIconDropdown() {
    return DropdownButtonFormField<String>(
      key: ValueKey('icon-$_iconKey'),
      value: _iconKey,
      decoration: const InputDecoration(labelText: 'Icon'),
      items: iconOptions.entries
          .map(
            (entry) => DropdownMenuItem(
              value: entry.key,
              child: Row(
                children: [
                  Icon(iconForKey(entry.key), size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Text(entry.value),
                ],
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) setState(() => _iconKey = value);
      },
    );
  }

  Widget _buildColorDropdown() {
    final colorValue = normalizeColorHex(_colorHex);

    return DropdownButtonFormField<String>(
      key: ValueKey('color-$colorValue'),
      value: colorValue,
      decoration: const InputDecoration(labelText: 'Accent color'),
      items: colorOptions.entries
          .map(
            (entry) => DropdownMenuItem(
              value: entry.key,
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: colorFromHex(entry.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(entry.value),
                ],
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) setState(() => _colorHex = value);
      },
    );
  }

  Widget _buildTypeSelector() {
    return DropdownButtonFormField<String>(
      key: ValueKey('type-$_type'),
      value: _type,
      decoration: const InputDecoration(labelText: 'Action type'),
      items: const [
        DropdownMenuItem(value: 'open_app', child: Text('Open App')),
        DropdownMenuItem(value: 'shell', child: Text('Shell Command')),
      ],
      onChanged: widget.isEdit
          ? null
          : (value) {
              if (value != null) setState(() => _type = value);
            },
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
                  widget.isEdit ? 'Edit Action' : 'New Action',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSpacing.xl),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _statusController,
                  decoration: const InputDecoration(
                    labelText: 'Status text',
                    hintText: 'Run, Open, Start, etc.',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildTypeSelector(),
                const SizedBox(height: AppSpacing.lg),
                _buildIconDropdown(),
                const SizedBox(height: AppSpacing.lg),
                _buildColorDropdown(),
                const SizedBox(height: AppSpacing.xl),
                if (_type == 'open_app') ...[
                  TextField(
                    controller: _appNameController,
                    decoration: const InputDecoration(
                      labelText: 'App name',
                      hintText: 'Visual Studio Code',
                    ),
                  ),
                ] else if (_type == 'shell') ...[
                  TextField(
                    controller: _cmdController,
                    decoration: const InputDecoration(
                      labelText: 'Command',
                      hintText: 'git status',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _cwdController,
                    decoration: const InputDecoration(
                      labelText: 'Working directory (optional)',
                      hintText: '/path/to/project',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CheckboxListTile(
                    title: const Text('Use Flutter project path'),
                    value: _usesFlutterProject,
                    onChanged: (value) {
                      setState(() {
                        _usesFlutterProject = value ?? false;
                        if (_usesFlutterProject) _usesGitProject = false;
                      });
                    },
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: const Text('Use Git project path'),
                    value: _usesGitProject,
                    onChanged: (value) {
                      setState(() {
                        _usesGitProject = value ?? false;
                        if (_usesGitProject) _usesFlutterProject = false;
                      });
                    },
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
                const SizedBox(height: AppSpacing.xxl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (widget.isEdit && !widget.isDefaultAction)
                      TextButton(
                        onPressed: () => Navigator.of(context).pop('delete'),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton(
                      onPressed: () {
                        final data = _buildFormData();
                        if (data != null) Navigator.of(context).pop(data);
                      },
                      child: Text(widget.isEdit ? 'Save' : 'Create'),
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
