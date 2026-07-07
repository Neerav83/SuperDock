import 'package:flutter/material.dart';

import '../core/models/workspace_action_rules.dart';
import '../core/theme/icon_registry.dart';
import '../core/theme/spacing.dart';
import 'glass_card.dart';

const ideOptions = <String, String>{
  'Visual Studio Code': 'VS Code',
  'Cursor': 'Cursor',
  'Xcode': 'Xcode',
  'Terminal': 'Terminal',
  'Docker': 'Docker',
  'Figma': 'Figma',
  'Simulator': 'Simulator',
  'Safari': 'Safari',
};

class WorkspaceFormData {
  const WorkspaceFormData({
    required this.name,
    required this.description,
    required this.shortcut,
    required this.iconKey,
    required this.colorHex,
    required this.projectPath,
    this.ideApp,
    required this.apps,
    this.shellCommand,
    this.runFlutterOnLaunch = false,
    this.gitPullOnLaunch = false,
    this.preservedShellActions = const [],
  });

  final String name;
  final String description;
  final String shortcut;
  final String iconKey;
  final String colorHex;
  final String projectPath;
  final String? ideApp;
  final String apps;
  final String? shellCommand;
  final bool runFlutterOnLaunch;
  final bool gitPullOnLaunch;
  final List<Map<String, dynamic>> preservedShellActions;

  factory WorkspaceFormData.fromWorkspace({
    required String name,
    required String description,
    required String shortcut,
    required String iconKey,
    required String colorHex,
    String? projectPath,
    required List<Map<String, dynamic>> actions,
  }) {
    String? ide;
    final extraApps = <String>[];
    var runFlutter = false;
    var gitPull = false;
    final preserved = <Map<String, dynamic>>[];

    for (final action in actions) {
      final type = action['type'] as String?;
      if (type == 'open_app') {
        final appName = action['name'] as String? ?? '';
        if (ide == null && ideOptions.containsKey(appName)) {
          ide = appName;
        } else if (appName.isNotEmpty) {
          extraApps.add(appName);
        }
      } else if (type == 'shell') {
        final cmd = (action['cmd'] as String? ?? '').trim();
        if (WorkspaceActionRules.isFlutterRun(action)) {
          runFlutter = true;
        } else if (WorkspaceActionRules.isGitPull(action)) {
          gitPull = true;
        } else if (cmd.isNotEmpty) {
          preserved.add(Map<String, dynamic>.from(action));
        }
      }
    }

    return WorkspaceFormData(
      name: name,
      description: description,
      shortcut: shortcut,
      iconKey: iconKey,
      colorHex: colorHex,
      projectPath: projectPath ?? '',
      ideApp: ide,
      apps: extraApps.join(', '),
      runFlutterOnLaunch: runFlutter,
      gitPullOnLaunch: gitPull,
      preservedShellActions: preserved,
    );
  }

  Map<String, dynamic> toPayload({String? id}) {
    final actions = <Map<String, dynamic>>[];

    if (ideApp != null && ideApp!.isNotEmpty) {
      actions.add({'type': 'open_app', 'name': ideApp});
    }

    for (final app in apps.split(',')) {
      final name = app.trim();
      if (name.isNotEmpty) {
        actions.add({'type': 'open_app', 'name': name});
      }
    }

    if (runFlutterOnLaunch) {
      actions.add({
        'type': 'shell',
        'cmd': 'flutter run',
        'usesFlutterProject': true,
      });
    }

    if (gitPullOnLaunch) {
      actions.add({
        'type': 'shell',
        'cmd': 'git pull',
        'usesGitProject': true,
      });
    }

    final shell = shellCommand?.trim();
    if (shell != null && shell.isNotEmpty) {
      actions.add({'type': 'shell', 'cmd': shell});
    }

    for (final action in preservedShellActions) {
      actions.add(Map<String, dynamic>.from(action));
    }

    final payload = <String, dynamic>{
      'name': name,
      'description': description,
      'shortcut': shortcut.isEmpty ? null : shortcut,
      'icon': iconKey,
      'accentColor': colorHex,
      'projectPath': projectPath.trim(),
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
    this.initialProjectPath = '',
    this.initialIdeApp,
    this.initialApps = '',
    this.initialShellCommand = '',
    this.initialRunFlutterOnLaunch = false,
    this.initialGitPullOnLaunch = false,
    this.isEdit = false,
  });

