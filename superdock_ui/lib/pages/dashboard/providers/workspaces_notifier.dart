import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superdock_ui/core/models/models.dart';
import 'package:superdock_ui/core/services/services.dart';
import 'package:superdock_ui/pages/dashboard/providers/api_provider.dart';
import 'package:superdock_ui/pages/dashboard/providers/backend_notifier.dart';
import 'package:superdock_ui/pages/dashboard/providers/settings_notifier.dart';
import 'package:superdock_ui/pages/dashboard/state/workspaces_state.dart';
import 'package:superdock_ui/pages/dashboard/utils/dashboard_messages.dart';
import 'package:superdock_ui/pages/dashboard/utils/flutter_device_helper.dart';
import 'package:superdock_ui/pages/dashboard/utils/git_action_helper.dart';
import 'package:superdock_ui/widgets/widgets.dart';

final dashboardWorkspacesProvider =
    NotifierProvider<DashboardWorkspacesNotifier, WorkspacesState>(
  DashboardWorkspacesNotifier.new,
);

class DashboardWorkspacesNotifier extends Notifier<WorkspacesState> {
  SuperDockApi get _api => ref.read(superDockApiProvider);

  @override
  WorkspacesState build() => const WorkspacesState();

  Future<void> load() async {
    try {
      final workspaces = await _api.getWorkspaces();
      if (!ref.mounted) return;

      var activeWorkspaceId = ref.read(dashboardSettingsProvider).activeWorkspaceId;
      if (activeWorkspaceId != null &&
          !workspaces.any((workspace) => workspace.id == activeWorkspaceId)) {
        activeWorkspaceId = null;
      }

      state = state.copyWith(
        workspaces: workspaces,
        activeWorkspaceId: activeWorkspaceId,
      );
    } catch (error) {
      rethrow;
    }
  }

  Future<void> loadWithFeedback(BuildContext context) async {
    try {
      await load();
    } catch (error) {
      showDashboardError(context, 'Could not load workspaces: $error');
    }
  }

  Future<void> _syncActiveWorkspaceSettings(Workspace workspace) async {
    final projectPath = workspace.projectPath?.trim();
    final saved = await ref.read(dashboardSettingsProvider.notifier).save(
          ref.read(dashboardSettingsProvider).copyWith(
                activeWorkspaceId: workspace.id,
                flutterProjectPath:
                    projectPath?.isNotEmpty == true ? projectPath : null,
                gitProjectPath:
                    projectPath?.isNotEmpty == true ? projectPath : null,
                clearFlutterProjectPath:
                    projectPath == null || projectPath.isEmpty,
                clearGitProjectPath: projectPath == null || projectPath.isEmpty,
              ),
        );
    if (!ref.mounted) return;
    state = state.copyWith(activeWorkspaceId: saved.activeWorkspaceId);
  }

  Future<void> _applyWorkspaceContext(Workspace workspace) async {
    try {
      await _api.activateWorkspace(workspace.id);
    } catch (_) {
      final projectPath = workspace.projectPath?.trim();
      if (projectPath != null && projectPath.isNotEmpty) {
        await _api.updateConfig({
          'flutterProjectPath': projectPath,
          'gitProjectPath': projectPath,
        });
      }
    }
    await _syncActiveWorkspaceSettings(workspace);
  }

  Future<void> activateWorkspace(BuildContext context, Workspace workspace) async {
    if (state.activeWorkspaceId == workspace.id) {
      await deactivateWorkspace(context);
      return;
    }

    try {
      await _applyWorkspaceContext(workspace);
      showDashboardInfo(context, 'Aktiverade ${workspace.name}');
    } catch (error) {
      showDashboardError(context, formatDashboardError(error));
    }
  }

  Future<void> deactivateWorkspace(BuildContext context) async {
    await ref.read(dashboardSettingsProvider.notifier).save(
          ref.read(dashboardSettingsProvider).copyWith(clearActiveWorkspaceId: true),
        );
    if (!ref.mounted) return;
    state = state.copyWith(activeWorkspaceId: null);
    showDashboardInfo(context, 'Visar globala quick actions igen');
  }

