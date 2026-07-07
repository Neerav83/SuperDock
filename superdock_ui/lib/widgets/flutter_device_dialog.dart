import 'package:flutter/material.dart';

import '../core/models/flutter_device.dart';
import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';
import 'glass_card.dart';

class FlutterDeviceDialog extends StatelessWidget {
  const FlutterDeviceDialog({
    super.key,
    required this.devices,
    this.selectedDeviceId,
  });

  final List<FlutterDevice> devices;
  final String? selectedDeviceId;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
          child: GlassCard(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose Flutter device',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Pick where to run the app. Your last choice is highlighted.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: devices.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      final isSelected = device.id == selectedDeviceId;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.md),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.purple
                                : AppColors.cardBorder,
                          ),
                        ),
                        title: Text(
                          device.name,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          device.subtitle,
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                        trailing: Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.play_arrow_rounded,
                          color: isSelected
                              ? AppColors.purple
                              : AppColors.textMuted,
                        ),
                        onTap: () => Navigator.of(context).pop(device.id),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
