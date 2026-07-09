import 'package:flutter/material.dart';
import 'package:superdock_ui/core/theme/tokens.dart';
import 'package:superdock_ui/widgets/widgets.dart';

class DashboardTerminalPanel extends StatelessWidget {
  const DashboardTerminalPanel({
    super.key,
    required this.lines,
    required this.isLive,
    required this.backendConnected,
    required this.scrollController,
  });

  final List<String> lines;
  final bool isLive;
  final bool backendConnected;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final displayLines = backendConnected
        ? lines
        : ['Backend offline — start superdock-core to see terminal output'];

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Text(
                  'Terminal Output',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: (isLive ? AppColors.green : AppColors.textMuted)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isLive ? AppColors.green : AppColors.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        isLive ? 'Live' : 'Idle',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isLive
                                  ? AppColors.green
                                  : AppColors.textMuted,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.terminalBackground,
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
              child: ListView.builder(
                controller: scrollController,
                itemCount: displayLines.length,
                itemBuilder: (context, i) => Text(
                  displayLines[i],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: AppColors.terminalText.withValues(alpha: 0.85),
                        height: 1.6,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
