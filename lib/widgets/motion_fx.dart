import 'dart:async';

import 'package:flutter/cupertino.dart';

class MotionBackdrop extends StatelessWidget {
  final Color backgroundColor;
  final Color surfaceColor;
  final Color accentColor;
  final Widget child;

  const MotionBackdrop({
    super.key,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.accentColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            backgroundColor,
            Color.lerp(backgroundColor, surfaceColor, 0.55) ?? surfaceColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: _GlowOrb(
              size: 240,
              color: accentColor.withOpacity(0.14),
            ),
          ),
          Positioned(
            bottom: -110,
            left: -70,
            child: _GlowOrb(
              size: 260,
              color: surfaceColor.withOpacity(0.18),
            ),
          ),
          Positioned(
            top: 180,
            left: -40,
            child: _GlowOrb(
              size: 160,
              color: accentColor.withOpacity(0.08),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class MotionCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color borderColor;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? glowColor;

  const MotionCard({
    super.key,
    required this.child,
    required this.color,
    required this.borderColor,
    required this.radius,
    this.padding,
    this.margin,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: (glowColor ?? borderColor).withOpacity(0.14),
            blurRadius: 28,
            spreadRadius: -10,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

class MotionReveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Offset beginOffset;

  const MotionReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.beginOffset = const Offset(0, 0.04),
  });

  @override
  State<MotionReveal> createState() => _MotionRevealState();
}

class _MotionRevealState extends State<MotionReveal> {
  bool _visible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) {
        setState(() => _visible = true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      offset: _visible ? Offset.zero : widget.beginOffset,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
        opacity: _visible ? 1 : 0,
        child: widget.child,
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withOpacity(0.0),
            ],
          ),
        ),
      ),
    );
  }
}
