import 'package:flutter/material.dart';
import 'package:superdock_ui/core/models/models.dart';
import 'package:superdock_ui/core/theme/tokens.dart';
import 'package:superdock_ui/widgets/widgets.dart';

class DashboardProcessesPanel extends StatelessWidget {
  const DashboardProcessesPanel({
    super.key,
    required this.processes,
    required this.onViewAll,
  });

  final List<ProcessInfo> processes;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Processes',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: processes.isEmpty
                ? Center(
                    child: Text(
                      'No active processes',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  )
                : ListView.separated(
                    itemCount: processes.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, i) {
                      final process = processes[i];
                      return Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 14,
                            color: AppColors.green,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              process.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textPrimary),
                            ),
                          ),
                          Text(
                            process.detail,
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
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: onViewAll,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'View all processes',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
