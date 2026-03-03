import "package:flutter/material.dart";

class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;
  final bool enabled;
  final double glowIntensity;

  const ShimmerLoading({
    super.key,
    required this.child,
    required this.baseColor,
    required this.highlightColor,
    this.duration = const Duration(milliseconds: 1150),
    this.enabled = true,
    this.glowIntensity = 1,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ShimmerLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
    } else if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final gradient = _buildGlowPulseGradient();

        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return gradient.createShader(bounds);
          },
          child: child!,
        );
      },
    );
  }

  LinearGradient _buildGlowPulseGradient() {
    final phase = _controller.value;
    final pulse = phase <= 0.5 ? phase * 2 : (1 - phase) * 2;
    final easedPulse = Curves.easeInOut.transform(pulse);
    final intensity = widget.glowIntensity.clamp(0.0, 1.0).toDouble();
    const minGlow = 0.10;
    final maxGlow = (0.52 * intensity).clamp(minGlow, 0.9).toDouble();
    final glowStrength = minGlow + ((maxGlow - minGlow) * easedPulse);
    final pulseColor =
        Color.lerp(widget.baseColor, widget.highlightColor, glowStrength)!;

    return LinearGradient(
      colors: [
        pulseColor,
        pulseColor,
      ],
      stops: const [0.0, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
