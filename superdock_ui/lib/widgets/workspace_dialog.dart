import 'package:flutter/material.dart';

import '../core/theme/icon_registry.dart';
import '../core/theme/spacing.dart';
import 'glass_card.dart';

class WorkspaceFormData {
  const WorkspaceFormData({
    required this.name,
    required this.description,
    required this.shortcut,
    required this.iconKey,
    required this.colorHex,
    required this.apps,
    this.shellCommand,
  });

  final String name;
  final String description;
  final String shortcut;
  final String iconKey;
  final String colorHex;
  final String apps;
  final String? shellCommand;

  Map<String, dynamic> toPayload({String? id}) {
    final actions = <Map<String, dynamic>>[];
    for (final app in apps.split(',')) {
      final name = app.trim();
      if (name.isNotEmpty) {
        actions.add({'type': 'open_app', 'name': name});
      }
    }

    final shell = shellCommand?.trim();
    if (shell != null && shell.isNotEmpty) {
      actions.add({'type': 'shell', 'cmd': shell});
    }

    final payload = <String, dynamic>{
      'name': name,
      'description': description,
      'shortcut': shortcut.isEmpty ? null : shortcut,
      'icon': iconKey,
      'accentColor': colorHex,
      'actions': actions,
    };
    if (id != null) payload['id'] = id;
    return payload;
  }
}

class WorkspaceDialog extends StatefulWidget {
  const WorkspaceDialog({
    super.key,
    this.workspaceId,
    this.initialName = '',
    this.initialDescription = '',
    this.initialShortcut = '',
    this.initialIconKey = 'grid_view',
    this.initialColorHex = '#3B82F6',
    this.initialApps = '',
    this.initialShellCommand = '',
    this.isEdit = false,
  });

  final String? workspaceId;
  final String initialName;
  final String initialDescription;
  final String initialShortcut;
  final String initialIconKey;
  final String initialColorHex;
  final String initialApps;
  final String initialShellCommand;
  final bool isEdit;

  @override
  State<WorkspaceDialog> createState() => _WorkspaceDialogState();
}

class _WorkspaceDialogState extends State<WorkspaceDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _shortcutController;
  late final TextEditingController _appsController;
  late final TextEditingController _shellController;
  late String _iconKey;
  late String _colorHex;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _descriptionController =
        TextEditingController(text: widget.initialDescription);
    _shortcutController = TextEditingController(text: widget.initialShortcut);
    _appsController = TextEditingController(text: widget.initialApps);
    _shellController = TextEditingController(text: widget.initialShellCommand);
    _iconKey = _resolveIconKey(widget.initialIconKey);
    _colorHex = normalizeColorHex(widget.initialColorHex);
  }

  String _resolveIconKey(String key) {
    return iconOptions.containsKey(key) ? key : 'grid_view';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _shortcutController.dispose();
    _appsController.dispose();
    _shellController.dispose();
    super.dispose();
  }

  WorkspaceFormData? _buildFormData() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('Workspace name is required.');
      return null;
    }

    return WorkspaceFormData(
      name: name,
      description: _descriptionController.text.trim(),
      shortcut: _shortcutController.text.trim(),
      iconKey: _iconKey,
      colorHex: _colorHex,
      apps: _appsController.text,
      shellCommand: _shellController.text.trim(),
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
      initialValue: _iconKey,
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
      initialValue: colorValue,
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
                  widget.isEdit ? 'Edit Workspace' : 'New Workspace',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSpacing.xl),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _shortcutController,
                  decoration: const InputDecoration(
                    labelText: 'Shortcut (optional)',
                    hintText: '⌘5',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildIconDropdown(),
                const SizedBox(height: AppSpacing.lg),
                _buildColorDropdown(),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _appsController,
                  decoration: const InputDecoration(
                    labelText: 'Apps to open',
                    hintText: 'Visual Studio Code, Terminal, Docker',
                    helperText: 'Comma-separated app names',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _shellController,
                  decoration: const InputDecoration(
                    labelText: 'Shell command (optional)',
                    hintText: 'docker ps',
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (widget.isEdit)
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
