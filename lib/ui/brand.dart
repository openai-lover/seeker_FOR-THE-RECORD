import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import 'design.dart';

/// Original F/bookmark monogram, drawn as vectors at every density.
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
    final paint = Paint()..color = ink;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 100, 100),
        const Radius.circular(27),
      ),
      paint,
    );
    paint
      ..color = paper
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(30, 73)
      ..lineTo(30, 29)
      ..lineTo(70, 29)
      ..moveTo(30, 48)
      ..lineTo(59, 48);
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * progress), paint);
    }
    paint
      ..style = PaintingStyle.fill
      ..color = coral;
    canvas.drawCircle(
      Offset(70, 69 - (1 - progress) * 18),
      10 * progress,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RecordPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class RecordHero extends StatelessWidget {
  const RecordHero({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const RecordMark(size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'FOR THE RECORD',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: -.9,
                fontSize: compact ? 19 : 21,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.fiber_manual_record, size: 8, color: coral),
        ],
      ),
      const SizedBox(height: 12),
      const Text(
        '“For the record, this is why I did it.”',
        style: TextStyle(color: muted, fontSize: 12, height: 1.4),
      ),
    ],
  );
}

/// A cold-start signature, never a loading gate. Tap anywhere to skip.
/// Resuming an active session and reduced motion both bypass it entirely.
class RecordLaunch extends StatefulWidget {
  const RecordLaunch({super.key, required this.child, this.enabled = true});
  final Widget child;
  final bool enabled;
  @override
  State<RecordLaunch> createState() => _RecordLaunchState();
}

class _RecordLaunchState extends State<RecordLaunch>
    with SingleTickerProviderStateMixin {
  late final AnimationController motion =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1300),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => dismissed = true);
        }
      });
  bool started = false, dismissed = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.enabled || MediaQuery.disableAnimationsOf(context)) {
      dismissed = true;
      motion.stop();
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
  Widget build(BuildContext context) => Stack(
    children: [
      ExcludeSemantics(excluding: !dismissed, child: widget.child),
      if (!dismissed)
        Positioned.fill(
          child: Semantics(
            button: true,
            label: tr(context, '인트로 건너뛰기', 'Skip intro'),
            child: GestureDetector(
              key: const ValueKey('record-launch'),
              behavior: HitTestBehavior.opaque,
              onTap: () {
                motion.stop();
                setState(() => dismissed = true);
              },
              child: AnimatedBuilder(
                animation: motion,
                builder: (context, _) {
                  final draw = Curves.easeOutCubic.transform(
                    (motion.value / .65).clamp(0, 1),
                  );
                  final reveal = ((motion.value - .82) / .18).clamp(0.0, 1.0);
                  return Opacity(
                    opacity: 1 - reveal,
                    child: ColoredBox(
                      color: paper,
                      child: SafeArea(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Transform.translate(
                              offset: Offset(0, -24 * reveal),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Transform.rotate(
                                    angle: (1 - draw) * -.12,
                                    child: RecordMark(
                                      size: 92 + 10 * (1 - draw),
                                      progress: math.max(.01, draw),
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  Opacity(
                                    opacity: draw,
                                    child: const Text(
                                      'FOR THE\nRECORD',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 34,
                                        fontWeight: FontWeight.w900,
                                        height: .98,
                                        letterSpacing: -1.8,
                                        color: ink,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Opacity(
                                    opacity: draw,
                                    child: const Text(
                                      '“For the record,\nthis is why I did it.”',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.5,
                                        color: muted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
    ],
  );
}
