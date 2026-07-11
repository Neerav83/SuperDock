import 'package:flutter/foundation.dart';

import 'package:superdock_ui/core/models/models.dart';

@immutable
class BackendState {
  const BackendState({
    this.terminalStreamConnected = false,
    this.status,
    this.systemStats,
    this.processes = const [],
    this.history = const [],
    this.terminal,
    this.backendConnected = false,
  });

  final bool terminalStreamConnected;
  final ConnectionStatus? status;
  final SystemStats? systemStats;
  final List<ProcessInfo> processes;
  final List<ActionHistoryEntry> history;
  final TerminalOutput? terminal;
  final bool backendConnected;

  static const _unset = Object();

  BackendState copyWith({
    bool? terminalStreamConnected,
    Object? status = _unset,
    Object? systemStats = _unset,
    List<ProcessInfo>? processes,
    List<ActionHistoryEntry>? history,
    Object? terminal = _unset,
    bool? backendConnected,
  }) {
    return BackendState(
      terminalStreamConnected:
          terminalStreamConnected ?? this.terminalStreamConnected,
      status: status == _unset ? this.status : status as ConnectionStatus?,
      systemStats:
          systemStats == _unset ? this.systemStats : systemStats as SystemStats?,
      processes: processes ?? this.processes,
      history: history ?? this.history,
      terminal: terminal == _unset ? this.terminal : terminal as TerminalOutput?,
      backendConnected: backendConnected ?? this.backendConnected,
    );
  }
}
