import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:qr/qr.dart' as qr;
import '../../features/generator/generator_models.dart';

class GradientQrView extends StatelessWidget {
  const GradientQrView({
    super.key,
    required this.data,
    required this.size,
    required this.colors,
    required this.errorCorrectionLevel,
    required this.moduleShape,
    this.logo,
    this.margin = 12,
    this.backgroundColor = Colors.white,
  });

  final String data;
  final double size;
  final List<Color> colors;
  final int errorCorrectionLevel;
  final QrModuleShape moduleShape;
  final ImageProvider? logo;
  final double margin;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(size),
              painter: _GradientQrPainter(
                data: data,
                colors: colors,
                errorCorrectionLevel: errorCorrectionLevel,
                moduleShape: moduleShape,
                margin: margin,
                backgroundColor: backgroundColor,
              ),
            ),
            if (logo != null)
              Container(
                width: size * .18,
                height: size * .18,
                padding: EdgeInsets.all(size * .018),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(size * .045),
                  boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8)],
                ),
                child: Image(image: logo!, fit: BoxFit.contain),
              ),
          ],
        ),
      );
}

class _GradientQrPainter extends CustomPainter {
  _GradientQrPainter({
    required this.data,
    required this.colors,
    required this.errorCorrectionLevel,
    required this.moduleShape,
    required this.margin,
    required this.backgroundColor,
  });

  final String data;
  final List<Color> colors;
  final int errorCorrectionLevel;
  final QrModuleShape moduleShape;
  final double margin;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor);
    if (data.isEmpty) return;
    late final qr.QrImage image;
    try {
      final code = qr.QrCode.fromData(data: data, errorCorrectLevel: errorCorrectionLevel);
      image = qr.QrImage(code);
    } catch (_) {
      return;
    }
    final count = image.moduleCount;
    final available = math.min(size.width, size.height) - margin * 2;
    final cell = available / count;
    final offsetX = (size.width - available) / 2;
    final offsetY = (size.height - available) / 2;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors.length >= 2 ? colors : [colors.first, colors.first],
      ).createShader(Rect.fromLTWH(offsetX, offsetY, available, available));

    for (var row = 0; row < count; row++) {
      for (var col = 0; col < count; col++) {
        if (!image.isDark(row, col)) continue;
        final rect = Rect.fromLTWH(offsetX + col * cell, offsetY + row * cell, cell * .94, cell * .94);
        switch (moduleShape) {
          case QrModuleShape.square:
            canvas.drawRect(rect, paint);
            break;
          case QrModuleShape.rounded:
            canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(cell * .28)), paint);
            break;
          case QrModuleShape.dots:
            canvas.drawCircle(rect.center, cell * .43, paint);
            break;
          case QrModuleShape.diamond:
            final path = Path()
              ..moveTo(rect.center.dx, rect.top)
              ..lineTo(rect.right, rect.center.dy)
              ..lineTo(rect.center.dx, rect.bottom)
              ..lineTo(rect.left, rect.center.dy)
              ..close();
            canvas.drawPath(path, paint);
            break;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GradientQrPainter oldDelegate) =>
      oldDelegate.data != data ||
      oldDelegate.colors != colors ||
      oldDelegate.errorCorrectionLevel != errorCorrectionLevel ||
      oldDelegate.moduleShape != moduleShape ||
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.margin != margin;
}
