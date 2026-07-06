import 'package:flutter/material.dart';

import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';
import 'glass_card.dart';

class StatusCard extends StatelessWidget {
  const StatusCard({
    super.key,
    required this.cpu,
    required this.memory,
    required this.disk,
    required this.uptime,
    this.cpuHistory = const [],
    this.memoryHistory = const [],
    this.diskHistory = const [],
  });

  final int cpu;
  final int memory;
  final int disk;
  final String uptime;
  final List<int> cpuHistory;
  final List<int> memoryHistory;
  final List<int> diskHistory;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Overview',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _MetricRow(
            label: 'CPU',
            value: cpu,
            color: AppColors.purple,
            history: cpuHistory,
          ),
          const SizedBox(height: AppSpacing.md),
          _MetricRow(
            label: 'Memory',
            value: memory,
            color: AppColors.blue,
            history: memoryHistory,
          ),
          const SizedBox(height: AppSpacing.md),
          _MetricRow(
            label: 'Disk',
            value: disk,
            color: AppColors.green,
            history: diskHistory,
          ),
          const SizedBox(height: AppSpacing.lg),
          Divider(color: AppColors.cardBorder, height: 1),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text(
                'Uptime',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
              const Spacer(),
              Text(
                uptime,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
    required this.color,
    required this.history,
  });

  final String label;
  final int value;
  final Color color;
  final List<int> history;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 32,
            child: CustomPaint(
              painter: _SparklinePainter(color: color, values: history),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$value%',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.color, required this.values});

  final Color color;
  final List<int> values;

  @override
  void paint(Canvas canvas, Size size) {
    final data = values.isEmpty ? [0] : values;
    final maxVal = data.reduce((a, b) => a > b ? a : b).clamp(1, 100);

    final points = List.generate(data.length, (i) {
      final x = data.length == 1 ? size.width : i * size.width / (data.length - 1);
      final y = size.height - (data[i] / maxVal) * size.height * 0.8 - size.height * 0.1;
      return Offset(x, y);
    });

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fillPath, fillPaint);
  }

  int get value => values.isEmpty ? 0 : values.last;

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values;
  }
}