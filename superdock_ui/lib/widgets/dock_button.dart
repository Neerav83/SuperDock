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
    this.compact = false,
  });

  final String title;
  final IconData icon;
  final String status;
  final Color accentColor;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isActive;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 20.0 : 28.0;
    final circleSize = compact ? 32.0 : 48.0;
    final vPadding = compact ? AppSpacing.xs : AppSpacing.lg;
    final hPadding = compact ? AppSpacing.sm : AppSpacing.md;

    return AnimatedPress(
      onTap: isLoading ? null : onTap,
      accentColor: accentColor,
      child: SizedBox.expand(
        child: GlassCard(
          padding: EdgeInsets.symmetric(vertical: vPadding, horizontal: hPadding),
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
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: circleSize,
                      height: circleSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(
                              alpha: isActive ? 0.5 : 0.35,
                            ),
                            blurRadius: compact ? 12 : 20,
                            spreadRadius: compact ? 1 : 2,
                          ),
                        ],
                      ),
                      child: Icon(icon, color: accentColor, size: iconSize),
                    ),
                    if (isLoading)
                      SizedBox(
                        width: circleSize + 4,
                        height: circleSize + 4,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accentColor.withValues(alpha: 0.8),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: compact ? AppSpacing.xs : AppSpacing.md),
                Text(
                  title,
                  style: (compact
                          ? Theme.of(context).textTheme.labelSmall
                          : Theme.of(context).textTheme.labelLarge)
                      ?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: compact ? 2 : AppSpacing.xs),
                Text(
                  isLoading ? 'Kör...' : (isActive ? 'Aktiv' : status),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: compact ? 10 : null,
                        color: isLoading || isActive
                            ? accentColor
                            : AppColors.textMuted,
                        fontWeight: isLoading || isActive
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
