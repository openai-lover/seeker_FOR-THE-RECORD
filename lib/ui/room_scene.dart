import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../domain/models.dart';
import 'design.dart';
import '../l10n/strings.dart';

class RoomScene extends StatelessWidget {
  const RoomScene({
    super.key,
    required this.projects,
    required this.pages,
    this.shared = false,
    this.pack = false,
    this.focus = false,
    this.onTap,
    this.onProject,
    this.onAchievement,
    this.onJournal,
  });
  final List<Project> projects;
  final int pages;
  final bool shared, pack, focus;
  final VoidCallback? onTap, onAchievement, onJournal;
  final ValueChanged<Project>? onProject;
  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    label: tr(
      context,
      '프로젝트 ${projects.length}권, 기록 $pages페이지. 책장은 아래 목록에서 열 수 있습니다.',
      '${projects.length} projects, $pages pages. Open books from the list below.',
    ),
    child: GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1.36,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: LayoutBuilder(
            builder: (context, box) => Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _RoomPainter(projects, pages, shared, pack, focus),
                ),
                if (onProject != null && projects.isNotEmpty)
                  Positioned(
                    left: box.maxWidth * .56,
                    top: box.maxHeight * .03,
                    width: box.maxWidth * .35,
                    height: 64,
                    child: PopupMenuButton<Project>(
                      tooltip: tr(context, '프로젝트 책 열기', 'Open a project book'),
                      onSelected: onProject,
                      itemBuilder: (context) => [
                        for (final project in projects)
                          PopupMenuItem(
                            value: project,
                            child: Text(project.title),
                          ),
                      ],
                      child: Semantics(
                        label: tr(context, '프로젝트 책', 'Project books'),
                        button: true,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                if (onAchievement != null)
                  Positioned(
                    left: box.maxWidth * .71,
                    top: box.maxHeight * .31,
                    child: IconButton(
                      tooltip: tr(context, '성취 진열장', 'Achievements'),
                      onPressed: onAchievement,
                      icon: const Icon(
                        Icons.workspace_premium_outlined,
                        color: brass,
                      ),
                    ),
                  ),
                if (onJournal != null)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 6,
                    child: TextButton.icon(
                      onPressed: onJournal,
                      icon: const Icon(Icons.edit_note, size: 18),
                      label: Text(tr(context, '매매 일지', 'Trade journal')),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _RoomPainter extends CustomPainter {
  _RoomPainter(this.projects, this.pages, this.shared, this.pack, this.focus);
  final List<Project> projects;
  final int pages;
  final bool shared, pack, focus;
  final Paint p = Paint();
  void rect(
    Canvas c,
    double x,
    double y,
    double w,
    double h,
    Color color, [
    double radius = 0,
  ]) {
    p
      ..color = color
      ..style = PaintingStyle.fill;
    if (radius > 0) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w, h),
          Radius.circular(radius),
        ),
        p,
      );
    } else {
      c.drawRect(Rect.fromLTWH(x, y, w, h), p);
    }
  }

  void oval(Canvas c, double x, double y, double w, double h, Color color) {
    p
      ..color = color
      ..style = PaintingStyle.fill;
    c.drawOval(Rect.fromLTWH(x, y, w, h), p);
  }

  void stroke(Canvas c, Offset a, Offset b, Color color, [double width = 1]) {
    p
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    c.drawLine(a, b, p);
    p.style = PaintingStyle.fill;
  }

  void path(Canvas c, List<Offset> points, Color color) {
    final shape = Path()..moveTo(points.first.dx, points.first.dy);
    for (final pt in points.skip(1)) {
      shape.lineTo(pt.dx, pt.dy);
    }
    shape.close();
    p
      ..color = color
      ..style = PaintingStyle.fill;
    c.drawPath(shape, p);
  }

  void book(
    Canvas c,
    double x,
    double y,
    double h,
    double w,
    Color color,
    bool complete,
  ) {
    rect(c, x + 2, y + 2, w, h, const Color(0x22000000), 2);
    rect(c, x, y, w, h, color, 2);
    rect(c, x + 3, y + 3, 1.5, h - 6, const Color(0x22FFFFFF));
    stroke(
      c,
      Offset(x + 4, y + 9),
      Offset(x + w - 3, y + 9),
      const Color(0xFFD9CBA9),
      1.2,
    );
    stroke(
      c,
      Offset(x + 4, y + h - 9),
      Offset(x + w - 3, y + h - 9),
      const Color(0xFFD9CBA9),
      1.2,
    );
    if (complete) {
      rect(c, x + w / 2 - 2, y + 18, 4, 7, const Color(0xFFD9CBA9), 1);
    }
  }

  void lamp(Canvas c, double x, double y, {bool lit = true}) {
    if (lit) {
      path(c, [
        Offset(x - 12, y - 29),
        Offset(x + 16, y - 29),
        Offset(x + 42, y + 20),
        Offset(x - 40, y + 20),
      ], const Color(0x22E9BD62));
    }
    oval(c, x - 17, y + 17, 36, 7, const Color(0xFF394D40));
    stroke(
      c,
      Offset(x, y + 19),
      Offset(x + 1, y - 18),
      const Color(0xFF52644F),
      3,
    );
    stroke(
      c,
      Offset(x + 1, y - 18),
      Offset(x + 17, y - 43),
      const Color(0xFF52644F),
      3,
    );
    oval(c, x + 12, y - 47, 8, 8, const Color(0xFF9C8B60));
    path(c, [
      Offset(x - 4, y - 47),
      Offset(x + 13, y - 50),
      Offset(x + 24, y - 29),
      Offset(x - 15, y - 27),
    ], const Color(0xFF44634E));
    oval(
      c,
      x - 15,
      y - 32,
      39,
      7,
      lit ? const Color(0xFFEAD4A0) : const Color(0xFF71806A),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 400, size.height / 294);
    rect(
      canvas,
      0,
      0,
      400,
      294,
      pack ? const Color(0xFFE9E0CD) : const Color(0xFFEDE8DC),
    );
    rect(
      canvas,
      0,
      0,
      400,
      218,
      pack ? const Color(0xFFE5DEC9) : const Color(0xFFEAE7DA),
    );
    // Warm wall grain is deterministic and stays completely still during focus.
    for (int i = 0; i < 160; i++) {
      final r = math.Random(i * 31);
      oval(
        canvas,
        r.nextDouble() * 400,
        r.nextDouble() * 210,
        1.1,
        .7,
        const Color(0x0A675139),
      );
    }
    rect(canvas, 0, 218, 400, 4, const Color(0xFFC8BEA9));
    for (int i = 0; i < 5; i++) {
      stroke(
        canvas,
        Offset(0, 229 + i * 17),
        Offset(400, 229 + i * 17),
        const Color(0x226A533E),
      );
    }
    // Window, linen blind, hills and soft light.
    rect(canvas, 33, 25, 104, 130, const Color(0x16000000), 7);
    rect(canvas, 29, 21, 104, 130, const Color(0xFFC5BBA5), 5);
    rect(canvas, 35, 27, 92, 116, const Color(0xFFD6DED1), 2);
    oval(canvas, 91, 38, 21, 21, const Color(0xFFF9F1D9));
    path(canvas, [
      const Offset(35, 104),
      const Offset(61, 73),
      const Offset(94, 94),
      const Offset(127, 72),
      const Offset(127, 143),
      const Offset(35, 143),
    ], const Color(0xFFBAC9B4));
    path(canvas, [
      const Offset(35, 124),
      const Offset(78, 103),
      const Offset(106, 116),
      const Offset(127, 106),
      const Offset(127, 143),
      const Offset(35, 143),
    ], const Color(0xFF9FAF95));
    rect(canvas, 78, 26, 5, 116, const Color(0xFFF7F1E4));
    rect(canvas, 35, 86, 92, 4, const Color(0xFFF7F1E4));
    rect(canvas, 28, 19, 106, 22, const Color(0xFFE1D5BC), 2);
    stroke(
      canvas,
      const Offset(132, 25),
      const Offset(132, 80),
      const Color(0xFFB6A889),
    );
    rect(canvas, 23, 144, 117, 8, const Color(0xFFC8B699), 2);
    path(canvas, [
      const Offset(36, 152),
      const Offset(129, 152),
      const Offset(218, 217),
      const Offset(91, 217),
    ], const Color(0x19FFFCDF));
    // Shelf carries one spine per real project, at most eight visible books.
    rect(canvas, 227, 66, 139, 7, const Color(0xFFAB8B65), 2);
    rect(canvas, 238, 73, 5, 9, const Color(0xFFB69B78));
    rect(canvas, 349, 73, 5, 9, const Color(0xFFB69B78));
    final visible = projects.take(8).toList();
    double bx = 234;
    for (int i = 0; i < visible.length; i++) {
      final b = visible[i];
      final height = 31.0 + (i % 3) * 6;
      book(
        canvas,
        bx,
        65 - height,
        height,
        12,
        bookColors[b.color % 6],
        b.completedAt != null,
      );
      bx += 16;
    }
    if (visible.isEmpty) {
      rect(canvas, 241, 57, 38, 7, const Color(0xFFB3A68D), 1);
      rect(canvas, 243, 54, 33, 3, const Color(0xFFF8F3E6), 1);
    }
    // Quiet wall print, not a gamified reward counter.
    rect(canvas, 286, 95, 51, 51, const Color(0xFFAE936C), 2);
    rect(canvas, 290, 99, 43, 43, paper);
    oval(canvas, 301, 107, 17, 17, pack ? brass : const Color(0xFFB4BFA6));
    stroke(
      canvas,
      const Offset(299, 132),
      const Offset(324, 132),
      const Color(0xFFC1B8A0),
    );
    if (pack) {
      rect(canvas, 202, 104, 57, 40, const Color(0xFFAB8B65), 2);
      rect(canvas, 207, 109, 47, 30, paper);
      path(canvas, [
        const Offset(213, 133),
        const Offset(226, 117),
        const Offset(243, 133),
      ], const Color(0xFFA2AF98));
    }
    // Soft rug, chair, desk in slight perspective.
    oval(canvas, 58, 236, 298, 42, const Color(0xFFE0D3B9));
    oval(canvas, 73, 242, 270, 31, const Color(0x0F554534));
    rect(canvas, 105, 215, 8, 59, const Color(0xFF826346), 2);
    rect(canvas, 318, 214, 8, 53, const Color(0xFF826346), 2);
    rect(canvas, 110, 216, 211, 11, const Color(0xFFA3835F));
    path(canvas, [
      const Offset(65, 177),
      const Offset(309, 177),
      const Offset(349, 210),
      const Offset(98, 210),
    ], pack ? const Color(0xFFAC845F) : const Color(0xFFC4A17B));
    path(canvas, [
      const Offset(98, 210),
      const Offset(349, 210),
      const Offset(349, 220),
      const Offset(98, 220),
    ], const Color(0xFFA78158));
    path(canvas, [
      const Offset(65, 177),
      const Offset(98, 210),
      const Offset(98, 220),
      const Offset(65, 187),
    ], const Color(0xFFB28C62));
    for (int i = 0; i < 3; i++) {
      stroke(
        canvas,
        Offset(104, 194 + i * 5),
        Offset(321, 194 + i * 5),
        const Color(0x16815832),
      );
    }
    // An open book: its visible leaves increase only with saved pages.
    final leaves = math.min(5, pages);
    for (int i = leaves; i >= 0; i--) {
      path(canvas, [
        Offset(172, 184 + i * .6),
        Offset(210, 186 + i * .6),
        Offset(224, 203 + i * .6),
        Offset(184, 200 + i * .6),
      ], i == 0 ? paper : const Color(0xFFD9CFBC));
    }
    path(canvas, [
      const Offset(211, 186),
      const Offset(239, 180),
      const Offset(258, 194),
      const Offset(223, 203),
    ], const Color(0xFFF8F3E6));
    stroke(
      canvas,
      const Offset(211, 186),
      const Offset(223, 202),
      const Color(0xFFCABB9D),
    );
    for (int i = 0; i < 3; i++) {
      stroke(
        canvas,
        Offset(183 + i * 2, 189 + i * 3),
        Offset(205 + i * 3, 191 + i * 3),
        const Color(0xFFC5BDA9),
      );
    }
    path(canvas, [
      const Offset(233, 185),
      const Offset(237, 184),
      const Offset(250, 199),
      const Offset(245, 198),
      const Offset(244, 201),
    ], const Color(0xFFAD7659));
    lamp(canvas, 116, 174, lit: true);
    if (shared) {
      lamp(canvas, 295, 174, lit: true);
    } else {
      oval(canvas, 285, 191, 19, 7, const Color(0x33000000));
      rect(canvas, 279, 175, 14, 17, paper, 3);
      oval(canvas, 279, 173, 14, 5, const Color(0xFF745D47));
      p
        ..color = paper
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawOval(const Rect.fromLTWH(290, 178, 8, 10), p);
      p.style = PaintingStyle.fill;
    }
    rect(canvas, 176, 234, 54, 34, const Color(0xFF49634D), 8);
    rect(canvas, 185, 255, 6, 30, const Color(0xFF806E53), 2);
    rect(canvas, 217, 255, 6, 30, const Color(0xFF806E53), 2);
    if (shared) {
      rect(canvas, 260, 238, 45, 28, const Color(0xFF8A8C69), 7);
      rect(canvas, 265, 260, 5, 22, const Color(0xFF806E53));
      rect(canvas, 297, 260, 5, 22, const Color(0xFF806E53));
    }
    // Small living plant, always available.
    rect(canvas, 40, 234, 22, 25, const Color(0xFFB7876B), 3);
    oval(canvas, 38, 230, 26, 7, const Color(0xFFC4997A));
    stroke(
      canvas,
      const Offset(51, 233),
      const Offset(51, 205),
      const Color(0xFF687E58),
      2,
    );
    oval(canvas, 33, 204, 19, 9, const Color(0xFF899971));
    oval(canvas, 50, 199, 18, 10, const Color(0xFF677F58));
    oval(canvas, 40, 190, 12, 16, const Color(0xFF93A07A));
    if (pages > 0) {
      rect(canvas, 150, 211, 27, 13, const Color(0xFFB28C53), 2);
      rect(canvas, 153, 214, 21, 1, const Color(0xFFDED0AE));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RoomPainter old) =>
      old.pages != pages ||
      old.shared != shared ||
      old.pack != pack ||
      old.focus != focus ||
      old.projects.map((p) => '${p.id}:${p.color}:${p.completedAt}').join() !=
          projects.map((p) => '${p.id}:${p.color}:${p.completedAt}').join();
}