  Future<void> handleWorkspaceQuickAction(
    BuildContext context,
    WorkspaceQuickAction action,
  ) async {
    final loadingKey = '${action.workspace.id}:${action.actionIndex}';
    if (state.loadingWorkspaceActionKey != null) return;

    state = state.copyWith(loadingWorkspaceActionKey: loadingKey);
    try {
      await _applyWorkspaceContext(action.workspace);
      final projectPath = action.workspace.projectPath?.trim();

      if (action.appName != null) {
        await _api.openApp(action.appName!, path: projectPath);
        return;
      }

      final cmd = action.shellCommand?.trim() ?? '';
      if (cmd.isEmpty) return;

      final usesGit = WorkspaceActionRules.usesGitProject(action.rawAction);
      if (WorkspaceActionRules.isFlutterRun(action.rawAction)) {
        final device = await resolveFlutterDevice(context, _api);
        if (device == null) return;
        showDashboardInfo(context, 'Startar flutter run på ${device.name}…');
        await _api.runShell(
          'flutter run -d ${device.id}',
          cwd: projectPath,
        );
        return;
      }

      if (commandNeedsInteractiveGit(cmd)) {
        final resolved = await resolveInteractiveGitCommand(
          context,
          _api,
          cmd: cmd,
          projectPath: projectPath,
        );
        if (resolved == null) return;
        final cwd = projectPath ?? await resolveGitProjectPath(_api);
        await _api.runShell(resolved, cwd: cwd);
        return;
      }

      await _api.runShell(
        cmd,
        cwd: usesGit || action.usesFlutterProject ? projectPath : null,
      );
    } catch (error) {
      showDashboardError(context, formatDashboardError(error));
    } finally {
      if (ref.mounted) state = state.copyWith(loadingWorkspaceActionKey: null);
      await ref.read(dashboardBackendProvider.notifier).refresh();
    }
  }

  Future<void> handleWorkspaceLaunch(
    BuildContext context,
    Workspace workspace,
  ) async {
    if (state.loadingWorkspaceId != null) return;

    state = state.copyWith(loadingWorkspaceId: workspace.id);
    try {
      final device = workspaceNeedsFlutterDevice(workspace)
          ? await resolveFlutterDevice(context, _api)
          : null;
      if (workspaceNeedsFlutterDevice(workspace) && device == null) return;

      if (device != null) {
        showDashboardInfo(context, 'Startar flutter run på ${device.name}…');
      }

      await _api.launchWorkspace(workspace.id, deviceId: device?.id);
      await _applyWorkspaceContext(workspace);
    } on MultipleFlutterDevicesException catch (error) {
      final device = await pickFlutterDevice(context, _api, error.devices);
      if (device == null) return;
      showDashboardInfo(context, 'Startar flutter run på ${device.name}…');
      await _api.launchWorkspace(workspace.id, deviceId: device.id);
      await _applyWorkspaceContext(workspace);
    } catch (error) {
      showDashboardError(context, formatDashboardError(error));
    } finally {
      if (ref.mounted) state = state.copyWith(loadingWorkspaceId: null);
      await ref.read(dashboardBackendProvider.notifier).refresh();
    }
  }

  void launchWorkspaceByIndex(BuildContext context, int index) {
    if (index < 0 || index >= state.workspaces.length) return;
    handleWorkspaceLaunch(context, state.workspaces[index]);
  }

  Future<void> openAddWorkspaceCommand(BuildContext context) async {
    final workspace = state.activeWorkspace;
    if (workspace == null) return;

    final result = await showSuperDockDialog<WorkspaceCommandFormData>(
      context: context,
      builder: (context) => const AddWorkspaceCommandDialog(),
    );

    if (result == null || !context.mounted) return;

    final action = <String, dynamic>{
      'type': 'shell',
      'cmd': result.command,
    };
    final cmd = result.command.trim();
    if (WorkspaceActionRules.isFlutterRun(action) || cmd.startsWith('flutter ')) {
      action['usesFlutterProject'] = true;
    } else if (result.usesGitProject || cmd.startsWith('git ')) {
      action['usesGitProject'] = true;
    }

    try {
      await _api.updateWorkspace(workspace.id, {
        ...workspace.toJson(),
        'projectPath': workspace.projectPath,
        'actions': [...workspace.actions, action],
      });
      await loadWithFeedback(context);
      showDashboardInfo(context, 'Kommando tillagt i ${workspace.name}');
    } catch (error) {
      showDashboardError(context, formatDashboardError(error));
    }
  }

