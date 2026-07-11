import 'package:flutter/material.dart';
import 'package:superdock_ui/core/models/models.dart';
import 'package:superdock_ui/core/services/services.dart';
import 'package:superdock_ui/pages/dashboard/utils/dashboard_messages.dart';
import 'package:superdock_ui/widgets/widgets.dart';

Future<String?> resolveGitProjectPath(
  SuperDockApi api, {
  String? projectPath,
}) async {
  final trimmed = projectPath?.trim();
  if (trimmed != null && trimmed.isNotEmpty) return trimmed;

  try {
    final config = await api.getConfig();
    final gitPath = config['gitProjectPath'] as String?;
    if (gitPath != null && gitPath.trim().isNotEmpty) return gitPath.trim();
    final flutterPath = config['flutterProjectPath'] as String?;
    if (flutterPath != null && flutterPath.trim().isNotEmpty) {
      return flutterPath.trim();
    }
  } catch (_) {}

  return null;
}

String buildGitAddCommand(List<String> paths) {
  if (paths.isEmpty) return '';
  final escaped = paths
      .map((path) => "'${path.replaceAll("'", "'\\''")}'")
      .join(' ');
  return 'git add -- $escaped';
}

String buildGitCommitCommand(String message) {
  final escaped = message.replaceAll("'", "'\\''");
  return "git commit -m '$escaped'";
}

bool commandNeedsInteractiveGit(String cmd) {
  return WorkspaceActionRules.isGitAddCommand(cmd) ||
      WorkspaceActionRules.isGitCommitCommand(cmd);
}

Future<String?> resolveInteractiveGitCommand(
  BuildContext context,
  SuperDockApi api, {
  required String cmd,
  String? projectPath,
}) async {
  if (WorkspaceActionRules.isGitAddCommand(cmd)) {
    return resolveGitAddCommand(context, api, projectPath: projectPath);
  }
  if (WorkspaceActionRules.isGitCommitCommand(cmd)) {
    return resolveGitCommitCommand(context, api, projectPath: projectPath);
  }
  return cmd;
}

Future<String?> resolveGitAddCommand(
  BuildContext context,
  SuperDockApi api, {
  String? projectPath,
}) async {
  try {
    final cwd = await resolveGitProjectPath(api, projectPath: projectPath);
    if (cwd == null) {
      if (!context.mounted) return null;
      showDashboardError(
        context,
        'Ingen git project path är konfigurerad för detta workspace.',
      );
      return null;
    }

    final response = await api.getGitChanges(projectPath: cwd);
    if (!context.mounted) return null;
    final selected = await showSuperDockDialog<List<String>>(
      context: context,
      builder: (context) => GitAddDialog(files: response.files),
    );

    if (selected == null || selected.isEmpty) return null;
    return buildGitAddCommand(selected);
  } catch (error) {
    if (!context.mounted) return null;
    showDashboardError(context, formatDashboardError(error));
    return null;
  }
}

Future<String?> resolveGitCommitCommand(
  BuildContext context,
  SuperDockApi api, {
  String? projectPath,
}) async {
  final cwd = await resolveGitProjectPath(api, projectPath: projectPath);
  if (cwd == null) {
    if (!context.mounted) return null;
    showDashboardError(
      context,
      'Ingen git project path är konfigurerad för detta workspace.',
    );
    return null;
  }

  if (!context.mounted) return null;
  final message = await showSuperDockDialog<String>(
    context: context,
    builder: (context) => const GitCommitDialog(),
  );

  if (message == null || message.trim().isEmpty) return null;
  return buildGitCommitCommand(message.trim());
}
