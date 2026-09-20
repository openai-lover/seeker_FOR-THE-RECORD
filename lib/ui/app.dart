import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../config.dart';
import '../l10n/strings.dart';
import '../l10n/legacy_catalog.dart';
import '../domain/trade_journal.dart';
import 'package:uuid/uuid.dart';
import '../data/remote.dart';
import '../domain/controller.dart';
import '../domain/models.dart';
import 'design.dart';
import 'brand.dart';
import 'room_scene.dart';

part 'home.dart';
part 'focus.dart';
part 'books.dart';
part 'settings.dart';
part 'shared.dart';
part 'trade_journal.dart';

Future<bool> perform(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
}) async {
  try {
    await action();
    if (context.mounted && success != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(uiText(context, success))));
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      final message = e is PlatformException
          ? errorText(e.code)
          : e
                .toString()
                .replaceFirst('Bad state: ', '')
                .replaceFirst('Invalid argument(s): ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ServiceError &&
                    [
                      'rpc-timeout',
                      'rpc-unavailable',
                      'parse-unavailable',
                    ].contains(e.code)
                ? activityErrorText(context, e.code)
                : (uiText(context, message) == message &&
                          RegExp(r'[가-힣]').hasMatch(message)
                      ? tr(
                          context,
                          message,
                          'Unable to complete this action. Please try again.',
                        )
                      : uiText(context, message)),
          ),
        ),
      );
    }
    return false;
  }
}

Future<bool> confirm(
  BuildContext context,
  String title,
  String body, {
  String action = '삭제',
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(uiText(context, title)),
        content: Text(uiText(context, body)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const LocalizedText('돌아가기'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(uiText(context, action)),
          ),
        ],
      ),
    ) ??
    false;
void openPage(BuildContext context, Widget child) =>
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => child));

class ActionButton extends StatefulWidget {
  const ActionButton({
    super.key,
    required this.label,
    required this.action,
    this.icon = Icons.arrow_forward_rounded,
    this.outlined = false,
  });
  final String label;
  final Future<void> Function()? action;
  final IconData icon;
  final bool outlined;
  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  bool busy = false;
  @override
  Widget build(BuildContext context) {
    final onPressed = widget.action == null || busy
        ? null
        : () async {
            setState(() => busy = true);
            await perform(context, widget.action!);
            if (mounted) setState(() => busy = false);
          };
    final icon = busy
        ? const Icon(Icons.hourglass_empty_rounded, size: 18)
        : Icon(widget.icon, size: 18);
    return widget.outlined
        ? OutlinedButton.icon(
            onPressed: onPressed,
            icon: icon,
            label: Text(uiText(context, widget.label)),
          )
        : FilledButton.icon(
            onPressed: onPressed,
            icon: icon,
            label: Text(uiText(context, widget.label)),
          );
  }
}

class WorkroomApp extends StatefulWidget {
  const WorkroomApp({
    super.key,
    required this.controller,
    required this.remote,
  });
  final WorkroomController controller;
  final RemoteService remote;
  @override
  State<WorkroomApp> createState() => _WorkroomAppState();
}

class _WorkroomAppState extends State<WorkroomApp> with WidgetsBindingObserver {
  Timer? ticker;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tick();
  }

  void _tick() {
    ticker?.cancel();
    ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (widget.controller.state.active != null) {
        unawaited(widget.controller.refresh().catchError((_) {}));
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _tick();
      unawaited(widget.controller.refresh().catchError((_) {}));
      if (widget.remote.signedIn) {
        unawaited(widget.remote.currentRoom().catchError((_) {}));
      }
    } else {
      ticker?.cancel();
    }
  }

  @override
  void dispose() {
    ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) => MaterialApp(
      title: AppConfig.name,
      debugShowCheckedModeBanner: false,
      theme: workroomTheme(),
      locale: Locale(
        WorkroomStrings.supportedLanguageCodes.contains(
              widget.controller.state.settings['language'],
            )
            ? widget.controller.state.settings['language'] as String
            : 'en',
      ),
      supportedLocales: WorkroomStrings.supportedLocales,
      localizationsDelegates: const [
        WorkroomStrings.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations:
              widget.controller.state.settings['reduceMotion'] == true ||
              MediaQuery.of(context).disableAnimations,
        ),
        child: child!,
      ),
      home: _Shell(c: widget.controller, r: widget.remote),
    ),
  );
}

class _Shell extends StatefulWidget {
  const _Shell({required this.c, required this.r});
  final WorkroomController c;
  final RemoteService r;
  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int tab = 0;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([widget.c, widget.r, widget.c.journals]),
    builder: (context, _) => Scaffold(
      body: SafeArea(
        child: switch (tab) {
          0 => _Home(
            c: widget.c,
            r: widget.r,
            onBooks: () => setState(() => tab = 1),
          ),
          1 => _Records(c: widget.c, r: widget.r),
          _ => _Settings(c: widget.c, r: widget.r),
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.chair_outlined),
            selectedIcon: Icon(Icons.chair),
            label: uiText(context, '작업실'),
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories),
            label: uiText(context, '기록'),
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_rounded),
            label: uiText(context, '설정'),
          ),
        ],
      ),
    ),
  );
}
