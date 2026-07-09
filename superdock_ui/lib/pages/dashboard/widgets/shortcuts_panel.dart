import 'package:flutter/material.dart';
import 'package:superdock_ui/core/models/models.dart';
import 'package:superdock_ui/core/theme/tokens.dart';
import 'package:superdock_ui/widgets/widgets.dart';

class DashboardShortcutsPanel extends StatelessWidget {
  const DashboardShortcutsPanel({
    super.key,
    required this.workspaces,
  });

  final List<Workspace> workspaces;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shortcuts',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (workspaces.isEmpty)
            Text(
              'No workspace shortcuts loaded',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            )
          else
            for (final ws in workspaces) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(
                      ws.shortcut ?? '',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      ws.name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}
