import 'package:flutter/material.dart';
import 'package:superdock_ui/core/models/models.dart';
import 'package:superdock_ui/core/services/services.dart';
import 'package:superdock_ui/pages/dashboard/utils/dashboard_messages.dart';
import 'package:superdock_ui/widgets/widgets.dart';

Future<FlutterDevice?> pickFlutterDevice(
  BuildContext context,
  SuperDockApi api,
  List<FlutterDevice> devices, {
  String? selectedDeviceId,
}) async {
  final pickedId = await showSuperDockDialog<String>(
    context: context,
    builder: (context) => FlutterDeviceDialog(
      devices: devices,
      selectedDeviceId: selectedDeviceId,
    ),
  );

  if (pickedId == null) return null;

  await api.updateConfig({'flutterDeviceId': pickedId});
  return devices.firstWhere((device) => device.id == pickedId);
}

Future<FlutterDevice?> resolveFlutterDevice(
  BuildContext context,
  SuperDockApi api,
) async {
  try {
    final response = await api.getFlutterDevices();
    final devices = response.devices;

    if (devices.isEmpty) {
      showDashboardError(
        context,
        'No Flutter devices found. Connect a device or start a simulator.',
      );
      return null;
    }

    return pickFlutterDevice(
      context,
      api,
      devices,
      selectedDeviceId: response.preferredDeviceId,
    );
  } catch (error) {
    showDashboardError(context, formatDashboardError(error));
    return null;
  }
}

bool workspaceNeedsFlutterDevice(Workspace workspace) {
  for (final action in workspace.actions) {
    final cmd = (action['cmd'] as String?)?.trim() ?? '';
    final usesFlutter = action['usesFlutterProject'] == true ||
        action['useFlutterProject'] == true;
    if (usesFlutter && cmd.startsWith('flutter run')) return true;
  }
  return false;
}

bool actionNeedsFlutterDevice(DockAction action) {
  final cmd = action.shellCommand?.trim() ?? '';
  return action.usesFlutterProject && cmd.startsWith('flutter run');
}
