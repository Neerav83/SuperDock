import 'package:flutter/material.dart';

import 'package:superdock_ui/core/theme/tokens.dart';
import 'package:superdock_ui/pages/dashboard/dashboard_providers.dart';
import 'package:superdock_ui/pages/dashboard/dashboard_widgets.dart';
import 'package:superdock_ui/widgets/widgets.dart';

class DashboardWorkspacesView extends StatelessWidget {
  const DashboardWorkspacesView({
    super.key,
    required this.state,
    required this.interactions,
    required this.terminalScrollController,
  });

  final DashboardState state;
  final DashboardInteractions interactions;
  final ScrollController terminalScrollController;

  @override
  Widget build(BuildContext context) {
    final compact = Responsive.isCompactWidth(MediaQuery.sizeOf(context).width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(icon: Icons.grid_view, title: 'Workspaces'),
        const SizedBox(height: AppSpacing.lg),
        compact
            ? DashboardWorkspacesSection(
                state: state,
                interactions: interactions,
                includeNewCard: true,
                horizontal: true,
              )
            : Expanded(
                child: DashboardWorkspacesSection(
                  state: state,
                  interactions: interactions,
                  includeNewCard: true,
                ),
              ),
        const SizedBox(height: AppSpacing.xxl),
        Expanded(
          child: DashboardTerminalPanel(
            lines: state.terminal?.lines ?? ['No terminal output yet'],
            isLive: state.terminal?.live ?? false,
            backendConnected: state.backendConnected,
            scrollController: terminalScrollController,
          ),
        ),
      ],
    );
  }
}
