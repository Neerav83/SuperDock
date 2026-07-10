import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superdock_ui/core/models/models.dart';
import 'package:superdock_ui/core/services/services.dart';
import 'package:superdock_ui/pages/dashboard/providers/actions_notifier.dart';
import 'package:superdock_ui/pages/dashboard/providers/api_provider.dart';
import 'package:superdock_ui/pages/dashboard/providers/settings_notifier.dart';
import 'package:superdock_ui/pages/dashboard/providers/workspaces_notifier.dart';
import 'package:superdock_ui/pages/dashboard/state/backend_state.dart';
import 'package:superdock_ui/pages/dashboard/dashboard_widgets.dart';

final dashboardBackendProvider =
    NotifierProvider<DashboardBackendNotifier, BackendState>(
  DashboardBackendNotifier.new,
);

class DashboardBackendNotifier extends Notifier<BackendState> {
  Timer? _pollTimer;
  StreamSubscription<TerminalOutput>? _terminalSubscription;
  TerminalStreamService? _terminalStream;

  SuperDockApi get _api => ref.read(superDockApiProvider);

  @override
  BackendState build() {
    ref.onDispose(() {
      _pollTimer?.cancel();
      _terminalSubscription?.cancel();
      _terminalStream?.dispose();
    });

    Future.microtask(_initialize);
    return const BackendState();
  }

  Future<void> _initialize() async {
    final settings = await ref.read(dashboardSettingsProvider.notifier).ensureLoaded();
    if (!ref.mounted) return;

    if (settings.autoStartBackend) {
      await BackendLauncher.ensureRunning(
        baseUrl: settings.backendUrl,
        corePath: settings.backendCorePath,
      );
    }

    await _connectTerminalStream();
    await syncBackendConfig();
    await ref.read(dashboardWorkspacesProvider.notifier).load();
    await ref.read(dashboardActionsProvider.notifier).load();
    await refresh();

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => refresh());
  }

  Future<void> _connectTerminalStream() async {
    await _terminalSubscription?.cancel();
    _terminalSubscription = null;
    _terminalStream?.dispose();
    _terminalStream = TerminalStreamService(_api);

    if (!await _api.isReachable()) {
      if (ref.mounted) {
        state = state.copyWith(terminalStreamConnected: false);
      }
      return;
    }

    try {
      await _terminalStream!.connect();
      _terminalSubscription = _terminalStream!.stream.listen(
        (output) {
          if (!ref.mounted) return;
          state = state.copyWith(
            terminal: output,
            terminalStreamConnected: true,
          );
        },
        onError: (_) {
          if (!ref.mounted) return;
          state = state.copyWith(terminalStreamConnected: false);
        },
      );
      if (ref.mounted) {
        state = state.copyWith(terminalStreamConnected: true);
      }
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(terminalStreamConnected: false);
      }
    }
  }

  Future<void> syncBackendConfig() async {
    final settings = ref.read(dashboardSettingsProvider);
    final payload = <String, dynamic>{};
    final flutterPath = settings.flutterProjectPath;
    final gitPath = settings.gitProjectPath;

    if (flutterPath != null && flutterPath.isNotEmpty) {
      payload['flutterProjectPath'] = flutterPath;
    }
    if (gitPath != null && gitPath.isNotEmpty) {
      payload['gitProjectPath'] = gitPath;
    }
    if (payload.isEmpty) return;

    try {
      await _api.updateConfig(payload);
    } catch (_) {
      // Backend may be offline during startup.
    }
  }

  Future<void> refresh() async {
    var statusOk = false;

    try {
      final status = await _api.getStatus();
      statusOk = true;
      if (ref.mounted) state = state.copyWith(status: status);
    } catch (_) {}

    final refreshTasks = <Future<void>>[
      _api.getSystemStats().then((stats) {
        if (ref.mounted) state = state.copyWith(systemStats: stats);
      }),
      _api.getProcesses().then((processes) {
        if (ref.mounted) state = state.copyWith(processes: processes);
      }),
      _api.getHistory().then((history) {
        if (ref.mounted) state = state.copyWith(history: history);
      }),
    ];

    if (!state.terminalStreamConnected) {
      refreshTasks.add(
        _api.getTerminal().then((terminal) {
          if (ref.mounted) state = state.copyWith(terminal: terminal);
        }),
      );
    }

    await Future.wait(
      refreshTasks.map((task) => task.catchError((_) {})),
    );

    if (ref.mounted) {
      state = state.copyWith(backendConnected: statusOk);
    }
  }

  Future<void> reconnectAfterSettingsChange() async {
    final settings = ref.read(dashboardSettingsProvider);
    if (settings.autoStartBackend) {
      await BackendLauncher.ensureRunning(
        baseUrl: settings.backendUrl,
        corePath: settings.backendCorePath,
      );
    }
    await syncBackendConfig();
    await _connectTerminalStream();
    await refresh();
  }

  bool isAppActive(String? appName) {
    if (appName == null) return false;
    return state.processes.any((process) => process.name == appName);
  }

  Future<void> showAllProcesses(BuildContext context) {
    return showAllProcessesDialog(
      context: context,
      api: _api,
      fallbackProcesses: state.processes,
    );
  }
}