  Future<void> openCreateWorkspace(BuildContext context) async {
    final result = await showSuperDockDialog<Object?>(
      context: context,
      builder: (context) => const WorkspaceDialog(),
    );

    if (result is! WorkspaceFormData || !context.mounted) return;

    try {
      final updated = await _api.createWorkspace(result.toPayload());
      if (result.projectPath.trim().isNotEmpty &&
          (updated.projectPath == null || updated.projectPath!.isEmpty)) {
        showDashboardError(
          context,
          'Project path was not saved. Restart SuperDock and try again.',
        );
        return;
      }
      await loadWithFeedback(context);
      showDashboardInfo(context, 'Workspace created.');
    } catch (error) {
      showDashboardError(context, formatDashboardError(error));
    }
  }

  Future<void> openEditWorkspace(BuildContext context, Workspace workspace) async {
    final form = WorkspaceFormData.fromWorkspace(
      name: workspace.name,
      description: workspace.description,
      shortcut: workspace.shortcut ?? '',
      iconKey: workspace.toJson()['icon'] as String? ?? 'grid_view',
      colorHex: workspace.accentColorHex,
      projectPath: workspace.projectPath,
      imageUrl: workspace.imageUrl,
      actions: workspace.actions,
    );

    final result = await showSuperDockDialog<Object?>(
      context: context,
      builder: (context) => WorkspaceDialog(
        isEdit: true,
        workspaceId: workspace.id,
        initialName: form.name,
        initialDescription: form.description,
        initialShortcut: form.shortcut,
        initialIconKey: form.iconKey,
        initialColorHex: form.colorHex,
        initialProjectPath: workspace.projectPath ?? '',
        initialImageUrl: workspace.imageUrl ?? '',
        initialIdeApp: form.ideApp,
        initialApps: form.apps,
        initialShellCommand: form.shellCommand ?? '',
        initialRunFlutterOnLaunch: form.runFlutterOnLaunch,
        initialGitPullOnLaunch: form.gitPullOnLaunch,
      ),
    );

    if (!context.mounted || result == null) return;

    if (result == 'delete') {
      try {
        await _api.deleteWorkspace(workspace.id);
        if (state.activeWorkspaceId == workspace.id) {
          await deactivateWorkspace(context);
        }
        await loadWithFeedback(context);
        showDashboardInfo(context, 'Workspace deleted.');
      } catch (error) {
        showDashboardError(context, formatDashboardError(error));
      }
      return;
    }

    if (result is! WorkspaceFormData) return;

    try {
      final updated = await _api.updateWorkspace(
        workspace.id,
        {
          ...workspace.toJson(),
          ...result.toPayload(),
        },
      );
      if (result.projectPath.trim().isNotEmpty &&
          (updated.projectPath == null || updated.projectPath!.isEmpty)) {
        showDashboardError(
          context,
          'Project path was not saved. Restart SuperDock and try again.',
        );
        return;
      }
      await loadWithFeedback(context);
      if (state.activeWorkspaceId == workspace.id) {
        await _api.activateWorkspace(workspace.id);
        final projectPath = result.projectPath.trim();
        if (projectPath.isNotEmpty) {
          await ref.read(dashboardSettingsProvider.notifier).save(
                ref.read(dashboardSettingsProvider).copyWith(
                      flutterProjectPath: projectPath,
                      gitProjectPath: projectPath,
                    ),
              );
        }
      }
      showDashboardInfo(context, 'Workspace updated.');
    } catch (error) {
      showDashboardError(context, formatDashboardError(error));
    }
  }
}
