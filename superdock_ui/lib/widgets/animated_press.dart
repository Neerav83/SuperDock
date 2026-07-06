import 'package:flutter/material.dart';

class AnimatedPress extends StatefulWidget {
  const AnimatedPress({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.94,
    this.accentColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final Color? accentColor;

  @override
  State<AnimatedPress> createState() => _AnimatedPressState();
}

class _AnimatedPressState extends State<AnimatedPress>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _flashController;
  late final Animation<double> _flashAnimation;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _flashAnimation = CurvedAnimation(
      parent: _flashController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onTap == null) return;

    widget.onTap!();
    _flashController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? Colors.white;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap != null ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.onTap != null ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: widget.onTap != null ? () => setState(() => _pressed = false) : null,
      onTap: widget.onTap != null ? _handleTap : null,
      child: AnimatedBuilder(
        animation: _flashAnimation,
        builder: (context, child) {
          final flashOpacity = (1 - _flashAnimation.value) * 0.35;

          return AnimatedScale(
            scale: _pressed ? widget.scale : 1.0,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            child: AnimatedOpacity(
              opacity: _pressed ? 0.75 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    if (_pressed)
                      BoxShadow(
                        color: accent.withValues(alpha: 0.45),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    if (flashOpacity > 0)
                      BoxShadow(
                        color: accent.withValues(alpha: flashOpacity),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: child,
              ),
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
