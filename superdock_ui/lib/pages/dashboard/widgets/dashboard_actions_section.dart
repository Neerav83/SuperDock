import 'package:flutter/material.dart';

import 'package:superdock_ui/core/theme/tokens.dart';
import 'package:superdock_ui/pages/dashboard/dashboard_providers.dart';
import 'package:superdock_ui/pages/dashboard/widgets/dashboard_interactions.dart';
import 'package:superdock_ui/widgets/widgets.dart';

class DashboardQuickActionsHeader extends StatelessWidget {
  const DashboardQuickActionsHeader({super.key, required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final workspace = state.activeWorkspace;

    if (workspace != null &&
        workspace.imageUrl != null &&
        workspace.imageUrl!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Row(
          children: [
            WorkspaceAvatar(
              icon: workspace.icon,
              accentColor: workspace.accentColor,
              imageUrl: workspace.imageUrl,
              size: 32,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              '${workspace.name} Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
      );
    }

    return SectionTitle(icon: Icons.bolt, title: state.quickActionsTitle);
  }
}

class DashboardActionsSection extends StatelessWidget {
  const DashboardActionsSection({
    super.key,
    required this.state,
    required this.interactions,
    required this.width,
    this.shrinkWrap = false,
    this.compact = false,
  });

  final DashboardState state;
  final DashboardInteractions interactions;
  final double width;
  final bool shrinkWrap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (state.showWorkspaceQuickActions) {
      return _buildWorkspaceActionsGrid(context);
    }

    if (state.dockActions.isEmpty) {
      return Center(
        child: Text(
          state.backendConnected
              ? 'No actions available'
              : 'Connect to backend to load actions',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
      );
    }

    return _buildDockActionsGrid(context);
  }

  Widget _buildWorkspaceActionsGrid(BuildContext context) {
    final actions = state.workspaceQuickActions;
    final columns = Responsive.actionColumns(width, actions.length + 1);
    final tileHeight = Responsive.actionTileHeight(width, compact: compact);

    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        mainAxisExtent: tileHeight,
      ),
      itemCount: actions.length + 1,
      itemBuilder: (context, i) {
        if (i == actions.length) {
          return _AddWorkspaceActionButton(
            compact: compact,
            onTap: interactions.openAddWorkspaceCommand,
          );
        }

        final action = actions[i];
        final loadingKey = '${action.workspace.id}:${action.actionIndex}';
        return GestureDetector(
          onLongPress: () => interactions.openEditWorkspaceAction(action),
          child: DockButton(
            title: action.title,
            icon: action.icon,
            status: action.status,
            accentColor: action.accentColor,
            isLoading: state.loadingWorkspaceActionKey == loadingKey,
            isActive: interactions.isAppActive(action.appName),
            compact: compact,
            onTap: () => interactions.handleWorkspaceQuickAction(action),
          ),
        );
      },
    );
  }

  Widget _buildDockActionsGrid(BuildContext context) {
    final columns = Responsive.actionColumns(width, state.dockActions.length);
    final tileHeight = Responsive.actionTileHeight(width, compact: compact);

    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        mainAxisExtent: tileHeight,
      ),
      itemCount: state.dockActions.length,
      itemBuilder: (context, i) {
        final action = state.dockActions[i];
        return GestureDetector(
          onLongPress: () => interactions.openEditAction(action),
          child: DockButton(
            title: action.title,
            icon: action.icon,
            status: action.status,
            accentColor: action.accentColor,
            isLoading: state.loadingActionId == action.id,
            isActive: interactions.isAppActive(action.appName),
            compact: compact,
            onTap: () => interactions.handleDockAction(action),
          ),
        );
      },
    );
  }
}

class _AddWorkspaceActionButton extends StatelessWidget {
  const _AddWorkspaceActionButton({
    required this.compact,
    required this.onTap,
  });

  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final circleSize = compact ? 32.0 : 48.0;
    final iconSize = compact ? 20.0 : 28.0;

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        borderColor: AppColors.textMuted.withValues(alpha: 0.35),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.textMuted.withValues(alpha: 0.45),
                ),
              ),
              child: Icon(
                Icons.add,
                size: iconSize,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              'Command',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
