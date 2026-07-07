import 'package:flutter/material.dart';

import 'workspace.dart';

class WorkspaceQuickAction {
  const WorkspaceQuickAction({
    required this.workspace,
    required this.actionIndex,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.status,
    required this.rawAction,
  });

  final Workspace workspace;
  final int actionIndex;
  final String title;
  final IconData icon;
  final Color accentColor;
  final String status;
  final Map<String, dynamic> rawAction;

  String? get appName {
    if (rawAction['type'] != 'open_app') return null;
    return rawAction['name'] as String? ?? rawAction['appName'] as String?;
  }

  bool get usesFlutterProject {
    return rawAction['usesFlutterProject'] == true ||
        rawAction['useFlutterProject'] == true;
  }

  bool get usesGitProject {
    return rawAction['usesGitProject'] == true ||
        rawAction['useGitProject'] == true;
  }

  String? get shellCommand {
    if (rawAction['type'] != 'shell') return null;
    return rawAction['cmd'] as String?;
  }
}

class WorkspaceActionMapper {
  static List<WorkspaceQuickAction> fromWorkspace(Workspace workspace) {
    final actions = <WorkspaceQuickAction>[];

    for (var i = 0; i < workspace.actions.length; i++) {
      final raw = workspace.actions[i];
      final type = raw['type'] as String?;
      if (type == 'open_app') {
        final appName = raw['name'] as String? ?? raw['appName'] as String? ?? 'App';
        final preset = _appPresets[appName];
        actions.add(
          WorkspaceQuickAction(
            workspace: workspace,
            actionIndex: i,
            title: _shortAppTitle(appName),
            icon: preset?.$1 ?? Icons.apps,
            accentColor: preset?.$2 ?? workspace.accentColor,
            status: preset?.$3 ?? 'Open',
            rawAction: raw,
          ),
        );
      } else if (type == 'shell') {
        final cmd = (raw['cmd'] as String? ?? '').trim();
        final preset = _shellPresets[cmd] ??
            (
              Icons.terminal,
              workspace.accentColor,
              'Run',
            );
        actions.add(
          WorkspaceQuickAction(
            workspace: workspace,
            actionIndex: i,
            title: _shellTitle(cmd),
            icon: preset.$1,
            accentColor: preset.$2,
            status: preset.$3,
            rawAction: raw,
          ),
        );
      }
    }

    return actions;
  }

  static String _shortAppTitle(String appName) {
    switch (appName) {
      case 'Visual Studio Code':
        return 'VS Code';
      default:
        return appName;
    }
  }

  static String _shellTitle(String cmd) {
    if (cmd.startsWith('flutter run')) return 'Flutter Run';
    if (cmd == 'git pull') return 'Git Pull';
    if (cmd == 'git push') return 'Git Push';
    if (cmd == 'git status') return 'Git Status';
    if (cmd == 'flutter pub get') return 'Pub Get';
    if (cmd.length > 18) return '${cmd.substring(0, 18)}…';
    return cmd.isEmpty ? 'Shell' : cmd;
  }
}

typedef _ActionPreset = (IconData, Color, String);

const _appPresets = <String, _ActionPreset>{
  'Visual Studio Code': (Icons.code, Color(0xFF3B82F6), 'Open'),
  'Cursor': (Icons.auto_awesome, Color(0xFFA855F7), 'Open'),
  'Docker': (Icons.dns, Color(0xFF22D3EE), 'Start'),
  'Figma': (Icons.design_services, Color(0xFFF97316), 'Open'),
  'Terminal': (Icons.terminal, Color(0xFF4ADE80), 'Open'),
  'Simulator': (Icons.phone_iphone, Color(0xFF3B82F6), 'Open'),
  'Xcode': (Icons.apple, Color(0xFF3B82F6), 'Open'),
  'Safari': (Icons.language, Color(0xFF22D3EE), 'Open'),
  'Preview': (Icons.visibility_outlined, Color(0xFFF97316), 'Open'),
};

const _shellPresets = <String, _ActionPreset>{
  'flutter run': (Icons.play_arrow, Color(0xFFA855F7), 'Run Project'),
  'git pull': (Icons.download, Color(0xFFF97316), 'Update'),
  'git push': (Icons.upload_rounded, Color(0xFFF97316), 'Push'),
  'git status': (Icons.fact_check_outlined, Color(0xFF22D3EE), 'Status'),
  'flutter pub get': (Icons.inventory_2_outlined, Color(0xFF4ADE80), 'Deps'),
};
