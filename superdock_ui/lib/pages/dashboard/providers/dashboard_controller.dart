import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superdock_ui/core/models/models.dart';
import 'package:superdock_ui/core/services/services.dart';
import 'package:superdock_ui/pages/dashboard/providers/actions_notifier.dart';
import 'package:superdock_ui/pages/dashboard/providers/backend_notifier.dart';
import 'package:superdock_ui/pages/dashboard/providers/nav_notifier.dart';
import 'package:superdock_ui/pages/dashboard/providers/settings_notifier.dart';
import 'package:superdock_ui/pages/dashboard/providers/workspaces_notifier.dart';
import 'package:superdock_ui/pages/dashboard/utils/dashboard_messages.dart';
import 'package:superdock_ui/widgets/widgets.dart';

final dashboardControllerProvider = Provider<DashboardController>(
  DashboardController.new,
);

class DashboardController {
  DashboardController(this._ref);

  final Ref _ref;

  void setSelectedNav(int index) {
    _ref.read(dashboardNavProvider.notifier).setSelectedNav(index);
  }

  Future<void> handleDockAction(BuildContext context, DockAction action) {
    return _ref.read(dashboardActionsProvider.notifier).handleDockAction(
          context,
          action,
        );
  }

  Future<void> handleWorkspaceQuickAction(
    BuildContext context,
    WorkspaceQuickAction action,
  ) {
    return _ref
        .read(dashboardWorkspacesProvider.notifier)
        .handleWorkspaceQuickAction(context, action);
  }

  Future<void> activateWorkspace(BuildContext context, Workspace workspace) {
    return _ref
        .read(dashboardWorkspacesProvider.notifier)
        .activateWorkspace(context, workspace);
  }

  Future<void> handleWorkspaceLaunch(BuildContext context, Workspace workspace) {
    return _ref
        .read(dashboardWorkspacesProvider.notifier)
        .handleWorkspaceLaunch(context, workspace);
  }

  void launchWorkspaceByIndex(BuildContext context, int index) {
    _ref.read(dashboardWorkspacesProvider.notifier).launchWorkspaceByIndex(
          context,
          index,
        );
  }

  Future<void> openSettings(BuildContext context) async {
    final settings = _ref.read(dashboardSettingsProvider);
    final updated = await showSuperDockDialog<AppSettings>(
      context: context,
      builder: (context) => SettingsDialog(
        initialSettings: settings,
        onRestartBackend: ({required baseUrl, required corePath}) {
          return _ref.read(dashboardBackendProvider.notifier).restartBackend(
                baseUrl: baseUrl,
                corePath: corePath,
              );
        },
        savedBackendUrl: settings.backendUrl,
      ),
    );

    if (updated == null || !context.mounted) return;

    await _ref.read(dashboardSettingsProvider.notifier).save(updated);
    await _ref.read(dashboardBackendProvider.notifier).reconnectAfterSettingsChange();
    if (!context.mounted) return;
    await _ref.read(dashboardActionsProvider.notifier).loadWithFeedback(context);
    if (!context.mounted) return;
    await _ref.read(dashboardWorkspacesProvider.notifier).loadWithFeedback(context);
    if (!context.mounted) return;
    showDashboardInfo(context, 'Settings saved.');
  }

  Future<void> openAddWorkspaceCommand(BuildContext context) {
    return _ref
        .read(dashboardWorkspacesProvider.notifier)
        .openAddWorkspaceCommand(context);
  }

  Future<void> openEditWorkspaceAction(
    BuildContext context,
    WorkspaceQuickAction action,
  ) {
    return _ref
        .read(dashboardWorkspacesProvider.notifier)
        .openEditWorkspaceAction(context, action);
  }

  Future<void> openCreateWorkspace(BuildContext context) {
    return _ref.read(dashboardWorkspacesProvider.notifier).openCreateWorkspace(
          context,
        );
  }

  Future<void> openEditWorkspace(BuildContext context, Workspace workspace) {
    return _ref.read(dashboardWorkspacesProvider.notifier).openEditWorkspace(
          context,
          workspace,
        );
  }

  Future<void> openCreateAction(BuildContext context) {
    return _ref.read(dashboardActionsProvider.notifier).openCreateAction(context);
  }

  Future<void> openEditAction(BuildContext context, DockAction action) {
    return _ref.read(dashboardActionsProvider.notifier).openEditAction(
          context,
          action,
        );
  }

  bool isAppActive(String? appName) {
    return _ref.read(dashboardBackendProvider.notifier).isAppActive(appName);
  }

  Future<void> showAllProcesses(BuildContext context) {
    return _ref.read(dashboardBackendProvider.notifier).showAllProcesses(context);
  }
}
