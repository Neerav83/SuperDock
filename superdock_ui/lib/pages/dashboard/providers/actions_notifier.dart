import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superdock_ui/core/models/models.dart';
import 'package:superdock_ui/core/services/services.dart';
import 'package:superdock_ui/pages/dashboard/providers/api_provider.dart';
import 'package:superdock_ui/pages/dashboard/providers/backend_notifier.dart';
import 'package:superdock_ui/pages/dashboard/state/actions_state.dart';
import 'package:superdock_ui/pages/dashboard/utils/dashboard_messages.dart';
import 'package:superdock_ui/pages/dashboard/utils/flutter_device_helper.dart';
import 'package:superdock_ui/widgets/widgets.dart';

final dashboardActionsProvider =
    NotifierProvider<DashboardActionsNotifier, ActionsState>(
  DashboardActionsNotifier.new,
);

class DashboardActionsNotifier extends Notifier<ActionsState> {
  SuperDockApi get _api => ref.read(superDockApiProvider);

  @override
  ActionsState build() => const ActionsState();

  Future<void> load() async {
    try {
      final actions = await _api.getActions();
      if (!ref.mounted) return;
      state = state.copyWith(dockActions: actions);
    } catch (error) {
      rethrow;
    }
  }

  Future<void> loadWithFeedback(BuildContext context) async {
    try {
      await load();
    } catch (error) {
      showDashboardError(context, 'Could not load actions: $error');
    }
  }

  Future<void> handleDockAction(BuildContext context, DockAction action) async {
    if (state.loadingActionId != null) return;

    state = state.copyWith(loadingActionId: action.id);
    try {
      final device = actionNeedsFlutterDevice(action)
          ? await resolveFlutterDevice(context, _api)
          : null;
      if (actionNeedsFlutterDevice(action) && device == null) return;

      if (device != null) {
        showDashboardInfo(context, 'Startar flutter run på ${device.name}…');
      }

      await _api.runDockAction(action.id, deviceId: device?.id);
    } on MultipleFlutterDevicesException catch (error) {
      final device = await pickFlutterDevice(context, _api, error.devices);
      if (device == null) return;
      showDashboardInfo(context, 'Startar flutter run på ${device.name}…');
      await _api.runDockAction(action.id, deviceId: device.id);
    } catch (error) {
      showDashboardError(context, formatDashboardError(error));
    } finally {
      if (ref.mounted) state = state.copyWith(loadingActionId: null);
      await ref.read(dashboardBackendProvider.notifier).refresh();
    }
  }

  Future<void> openCreateAction(BuildContext context) async {
    final result = await showSuperDockDialog<Object?>(
      context: context,
      builder: (context) => const ActionDialog(),
    );

    if (result is! ActionFormData || !context.mounted) return;

    try {
      await _api.createAction(result.toPayload());
      await loadWithFeedback(context);
      showDashboardInfo(context, 'Action created.');
    } catch (error) {
      showDashboardError(context, formatDashboardError(error));
    }
  }

  Future<void> openEditAction(BuildContext context, DockAction action) async {
    final isDefault = _isDefaultAction(action.id);
    final json = action.toJson();
    final type = json['type'] as String? ?? 'open_app';

    final result = await showSuperDockDialog<Object?>(
      context: context,
      builder: (context) => ActionDialog(
        isEdit: true,
        isDefaultAction: isDefault,
        actionId: action.id,
        initialTitle: action.title,
        initialStatus: action.status,
        initialIconKey: json['icon'] as String? ?? 'extension',
        initialColorHex: json['accentColor'] as String? ?? '#3B82F6',
        initialType: type,
        initialAppName: action.appName ?? '',
        initialCmd: action.shellCommand ?? '',
        initialUsesFlutterProject: action.usesFlutterProject,
        initialUsesGitProject: action.usesGitProject,
      ),
    );

    if (!context.mounted || result == null) return;

    if (result == 'delete') {
      if (isDefault) {
        showDashboardError(context, 'Cannot delete default actions.');
        return;
      }
      try {
        await _api.deleteAction(action.id);
        await loadWithFeedback(context);
        showDashboardInfo(context, 'Action deleted.');
      } catch (error) {
        showDashboardError(context, formatDashboardError(error));
      }
      return;
    }

    if (result is! ActionFormData) return;

    if (isDefault) {
      showDashboardError(context, 'Cannot modify default actions.');
      return;
    }

    try {
      await _api.updateAction(action.id, result.toPayload());
      await loadWithFeedback(context);
      showDashboardInfo(context, 'Action updated.');
    } catch (error) {
      showDashboardError(context, formatDashboardError(error));
    }
  }

  bool _isDefaultAction(String id) {
    const defaultIds = [
      'vscode',
      'cursor',
      'docker',
      'figma',
      'terminal',
      'flutter-run',
      'git-pull',
      'simulator',
      'xcode',
      'safari',
    ];
    return defaultIds.contains(id);
  }
}
