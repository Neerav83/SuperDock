import 'package:flutter/material.dart';

import 'package:superdock_ui/core/theme/tokens.dart';
import 'package:superdock_ui/pages/dashboard/dashboard_providers.dart';
import 'package:superdock_ui/pages/dashboard/widgets/dashboard_interactions.dart';
import 'package:superdock_ui/widgets/widgets.dart';

class DashboardTopNav extends StatelessWidget {
  const DashboardTopNav({
    super.key,
    required this.state,
    required this.interactions,
  });

  final DashboardState state;
  final DashboardInteractions interactions;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact =
        Responsive.isCompactWidth(width) || Responsive.useStackedTopNav(width);

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildTitle(context, showTagline: false)),
              _ConnectionStatus(state: state),
              const SizedBox(width: AppSpacing.sm),
              _SettingsButton(onTap: interactions.openSettings),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _NavPill(
            selectedNav: state.selectedNav,
            onNavSelected: interactions.setSelectedNav,
          ),
        ],
      );
    }

    return Row(
      children: [
        _buildTitle(context, showTagline: true),
        const Spacer(),
        _NavPill(
          selectedNav: state.selectedNav,
          onNavSelected: interactions.setSelectedNav,
        ),
        const Spacer(),
        _ConnectionStatus(state: state),
        const SizedBox(width: AppSpacing.md),
        _SettingsButton(onTap: interactions.openSettings),
      ],
    );
  }

  Widget _buildTitle(BuildContext context, {required bool showTagline}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.purple, AppColors.blue],
          ).createShader(bounds),
          child: Text(
            'SuperDock',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
          ),
        ),
        if (showTagline)
          Text(
            'Your command center for everything',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
      ],
    );
  }
}

class _NavPill extends StatelessWidget {
  const _NavPill({
    required this.selectedNav,
    required this.onNavSelected,
  });

  final int selectedNav;
  final ValueChanged<int> onNavSelected;

  @override
  Widget build(BuildContext context) {
    const labels = ['Dashboard', 'Workspaces', 'Actions'];

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.xs),
      borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(labels.length, (i) {
          final isActive = selectedNav == i;
          return GestureDetector(
            onTap: () => onNavSelected(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                border: isActive
                    ? Border.all(color: AppColors.blue.withValues(alpha: 0.6))
                    : null,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppColors.blue.withValues(alpha: 0.2),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                labels[i],
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isActive
                          ? AppColors.textPrimary
                          : AppColors.navInactive,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ConnectionStatus extends StatelessWidget {
  const _ConnectionStatus({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final hostname = state.backendConnected
        ? (state.status?.hostname ?? 'Connected')
        : 'Disconnected';

    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            hostname,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: state.backendConnected ? AppColors.green : AppColors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            state.backendConnected ? 'Connected' : 'Offline',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color:
                      state.backendConnected ? AppColors.green : AppColors.orange,
                ),
          ),
        ],
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        borderRadius: BorderRadius.circular(28),
        child: const Icon(
          Icons.settings_outlined,
          size: 20,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
