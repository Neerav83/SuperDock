import 'package:flutter/material.dart';

import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';
import 'animated_press.dart';
import 'glass_card.dart';

class DockButton extends StatelessWidget {
  const DockButton({
    super.key,
    required this.title,
    required this.icon,
    required this.status,
    required this.accentColor,
    this.onTap,
    this.isLoading = false,
    this.isActive = false,
  });

  final String title;
  final IconData icon;
  final String status;
  final Color accentColor;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedPress(
      onTap: isLoading ? null : onTap,
      accentColor: accentColor,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.lg,
          horizontal: AppSpacing.md,
        ),
        borderColor: isActive
            ? accentColor.withValues(alpha: 0.6)
            : AppColors.cardBorder,
        gradient: isActive
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentColor.withValues(alpha: 0.12),
                  AppColors.cardBackground.withValues(alpha: 0.05),
                ],
              )
            : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: isActive ? 0.5 : 0.35),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: accentColor, size: 28),
                ),
                if (isLoading)
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accentColor.withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              isLoading ? 'Kör...' : (isActive ? 'Aktiv' : status),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isLoading || isActive
                        ? accentColor
                        : AppColors.textMuted,
                    fontWeight: isLoading || isActive
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
