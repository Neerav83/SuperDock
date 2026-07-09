import 'package:flutter/foundation.dart';

import 'package:superdock_ui/core/models/models.dart';

@immutable
class WorkspacesState {
  const WorkspacesState({
    this.workspaces = const [],
    this.activeWorkspaceId,
    this.loadingWorkspaceId,
    this.loadingWorkspaceActionKey,
  });

  final List<Workspace> workspaces;
  final String? activeWorkspaceId;
  final String? loadingWorkspaceId;
  final String? loadingWorkspaceActionKey;

  Workspace? get activeWorkspace {
    final id = activeWorkspaceId;
    if (id == null) return null;
    for (final workspace in workspaces) {
      if (workspace.id == id) return workspace;
    }
    return null;
  }

  List<WorkspaceQuickAction> get workspaceQuickActions {
    final workspace = activeWorkspace;
    if (workspace == null) return const [];
    return WorkspaceActionMapper.fromWorkspace(workspace);
  }

  bool get showWorkspaceQuickActions => workspaceQuickActions.isNotEmpty;

  String get quickActionsTitle {
    final workspace = activeWorkspace;
    if (workspace != null) return '${workspace.name} Actions';
    return 'Quick Actions';
  }

  static const _unset = Object();

  WorkspacesState copyWith({
    List<Workspace>? workspaces,
    Object? activeWorkspaceId = _unset,
    Object? loadingWorkspaceId = _unset,
    Object? loadingWorkspaceActionKey = _unset,
  }) {
    return WorkspacesState(
      workspaces: workspaces ?? this.workspaces,
      activeWorkspaceId: activeWorkspaceId == _unset
          ? this.activeWorkspaceId
          : activeWorkspaceId as String?,
      loadingWorkspaceId: loadingWorkspaceId == _unset
          ? this.loadingWorkspaceId
          : loadingWorkspaceId as String?,
      loadingWorkspaceActionKey: loadingWorkspaceActionKey == _unset
          ? this.loadingWorkspaceActionKey
          : loadingWorkspaceActionKey as String?,
    );
  }
}
