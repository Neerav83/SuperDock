import 'package:flutter/material.dart';
import 'package:superdock_ui/core/models/models.dart';
import 'package:superdock_ui/core/theme/tokens.dart';
import 'package:superdock_ui/widgets/widgets.dart';

class DashboardRecentActionsPanel extends StatelessWidget {
  const DashboardRecentActionsPanel({
    super.key,
    required this.history,
  });

  final List<ActionHistoryEntry> history;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Actions',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: history.isEmpty
                ? Center(
                    child: Text(
                      'No actions yet',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  )
                : ListView.separated(
                    itemCount: history.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, i) {
                      final entry = history[i];
                      return Row(
                        children: [
                          Icon(
                            entry.success
                                ? Icons.check_circle
                                : Icons.error_outline,
                            size: 16,
                            color: entry.success
                                ? AppColors.green
                                : AppColors.orange,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              entry.label,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                          Text(
                            entry.relative,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
