import 'package:flutter/material.dart';

import 'package:superdock_ui/core/theme/tokens.dart';
import 'package:superdock_ui/pages/dashboard/dashboard_providers.dart';
import 'package:superdock_ui/pages/dashboard/dashboard_widgets.dart';
import 'package:superdock_ui/widgets/widgets.dart';

class DashboardHomeView extends StatelessWidget {
  const DashboardHomeView({
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final compact = Responsive.isCompactWidth(constraints.maxWidth);
        final useScroll = Responsive.useScrollLayout(
          constraints.maxWidth,
          constraints.maxHeight,
        );
        final showSidebar = Responsive.showSidebar(screenWidth);

        if (useScroll) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DashboardQuickActionsHeader(state: state),
                const SizedBox(height: AppSpacing.md),
                DashboardActionsSection(
                  state: state,
                  interactions: interactions,
                  width: constraints.maxWidth,
                  shrinkWrap: true,
                  compact: compact,
                ),
                const SizedBox(height: AppSpacing.xxl),
                const SectionTitle(icon: Icons.grid_view, title: 'Workspaces'),
                const SizedBox(height: AppSpacing.md),
                DashboardWorkspacesSection(
                  state: state,
                  interactions: interactions,
                  includeNewCard: true,
                  horizontal: true,
                ),
                if (!showSidebar) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  SizedBox(
                    height: 180,
                    child: DashboardRecentActionsPanel(history: state.history),
                  ),
                ],
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  height: 240,
                  child: DashboardTerminalPanel(
                    lines: state.terminal?.lines ?? ['No terminal output yet'],
                    isLive: state.terminal?.live ?? false,
                    backendConnected: state.backendConnected,
                    scrollController: terminalScrollController,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DashboardQuickActionsHeader(state: state),
                  Expanded(
                    child: DashboardActionsSection(
                      state: state,
                      interactions: interactions,
                      width: constraints.maxWidth,
                      compact: compact,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(icon: Icons.grid_view, title: 'Workspaces'),
                  Expanded(
                    child: DashboardWorkspacesSection(
                      state: state,
                      interactions: interactions,
                      includeNewCard: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  if (showSidebar) ...[
                    Expanded(
                      flex: 2,
                      child: DashboardRecentActionsPanel(history: state.history),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                  ],
                  Expanded(
                    flex: 3,
                    child: DashboardTerminalPanel(
                      lines: state.terminal?.lines ?? ['No terminal output yet'],
                      isLive: state.terminal?.live ?? false,
                      backendConnected: state.backendConnected,
                      scrollController: terminalScrollController,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
