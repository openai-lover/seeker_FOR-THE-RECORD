import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../l10n/legacy_catalog.dart';

const ink = Color(0xFF191F28),
    muted = Color(0xFF667085),
    green = Color(0xFF007F78),
    paper = Color(0xFFFFFFFF),
    cream = Color(0xFFF4F5F7),
    brass = Color(0xFFC74528),
    line = Color(0xFFE5E8EB),
    coral = Color(0xFFFF6B4A),
    lime = Color(0xFFD5F56B);
const bookColors = [
  Color(0xFF466451),
  Color(0xFF97523E),
  Color(0xFF456675),
  Color(0xFF796035),
  Color(0xFF69546D),
  Color(0xFF716858),
];
ThemeData workroomTheme() => ThemeData(
  useMaterial3: true,
  splashFactory: InkRipple.splashFactory,
  fontFamily: 'NotoSansKR',
  scaffoldBackgroundColor: cream,
  colorScheme: ColorScheme.fromSeed(seedColor: green, surface: paper).copyWith(
    primary: green,
    onPrimary: paper,
    secondary: brass,
    onSurface: ink,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w800,
      height: 1.25,
      letterSpacing: -1,
    ),
    headlineMedium: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w800,
      height: 1.3,
      letterSpacing: -.8,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      height: 1.4,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.5,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 1.5),
    bodyMedium: TextStyle(fontSize: 14, height: 1.5),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: cream,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      fontFamily: 'NotoSansKR',
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: ink,
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(48, 54),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(
        fontFamily: 'NotoSansKR',
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(48, 52),
      side: const BorderSide(color: line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: cream,
    contentPadding: const EdgeInsets.all(18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: green, width: 1.5),
    ),
  ),
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: paper,
    indicatorColor: Color(0xFFDFF3EF),
    labelTextStyle: WidgetStatePropertyAll(
      TextStyle(
        fontFamily: 'NotoSansKR',
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  ),
  dividerTheme: const DividerThemeData(color: line, space: 28),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: ink,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  ),
);

class PaperCard extends StatelessWidget {
  const PaperCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = paper,
    this.onTap,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: color,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(padding: padding, child: child),
    ),
  );
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = muted});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Text(
    uiText(context, text),
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: .3,
      color: color,
    ),
  );
}

class QuietTag extends StatelessWidget {
  const QuietTag(
    this.text, {
    super.key,
    this.icon = Icons.circle_outlined,
    this.localize = true,
  });
  final String text;
  final IconData icon;
  final bool localize;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: paper,
      border: Border.all(color: line),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: green),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            localize ? uiText(context, text) : text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: muted),
          ),
        ),
      ],
    ),
  );
}

class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(24, 16, 24, 32),
  });
  final List<Widget> children;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    ),
  );
}

String minutesLabel(BuildContext context, int sec) => sec < 60
    ? tr(context, '$sec초', '$sec s')
    : tr(
        context,
        '${sec ~/ 60}분${sec % 60 == 0 ? '' : ' ${sec % 60}초'}',
        '${sec ~/ 60} min${sec % 60 == 0 ? '' : ' ${sec % 60} s'}',
      );
String dateLabel(BuildContext context, int ms) {
  final date = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
  return '${MaterialLocalizations.of(context).formatMediumDate(date)} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

String resultLabel(int index) => ['해냈어요', '조금 나아갔어요', '막힌 곳을 찾았어요'][index];
