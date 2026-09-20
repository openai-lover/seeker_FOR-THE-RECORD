import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seeker_workroom/l10n/legacy_catalog.dart';
import 'package:seeker_workroom/l10n/locale_catalog.dart';
import 'package:seeker_workroom/l10n/strings.dart';

void main() {
  test('all registered languages have complete bundled catalogues', () {
    expect(WorkroomStrings.supportedLanguageCodes, [
      'en',
      'ko',
      'ja',
      'zh',
      'hi',
      'es',
      'pt',
      'fr',
    ]);
    expect(WorkroomStrings.delegate.isSupported(const Locale('hi')), isTrue);
    expect(WorkroomStrings.delegate.isSupported(const Locale('de')), isFalse);
    for (final message in translatedCatalog.entries) {
      expect(
        message.value,
        hasLength(translationLanguages.length),
        reason: message.key,
      );
      for (final translation in message.value) {
        expect(translation.trim(), isNotEmpty, reason: message.key);
        final placeholders = RegExp(r'\{\d+\}');
        expect(
          placeholders.allMatches(translation).map((m) => m.group(0)).toSet(),
          placeholders.allMatches(message.key).map((m) => m.group(0)).toSet(),
          reason: 'Placeholder parity: ${message.key}',
        );
      }
    }
    for (final english in {
      ...englishCatalog.values,
      ...additionalEnglishCatalog.values,
    }) {
      expect(
        translatedCatalog.containsKey(english),
        isTrue,
        reason: 'No translated catalogue entry for $english',
      );
    }
  });

  test('static bilingual UI messages cannot silently lose locale coverage', () {
    final literal = r"'((?:[^'\\]|\\.)*)'";
    final calls = RegExp('tr\\(\\s*context,\\s*$literal\\s*,\\s*$literal');
    // Both branches need coverage when availability determines the copy.
    final condition = r'[a-zA-Z_][\w.]*\s*\?\s*';
    final conditionalCalls = RegExp(
      'tr\\(\\s*context,\\s*$condition$literal\\s*:\\s*$literal\\s*,\\s*$condition$literal\\s*:\\s*$literal',
    );
    for (final file
        in Directory('lib/ui')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      for (final match in calls.allMatches(file.readAsStringSync())) {
        final english = match
            .group(2)!
            .replaceAll(r'\n', '\n')
            .replaceAll(r"\'", "'");
        if (english.contains(r'$')) continue;
        expect(
          translatedCatalog.containsKey(english),
          isTrue,
          reason: '${file.path}: $english',
        );
      }
      for (final match in conditionalCalls.allMatches(
        file.readAsStringSync(),
      )) {
        for (final group in [3, 4]) {
          final english = match
              .group(group)!
              .replaceAll(r'\n', '\n')
              .replaceAll(r"\'", "'");
          if (english.contains(r'$')) continue;
          expect(
            translatedCatalog.containsKey(english),
            isTrue,
            reason: '${file.path}, conditional branch: $english',
          );
        }
      }
    }
  });

  test('dynamic captions localize without translating embedded user content', () {
    const note = 'My 原文 메모 — Settings {0}\nKeep this exactly.';
    expect(
      translateEnglish('ja', 'Starting intention  $note'),
      '始めたときの目標  $note',
    );
    expect(
      translateEnglish('es', 'Definition of done\n$note'),
      'Criterio de finalización\n$note',
    );
    expect(translateEnglish('hi', '25 min'), '25 मिनट');
    expect(translateEnglish('zh', '2 min 7 s'), '2 分 7 秒');
    expect(translateEnglish('ja', '3 pages'), '3ページ');
    expect(translateEnglish('en', '1 pages'), '1 page');
    expect(translateEnglish('es', '1 pages'), '1 página');
    expect(translateEnglish('hi', '1 pages\n25 मिनट'), '1 पन्ना\n25 मिनट');
    expect(
      translateEnglish('es', 'Confirmed minutes (0–180)'),
      'Minutos confirmados (0–180)',
    );
    expect(
      translateEnglish('fr', '4 moments of progress · 25 min'),
      '4 moments de progrès · 25 min',
    );
    expect(
      normalizeLegacyTemplate('입장 만료 19:35 · 두 자리 한정'),
      'Invitation expires 19:35 · Two seats only',
    );
    expect(
      translateEnglish('pt', normalizeLegacyTemplate('주문 만료 19:35:21')),
      'O pedido expira às 19:35:21',
    );
    expect(translateEnglish('hi', note), note);
    expect(translateEnglish('de', 'Settings'), 'Settings');
    expect(
      translateEnglish(
        'es',
        normalizeLegacyTemplate('요청을 완료하지 못했어요. 다시 확인해 주세요. (rpc-unavailable)'),
      ),
      'No se pudo completar la solicitud. Inténtalo de nuevo. (rpc-unavailable)',
    );
  });

  test(
    'localized text literals have an English and six-language translation',
    () {
      final literal = r"'((?:[^'\\]|\\.)*)'";
      final calls = RegExp(
        '(?:LocalizedText\\(|uiText\\(\\s*context,|Eyebrow\\(|QuietTag\\()\\s*$literal',
      );
      for (final file
          in Directory('lib/ui')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        for (final match in calls.allMatches(file.readAsStringSync())) {
          final source = match
              .group(1)!
              .replaceAll(r'\n', '\n')
              .replaceAll(r"\'", "'");
          if (source.contains(r'$') ||
              !RegExp(r'[a-zA-Z가-힣]').hasMatch(source)) {
            continue;
          }
          final english =
              additionalEnglishCatalog[source] ??
              englishCatalog[source] ??
              source;
          expect(
            RegExp(r'[가-힣]').hasMatch(english),
            isFalse,
            reason: 'Korean leaked into English: ${file.path}: $source',
          );
          expect(
            translatedCatalog.containsKey(english),
            isTrue,
            reason: '${file.path}: $english',
          );
        }
      }
    },
  );

  for (final language in WorkroomStrings.supportedLanguageCodes) {
    testWidgets('$language resolves interface, errors and material controls', (
      tester,
    ) async {
      late BuildContext localizedContext;
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(language),
          supportedLocales: WorkroomStrings.supportedLocales,
          localizationsDelegates: const [
            WorkroomStrings.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) {
              localizedContext = context;
              return const Scaffold(body: LocalizedText('설정'));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final strings = WorkroomStrings.of(localizedContext);
      expect(strings.locale.languageCode, language);
      expect(
        uiText(
          localizedContext,
          'Workroom 0.2.0 · 개발 검증 빌드\n지갑 없는 개인 사용은 지금 가능합니다.',
        ),
        startsWith('FOR THE RECORD 0.3.1'),
        reason: 'Version footer must be current in every locale',
      );
      expect(find.text(strings.choose('설정', 'Settings')), findsOneWidget);
      final translatedError = activityErrorText(
        localizedContext,
        'rpc-timeout',
      );
      expect(translatedError, isNotEmpty);
      if (language != 'ko') {
        expect(RegExp(r'[가-힣]').hasMatch(translatedError), isFalse);
        expect(
          uiText(localizedContext, '초대 코드 만들기'),
          translateEnglish(language, 'Create invitation code'),
        );
      }
      expect(
        MaterialLocalizations.of(localizedContext).okButtonLabel,
        isNotEmpty,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('absence of locale scope defaults to English', (tester) async {
    late WorkroomStrings strings;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) {
            strings = WorkroomStrings.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(strings.locale.languageCode, 'en');
    expect(strings.choose('설정', 'Settings'), 'Settings');
  });
}