  final String? workspaceId;
  final String initialName;
  final String initialDescription;
  final String initialShortcut;
  final String initialIconKey;
  final String initialColorHex;
  final String initialProjectPath;
  final String? initialIdeApp;
  final String initialApps;
  final String initialShellCommand;
  final bool initialRunFlutterOnLaunch;
  final bool initialGitPullOnLaunch;
  final bool isEdit;

  @override
  State<WorkspaceDialog> createState() => _WorkspaceDialogState();
}

class _WorkspaceDialogState extends State<WorkspaceDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _shortcutController;
  late final TextEditingController _projectPathController;
  late final TextEditingController _appsController;
  late final TextEditingController _shellController;
  late String _iconKey;
  late String _colorHex;
  late String? _ideApp;
  late bool _runFlutterOnLaunch;
  late bool _gitPullOnLaunch;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _descriptionController =
        TextEditingController(text: widget.initialDescription);
    _shortcutController = TextEditingController(text: widget.initialShortcut);
    _projectPathController =
        TextEditingController(text: widget.initialProjectPath);
    _appsController = TextEditingController(text: widget.initialApps);
    _shellController = TextEditingController(text: widget.initialShellCommand);
    _iconKey = _resolveIconKey(widget.initialIconKey);
    _colorHex = normalizeColorHex(widget.initialColorHex);
    _ideApp = widget.initialIdeApp;
    _runFlutterOnLaunch = widget.initialRunFlutterOnLaunch;
    _gitPullOnLaunch = widget.initialGitPullOnLaunch;
  }

  String _resolveIconKey(String key) {
    return iconOptions.containsKey(key) ? key : 'grid_view';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _shortcutController.dispose();
    _projectPathController.dispose();
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

    final projectPath = _projectPathController.text.trim();
    if (projectPath.isEmpty) {
      _showError('Project path is required.');
      return null;
    }

    return WorkspaceFormData(
      name: name,
      description: _descriptionController.text.trim(),
      shortcut: _shortcutController.text.trim(),
      iconKey: _iconKey,
      colorHex: _colorHex,
      projectPath: projectPath,
      ideApp: _ideApp,
      apps: _appsController.text,
      shellCommand: _shellController.text.trim(),
      runFlutterOnLaunch: _runFlutterOnLaunch,
      gitPullOnLaunch: _gitPullOnLaunch,
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

  Widget _buildIdeDropdown() {
    return DropdownButtonFormField<String?>(
      key: ValueKey('ide-$_ideApp'),
      initialValue: _ideApp,
      decoration: const InputDecoration(
        labelText: 'Primary IDE',
        helperText: 'Opens when you launch this workspace',
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('None'),
        ),
        ...ideOptions.entries.map(
          (entry) => DropdownMenuItem<String?>(
            value: entry.key,
            child: Text(entry.value),
          ),
        ),
      ],
      onChanged: (value) => setState(() => _ideApp = value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
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
                  controller: _projectPathController,
                  decoration: const InputDecoration(
                    labelText: 'Project path',
                    hintText: '/Users/you/projects/my_app',
                    helperText: 'Used for Flutter, Git and quick actions',
                  ),
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
                _buildIdeDropdown(),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _appsController,
                  decoration: const InputDecoration(
                    labelText: 'More apps to open',
                    hintText: 'Terminal, Docker, Simulator',
                    helperText: 'Comma-separated app names',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Flutter run on launch'),
                  subtitle: const Text('Uses this workspace project path'),
                  value: _runFlutterOnLaunch,
                  onChanged: (value) =>
                      setState(() => _runFlutterOnLaunch = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Git pull on launch'),
                  subtitle: const Text('Uses this workspace project path'),
                  value: _gitPullOnLaunch,
                  onChanged: (value) =>
                      setState(() => _gitPullOnLaunch = value),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _shellController,
                  decoration: const InputDecoration(
                    labelText: 'Extra shell command (optional)',
                    hintText: 'docker compose up -d',
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
