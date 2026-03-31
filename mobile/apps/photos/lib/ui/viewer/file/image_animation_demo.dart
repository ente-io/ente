import "dart:math" as math;
import "dart:ui" as ui;

import "package:flutter/material.dart";

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ImageAnimationDemo(),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Demo page with animation switcher
// ─────────────────────────────────────────────────────────────────────────────

/// Demo page showcasing two image-overlay animation styles:
/// dot-grid ripple and scan-line with radial pulse.
class ImageAnimationDemo extends StatefulWidget {
  const ImageAnimationDemo({super.key});

  @override
  State<ImageAnimationDemo> createState() => _ImageAnimationDemoState();
}

class _ImageAnimationDemoState extends State<ImageAnimationDemo> {
  bool _useScanPulse = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildSwitcher(),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AspectRatio(
                    aspectRatio: 3 / 2,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildContent(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitcher() {
    Widget tab(String label, bool active, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: active ? 0.9 : 0.5),
              fontSize: 14,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          tab(
            "Dot grid",
            !_useScanPulse,
            () => setState(() => _useScanPulse = false),
          ),
          const SizedBox(width: 4),
          tab(
            "Scan + pulse",
            _useScanPulse,
            () => setState(() => _useScanPulse = true),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Placeholder image background
        Container(
          color: const Color(0xFF1A1A1A),
          child: Center(
            child: Icon(
              Icons.landscape,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
        ),
        // Dark overlay
        ColoredBox(color: Colors.black.withValues(alpha: 0.15)),
        // Breathe effect (scan+pulse mode only)
        if (_useScanPulse) const _BreatheOverlay(),
        // Animation overlay
        IgnorePointer(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _useScanPulse
                ? const ScanPulseOverlay(key: ValueKey("scan"))
                : const DotGridOverlay(key: ValueKey("dots")),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animation A: Dot grid overlay
// ─────────────────────────────────────────────────────────────────────────────

/// A 24×16 grid of dots that pulse outward from the center in a ripple pattern.
class DotGridOverlay extends StatefulWidget {
  const DotGridOverlay({super.key});

  @override
  State<DotGridOverlay> createState() => _DotGridOverlayState();
}

class _DotGridOverlayState extends State<DotGridOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _DotGridPainter(progress: _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _DotGridPainter extends CustomPainter {
  static const int _cols = 24;
  static const int _rows = 16;
  // sqrt(50^2 + 50^2) — max distance from center in percentage space.
  static const double _maxDist = 70.710678;

  final double progress;

  _DotGridPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (int r = 0; r < _rows; r++) {
      for (int c = 0; c < _cols; c++) {
        // Pixel position for drawing
        final double x = ((c + 0.5) / _cols) * size.width;
        final double y = ((r + 0.5) / _rows) * size.height;

        // Distance in percentage space (0-100) from center for delay
        final double dx = ((c + 0.5) / _cols) * 100 - 50;
        final double dy = ((r + 0.5) / _rows) * 100 - 50;
        final double dist = math.sqrt(dx * dx + dy * dy);

        // Delay: (dist / maxDist) * 1.8s, normalized to cycle: * (1.8 / 2.5)
        final double delay = (dist / _maxDist) * 0.72;

        double phase = (progress - delay) % 1.0;
        if (phase < 0) phase += 1.0;

        // Ping-pong with ease-in-out within each half
        double t;
        if (phase < 0.5) {
          t = _easeInOut(phase * 2);
        } else {
          t = _easeInOut((1.0 - phase) * 2);
        }

        if (t < 0.01) continue;

        // CSS: scale(0)→scale(1)→scale(0), opacity 0→0.5→0
        final double radius = 1.5 * t;
        final double opacity = 0.5 * t;

        final paint = Paint()..color = Color.fromRGBO(255, 255, 255, opacity);
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  static double _easeInOut(double t) {
    return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
  }

  @override
  bool shouldRepaint(_DotGridPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Animation B: Scan line + radial pulse + edge glow
// ─────────────────────────────────────────────────────────────────────────────

/// Composite overlay with a scanning line, radial pulse, and edge glow.
class ScanPulseOverlay extends StatefulWidget {
  const ScanPulseOverlay({super.key});

  @override
  State<ScanPulseOverlay> createState() => _ScanPulseOverlayState();
}

class _ScanPulseOverlayState extends State<ScanPulseOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _scanController;
  late final AnimationController _pulseController;
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();
  }

  @override
  void dispose() {
    _scanController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: _scanController,
          builder: (context, _) => CustomPaint(
            painter: _ScanLinePainter(progress: _scanController.value),
            size: Size.infinite,
          ),
        ),
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) => CustomPaint(
            painter: _RadialPulsePainter(progress: _pulseController.value),
            size: Size.infinite,
          ),
        ),
        AnimatedBuilder(
          animation: _glowController,
          builder: (context, _) => CustomPaint(
            painter: _EdgeGlowPainter(progress: _glowController.value),
            size: Size.infinite,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scan line painter
// ─────────────────────────────────────────────────────────────────────────────

/// Horizontal gradient line that sweeps from top to bottom.
class _ScanLinePainter extends CustomPainter {
  final double progress;

  _ScanLinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Position with ease-in-out: -2px → size.height
    final double easedPos = _easeInOut(progress);
    final double y = -2.0 + (size.height + 2.0) * easedPos;

    // Opacity: fade in 0–5%, full 5–95%, fade out 95–100%
    double opacity;
    if (progress < 0.05) {
      opacity = progress / 0.05;
    } else if (progress > 0.95) {
      opacity = (1.0 - progress) / 0.05;
    } else {
      opacity = 1.0;
    }

    // Glow behind the line
    final glowPaint = Paint()
      ..color = Color.fromRGBO(255, 220, 180, 0.1 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width / 2, y + 1),
        width: size.width + 12,
        height: 14,
      ),
      glowPaint,
    );

    // Main scan line with horizontal gradient
    final lineRect = Rect.fromLTWH(0, y, size.width, 2);
    final gradient = ui.Gradient.linear(
      Offset(0, y),
      Offset(size.width, y),
      [
        Colors.transparent,
        Color.fromRGBO(255, 220, 180, 0.5 * opacity),
        Color.fromRGBO(255, 255, 255, 0.4 * opacity),
        Color.fromRGBO(255, 220, 180, 0.5 * opacity),
        Colors.transparent,
      ],
      [0.0, 0.25, 0.5, 0.75, 1.0],
    );
    final linePaint = Paint()..shader = gradient;
    canvas.drawRRect(
      RRect.fromRectAndRadius(lineRect, const Radius.circular(1)),
      linePaint,
    );
  }

  static double _easeInOut(double t) {
    return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
  }

  @override
  bool shouldRepaint(_ScanLinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Radial pulse painter
// ─────────────────────────────────────────────────────────────────────────────

/// Radial gradient that breathes from the center, scaling 0.6→1→0.6.
class _RadialPulsePainter extends CustomPainter {
  final double progress;

  _RadialPulsePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Ping-pong with ease-in-out: scale 0.6→1→0.6, opacity 0→1→0
    double t;
    if (progress < 0.5) {
      t = _easeInOut(progress * 2);
    } else {
      t = _easeInOut((1.0 - progress) * 2);
    }

    final center = Offset(size.width / 2, size.height / 2);
    final scale = 0.6 + 0.4 * t;
    final double maxDim = math.max(size.width, size.height) * 0.6 * scale;

    final gradient = ui.Gradient.radial(
      center,
      maxDim,
      [Color.fromRGBO(255, 240, 210, 0.08 * t), Colors.transparent],
      [0.0, 0.6],
    );
    final paint = Paint()..shader = gradient;
    canvas.drawRect(Offset.zero & size, paint);
  }

  static double _easeInOut(double t) {
    return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
  }

  @override
  bool shouldRepaint(_RadialPulsePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Edge glow painter (simulates CSS inset box-shadow)
// ─────────────────────────────────────────────────────────────────────────────

/// Pulsing inset glow around the edges, simulating CSS inset box-shadow.
class _EdgeGlowPainter extends CustomPainter {
  final double progress;

  _EdgeGlowPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Ping-pong with ease-in-out
    double t;
    if (progress < 0.5) {
      t = _easeInOut(progress * 2);
    } else {
      t = _easeInOut((1.0 - progress) * 2);
    }

    final double blur = 40.0 + 20.0 * t;
    final double alpha = 0.02 + 0.05 * t;
    final color = Color.fromRGBO(255, 220, 180, alpha);

    // Draw thick stroked rect clipped to bounds → inset glow effect
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(2)),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = blur * 2
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(2)),
      paint,
    );
    canvas.restore();
  }

  static double _easeInOut(double t) {
    return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
  }

  @override
  bool shouldRepaint(_EdgeGlowPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Breathe overlay — subtle brightness dimming for scan+pulse mode
// ─────────────────────────────────────────────────────────────────────────────

/// Simulates CSS `filter: brightness(0.92)` by overlaying a pulsing dark tint.
class _BreatheOverlay extends StatefulWidget {
  const _BreatheOverlay();

  @override
  State<_BreatheOverlay> createState() => _BreatheOverlayState();
}

class _BreatheOverlayState extends State<_BreatheOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // Brightness: 1.0 → 0.92 → 1.0 (darken by up to 8%)
        final double darken = math.sin(_controller.value * math.pi) * 0.08;
        return ColoredBox(color: Colors.black.withValues(alpha: darken));
      },
    );
  }
}
