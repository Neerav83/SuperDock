import 'package:flutter/material.dart';
import 'package:superdock_ui/core/models/models.dart';
import 'package:superdock_ui/core/services/services.dart';
import 'package:superdock_ui/core/theme/tokens.dart';
import 'package:superdock_ui/widgets/widgets.dart';

Future<void> showAllProcessesDialog({
  required BuildContext context,
  required SuperDockApi api,
  required List<ProcessInfo> fallbackProcesses,
}) async {
  var items = fallbackProcesses;
  try {
    items = await api.getAllProcesses();
  } catch (_) {}
  if (!context.mounted) return;

  await showSuperDockDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'All Active Processes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text(
                          'No active processes',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                      )
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final process = items[index];
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
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
