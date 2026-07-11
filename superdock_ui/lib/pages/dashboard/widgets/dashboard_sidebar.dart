import 'package:flutter/material.dart';
import 'package:superdock_ui/core/models/models.dart';
import 'package:superdock_ui/core/theme/tokens.dart';
import 'package:superdock_ui/pages/dashboard/widgets/processes_panel.dart';
import 'package:superdock_ui/pages/dashboard/widgets/shortcuts_panel.dart';
import 'package:superdock_ui/widgets/widgets.dart';

class DashboardSidebar extends StatelessWidget {
  const DashboardSidebar({
    super.key,
    required this.systemStats,
    required this.processes,
    required this.workspaces,
    required this.onViewAllProcesses,
  });

  final SystemStats? systemStats;
  final List<ProcessInfo> processes;
  final List<Workspace> workspaces;
  final VoidCallback onViewAllProcesses;

  @override
  Widget build(BuildContext context) {
    final stats = systemStats;

    return Column(
      children: [
        StatusCard(
          cpu: stats?.cpu ?? 0,
          memory: stats?.memory ?? 0,
          disk: stats?.disk ?? 0,
          uptime: stats?.uptime ?? '—',
          cpuHistory: stats?.sparklines.cpu ?? [],
          memoryHistory: stats?.sparklines.memory ?? [],
          diskHistory: stats?.sparklines.disk ?? [],
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: DashboardProcessesPanel(
            processes: processes,
            onViewAll: onViewAllProcesses,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        DashboardShortcutsPanel(workspaces: workspaces),
      ],
    );
  }
}
