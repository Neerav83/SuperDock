import 'package:flutter/foundation.dart';

import 'package:superdock_ui/core/models/models.dart';

class DashboardInteractions {
  const DashboardInteractions({
    required this.setSelectedNav,
    required this.openSettings,
    required this.showAllProcesses,
    required this.isAppActive,
    required this.handleDockAction,
    required this.openEditAction,
    required this.openCreateAction,
    required this.handleWorkspaceQuickAction,
    required this.openEditWorkspaceAction,
    required this.openAddWorkspaceCommand,
    required this.openEditWorkspace,
    required this.activateWorkspace,
    required this.handleWorkspaceLaunch,
    required this.openCreateWorkspace,
  });

  final ValueChanged<int> setSelectedNav;
  final VoidCallback openSettings;
  final VoidCallback showAllProcesses;
  final bool Function(String? appName) isAppActive;
  final void Function(DockAction action) handleDockAction;
  final void Function(DockAction action) openEditAction;
  final VoidCallback openCreateAction;
  final void Function(WorkspaceQuickAction action) handleWorkspaceQuickAction;
  final void Function(WorkspaceQuickAction action) openEditWorkspaceAction;
  final VoidCallback openAddWorkspaceCommand;
  final void Function(Workspace workspace) openEditWorkspace;
  final void Function(Workspace workspace) activateWorkspace;
  final void Function(Workspace workspace) handleWorkspaceLaunch;
  final VoidCallback openCreateWorkspace;
}
