import 'package:flutter/material.dart';

import 'package:superdock_ui/core/theme/tokens.dart';
import 'package:superdock_ui/pages/dashboard/dashboard_providers.dart';
import 'package:superdock_ui/pages/dashboard/dashboard_widgets.dart';

class DashboardActionsView extends StatelessWidget {
  const DashboardActionsView({
    super.key,
    required this.state,
    required this.interactions,
  });

  final DashboardState state;
  final DashboardInteractions interactions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = Responsive.isCompactWidth(constraints.maxWidth);
        final useScroll = Responsive.useScrollLayout(
          constraints.maxWidth,
          constraints.maxHeight,
        );

        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: DashboardQuickActionsHeader(state: state)),
                if (!state.showWorkspaceQuickActions)
                  IconButton(
                    onPressed: interactions.openCreateAction,
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    tooltip: 'Create new action',
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            useScroll
                ? DashboardActionsSection(
                    state: state,
                    interactions: interactions,
                    width: constraints.maxWidth,
                    shrinkWrap: true,
                    compact: compact,
                  )
                : Expanded(
                    child: DashboardActionsSection(
                      state: state,
                      interactions: interactions,
                      width: constraints.maxWidth,
                      compact: compact,
                    ),
                  ),
            if (!useScroll) ...[
              const SizedBox(height: AppSpacing.xxl),
              Expanded(
                child: DashboardRecentActionsPanel(history: state.history),
              ),
            ],
          ],
        );

        if (useScroll) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content,
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  height: 200,
                  child: DashboardRecentActionsPanel(history: state.history),
                ),
              ],
            ),
          );
        }

        return content;
      },
    );
  }
}
