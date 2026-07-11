import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:superdock_ui/core/models/models.dart';
import 'package:superdock_ui/core/services/services.dart';
import 'package:superdock_ui/pages/dashboard/providers/actions_notifier.dart';
import 'package:superdock_ui/pages/dashboard/providers/backend_notifier.dart';
import 'package:superdock_ui/pages/dashboard/providers/nav_notifier.dart';
import 'package:superdock_ui/pages/dashboard/providers/settings_notifier.dart';
import 'package:superdock_ui/pages/dashboard/providers/workspaces_notifier.dart';
import 'package:superdock_ui/pages/dashboard/state/actions_state.dart';
import 'package:superdock_ui/pages/dashboard/state/backend_state.dart';
import 'package:superdock_ui/pages/dashboard/state/workspaces_state.dart';

export 'package:superdock_ui/pages/dashboard/providers/actions_notifier.dart';
export 'package:superdock_ui/pages/dashboard/providers/api_provider.dart';
export 'package:superdock_ui/pages/dashboard/providers/backend_notifier.dart';
export 'package:superdock_ui/pages/dashboard/providers/dashboard_controller.dart';
export 'package:superdock_ui/pages/dashboard/providers/nav_notifier.dart';
export 'package:superdock_ui/pages/dashboard/providers/settings_notifier.dart';
export 'package:superdock_ui/pages/dashboard/providers/workspaces_notifier.dart';
export 'package:superdock_ui/pages/dashboard/state/actions_state.dart';
export 'package:superdock_ui/pages/dashboard/state/backend_state.dart';
export 'package:superdock_ui/pages/dashboard/state/workspaces_state.dart';

@immutable
class DashboardState {
  const DashboardState({
    required this.settings,
    required this.selectedNav,
    required this.backend,
    required this.workspacesState,
    required this.actionsState,
  });

  final AppSettings settings;
  final int selectedNav;
  final BackendState backend;
  final WorkspacesState workspacesState;
  final ActionsState actionsState;

  bool get terminalStreamConnected => backend.terminalStreamConnected;
  ConnectionStatus? get status => backend.status;
  SystemStats? get systemStats => backend.systemStats;
  List<ProcessInfo> get processes => backend.processes;
  List<ActionHistoryEntry> get history => backend.history;
  TerminalOutput? get terminal => backend.terminal;
  bool get backendConnected => backend.backendConnected;

  List<Workspace> get workspaces => workspacesState.workspaces;
  String? get activeWorkspaceId => workspacesState.activeWorkspaceId;
  String? get loadingWorkspaceId => workspacesState.loadingWorkspaceId;
  String? get loadingWorkspaceActionKey =>
      workspacesState.loadingWorkspaceActionKey;
  Workspace? get activeWorkspace => workspacesState.activeWorkspace;
  List<WorkspaceQuickAction> get workspaceQuickActions =>
      workspacesState.workspaceQuickActions;
  bool get showWorkspaceQuickActions => workspacesState.showWorkspaceQuickActions;
  String get quickActionsTitle => workspacesState.quickActionsTitle;

  List<DockAction> get dockActions => actionsState.dockActions;
  String? get loadingActionId => actionsState.loadingActionId;
}

final dashboardViewProvider = Provider<DashboardState>((ref) {
  return DashboardState(
    settings: ref.watch(dashboardSettingsProvider),
    selectedNav: ref.watch(dashboardNavProvider),
    backend: ref.watch(dashboardBackendProvider),
    workspacesState: ref.watch(dashboardWorkspacesProvider),
    actionsState: ref.watch(dashboardActionsProvider),
  );
});
