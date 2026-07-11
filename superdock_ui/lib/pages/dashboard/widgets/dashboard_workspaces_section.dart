import 'package:flutter/material.dart';

import 'package:superdock_ui/core/models/models.dart';
import 'package:superdock_ui/core/theme/tokens.dart';
import 'package:superdock_ui/pages/dashboard/dashboard_providers.dart';
import 'package:superdock_ui/pages/dashboard/widgets/dashboard_interactions.dart';
import 'package:superdock_ui/widgets/widgets.dart';

class DashboardWorkspacesSection extends StatelessWidget {
  const DashboardWorkspacesSection({
    super.key,
    required this.state,
    required this.interactions,
    required this.includeNewCard,
    this.horizontal = false,
  });

  final DashboardState state;
  final DashboardInteractions interactions;
  final bool includeNewCard;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    if (state.workspaces.isEmpty) {
      return Center(
        child: Text(
          state.backendConnected
              ? 'No workspaces available'
              : 'Connect to backend to load workspaces',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
      );
    }

    if (horizontal) {
      return _buildHorizontalList();
    }

    return _buildVerticalRow();
  }

  Widget _buildWorkspaceCard(Workspace ws) {
    return WorkspaceCard(
      title: ws.name,
      description: ws.description,
      icon: ws.icon,
      accentColor: ws.accentColor,
      imageUrl: ws.imageUrl,
      isActive: state.activeWorkspaceId == ws.id,
      isLoading: state.loadingWorkspaceId == ws.id,
      onActivate: () => interactions.activateWorkspace(ws),
      onLaunch: () => interactions.handleWorkspaceLaunch(ws),
    );
  }

  Widget _buildHorizontalList() {
    final cards = <Widget>[
      for (final ws in state.workspaces)
        SizedBox(
          width: 200,
          child: GestureDetector(
            onLongPress: () => interactions.openEditWorkspace(ws),
            child: _buildWorkspaceCard(ws),
          ),
        ),
      if (includeNewCard)
        SizedBox(
          width: 200,
          child: NewWorkspaceCard(onTap: interactions.openCreateWorkspace),
        ),
    ];

    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) => cards[index],
      ),
    );
  }

  Widget _buildVerticalRow() {
    final cards = [
      for (final ws in state.workspaces)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: GestureDetector(
              onLongPress: () => interactions.openEditWorkspace(ws),
              child: _buildWorkspaceCard(ws),
            ),
          ),
        ),
      if (includeNewCard)
        Expanded(
          child: NewWorkspaceCard(onTap: interactions.openCreateWorkspace),
        ),
    ];

    return Row(children: cards);
  }
}
