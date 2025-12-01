import 'dart:math';
import 'package:flutter/material.dart';

class WaveProgressBar extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double>? onChanged;
  final Color activeColor;
  final Color inactiveColor;

  const WaveProgressBar({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    this.onChanged,
    this.activeColor = Colors.blue,
    this.inactiveColor = Colors.grey,
  });

  @override
  State<WaveProgressBar> createState() => _WaveProgressBarState();
}

class _WaveProgressBarState extends State<WaveProgressBar> {
  // Generate a static "waveform" so it doesn't jitter during playback
  final List<double> _amplitudes = List.generate(
    100,
    (index) => Random().nextDouble(),
  );

  void _handleInput(Offset localPosition, double width) {
    if (widget.onChanged == null) return;

    final dx = localPosition.dx.clamp(0.0, width);
    final percent = dx / width;
    final newValue = widget.min + (widget.max - widget.min) * percent;
    widget.onChanged!(newValue);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        final box = context.findRenderObject() as RenderBox;
        _handleInput(box.globalToLocal(details.globalPosition), box.size.width);
      },
      onTapDown: (details) {
        final box = context.findRenderObject() as RenderBox;
        _handleInput(details.localPosition, box.size.width);
      },
      child: SizedBox(
        height: 40, // Height for the wave
        width: double.infinity,
        child: CustomPaint(
          painter: _WavePainter(
            value: widget.value,
            min: widget.min,
            max: widget.max,
            amplitudes: _amplitudes,
            activeColor: widget.activeColor,
            inactiveColor: widget.inactiveColor,
          ),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double value;
  final double min;
  final double max;
  final List<double> amplitudes;
  final Color activeColor;
  final Color inactiveColor;

  _WavePainter({
    required this.value,
    required this.min,
    required this.max,
    required this.amplitudes,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0; // Thickness of each bar

    final centerY = size.height / 2;
    final totalBars = amplitudes.length;
    final barSpacing = size.width / totalBars;

    // Calculate progress ratio (0.0 to 1.0)
    final progress = (value - min) / (max - min);
    final currentBarIndex = (progress * totalBars).floor();

    for (int i = 0; i < totalBars; i++) {
      final x = i * barSpacing + barSpacing / 2;

      if (i <= currentBarIndex) {
        // Played part: Draw Wave
        paint.color = activeColor;
        // Scale amplitude to fit height, keeping a minimum height
        final height = (amplitudes[i] * size.height * 0.8).clamp(
          4.0,
          size.height,
        );
        final top = centerY - height / 2;
        final bottom = centerY + height / 2;
        canvas.drawLine(Offset(x, top), Offset(x, bottom), paint);
      } else {
        // Remaining part: Draw Straight Line
        paint.color = inactiveColor;
        // Draw a small dot or thin line to represent the "track"
        canvas.drawLine(
          Offset(x, centerY),
          Offset(x, centerY),
          paint..strokeWidth = 2.0,
        );
      }
    }

    // Draw a thumb/knob at the current position
    final thumbX = progress * size.width;
    paint.color = Colors.white;
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(thumbX, centerY), 6.0, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return value != oldDelegate.value ||
        activeColor != oldDelegate.activeColor ||
        inactiveColor != oldDelegate.inactiveColor;
  }
}
