import 'package:flutter/foundation.dart';

import 'package:superdock_ui/core/models/models.dart';

@immutable
class ActionsState {
  const ActionsState({
    this.dockActions = const [],
    this.loadingActionId,
  });

  final List<DockAction> dockActions;
  final String? loadingActionId;

  static const _unset = Object();

  ActionsState copyWith({
    List<DockAction>? dockActions,
    Object? loadingActionId = _unset,
  }) {
    return ActionsState(
      dockActions: dockActions ?? this.dockActions,
      loadingActionId: loadingActionId == _unset
          ? this.loadingActionId
          : loadingActionId as String?,
    );
  }
}
