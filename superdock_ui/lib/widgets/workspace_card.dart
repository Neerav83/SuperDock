import 'package:flutter/material.dart';

import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';
import 'animated_press.dart';
import 'glass_card.dart';

class WorkspaceCard extends StatelessWidget {
  const WorkspaceCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    this.imageUrl,
    this.onActivate,
    this.onLaunch,
    this.isLoading = false,
    this.isActive = false,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final String? imageUrl;
  final VoidCallback? onActivate;
  final VoidCallback? onLaunch;
  final bool isLoading;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.cardBackground,
          accentColor.withValues(alpha: isActive ? 0.16 : 0.08),
        ],
      ),
      borderColor: isActive
          ? accentColor.withValues(alpha: 0.75)
          : accentColor.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: isLoading ? null : onActivate,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      WorkspaceAvatar(
                        icon: icon,
                        accentColor: accentColor,
                        imageUrl: imageUrl,
                        size: 24,
                      ),
                      if (isActive) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.18),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.pillRadius),
                          ),
                          child: Text(
                            'Active',
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: accentColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedPress(
            onTap: isLoading ? null : onLaunch,
            accentColor: accentColor,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                border: Border.all(color: accentColor.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.2),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: isLoading
                  ? SizedBox(
                      height: 18,
                      child: Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: accentColor,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      'Launch',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class NewWorkspaceCard extends StatelessWidget {
  const NewWorkspaceCard({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedPress(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        borderColor: AppColors.textMuted.withValues(alpha: 0.3),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: AppColors.textMuted.withValues(alpha: 0.4),
            radius: AppSpacing.cardRadius,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                size: 32,
                color: AppColors.textMuted.withValues(alpha: 0.7),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'New Workspace',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = distance + 6;
        canvas.drawPath(
          metric.extractPath(distance, end.clamp(0, metric.length)),
          paint,
        );
        distance = end + 4;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WorkspaceAvatar extends StatelessWidget {
  const WorkspaceAvatar({
    super.key,
    required this.icon,
    required this.accentColor,
    this.imageUrl,
    this.size = 24,
  });

  final IconData icon;
  final Color accentColor;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) {
      return Icon(icon, color: accentColor, size: size);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.sm),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(icon, color: accentColor, size: size);
        },
      ),
    );
  }
}
