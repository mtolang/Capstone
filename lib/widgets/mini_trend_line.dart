import 'package:flutter/material.dart';

class MiniTrendLine extends StatelessWidget {
  final List<double> data;
  final Color color;
  final double strokeWidth;
  final double height;

  const MiniTrendLine({
    super.key,
    required this.data,
    this.color = Colors.indigo,
    this.strokeWidth = 2,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparkPainter(data: data, color: color, strokeWidth: strokeWidth),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double strokeWidth;

  _SparkPainter({required this.data, required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final min = data.reduce((a, b) => a < b ? a : b);
    final max = data.reduce((a, b) => a > b ? a : b);
    final range = (max - min).abs() < 1e-6 ? 1.0 : (max - min);

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final y = size.height - ((data[i] - min) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity(0.18), Colors.transparent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fill, fillPaint);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
