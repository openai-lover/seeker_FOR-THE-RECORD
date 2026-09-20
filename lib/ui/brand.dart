import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import 'design.dart';

/// Original record/bookmark monogram. Vector drawn at every pixel density.
class RecordMark extends StatelessWidget {
  const RecordMark({super.key, this.size = 48, this.progress = 1});
  final double size, progress;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _RecordPainter(progress)),
    ),
  );
}

class _RecordPainter extends CustomPainter {
  const _RecordPainter(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);
    final paint = Paint()..color = green;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 100, 100),
        const Radius.circular(29),
      ),
      paint,
    );
    canvas.save();
    canvas.translate(50, 50);
    canvas.rotate((1 - progress) * -.22);
    canvas.translate(-50, -50);
    paint
      ..color = const Color(0xFFF2FFCE)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(30, 72)
      ..lineTo(30, 29)
      ..lineTo(69, 29)
      ..moveTo(30, 47)
      ..lineTo(59, 47);
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * progress), paint);
    }
    paint
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFF8C68);
    canvas.drawCircle(const Offset(69, 69), 10 * progress, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RecordPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// One entrance, no splash delay, no infinite animation, respects reduced motion.
class RecordHero extends StatefulWidget {
  const RecordHero({super.key, this.compact = false});
  final bool compact;
  @override
  State<RecordHero> createState() => _RecordHeroState();
}

class _RecordHeroState extends State<RecordHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  );
  bool started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      motion.value = 1;
    } else if (!started) {
      motion.forward();
    }
    started = true;
  }

  @override
  void dispose() {
    motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: motion,
    builder: (context, _) {
      final t = Curves.easeOutCubic.transform(motion.value);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RecordMark(
                size: widget.compact ? 40 : 48,
                progress: math.max(.05, t),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'FOR THE RECORD',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    fontSize: widget.compact ? 20 : 22,
                    height: 1.05,
                  ),
                ),
              ),
            ],
          ),
          if (!widget.compact) ...[
            const SizedBox(height: 22),
            Transform.translate(
              offset: Offset(0, 12 * (1 - t)),
              child: Opacity(
                opacity: t,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: green,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.fiber_manual_record,
                            color: Color(0xFFFF8C68),
                            size: 10,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tr(
                                context,
                                '나의 판단, 나의 기록',
                                'YOUR DECISIONS. YOUR RECORD.',
                              ),
                              style: const TextStyle(
                                color: Color(0xFFF2FFCE),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        '“For the record,\nthis is why\nI did it.”',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 33,
                          fontWeight: FontWeight.w800,
                          height: 1.13,
                          letterSpacing: -1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        tr(
                          context,
                          '행동을 남기고, 이유를 기억하세요.',
                          'Keep the action. Remember the why.',
                        ),
                        style: const TextStyle(
                          color: Color(0xFFE0F1E8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            const Text(
              '“For the record, this is why I did it.”',
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ],
        ],
      );
    },
  );
}
