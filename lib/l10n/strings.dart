import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'locale_catalog.dart';

/// Locale is scoped to the widget tree; user-written notes are never translated.
class WorkroomStrings {
  const WorkroomStrings(this.locale);
  final Locale locale;
  static const supportedLanguageCodes = [
    'en',
    'ko',
    'ja',
    'zh',
    'hi',
    'es',
    'pt',
    'fr',
  ];
  static const supportedLocales = [
    Locale('en'),
    Locale('ko'),
    Locale('ja'),
    Locale('zh'),
    Locale('hi'),
    Locale('es'),
    Locale('pt'),
    Locale('fr'),
  ];
  static WorkroomStrings of(BuildContext context) =>
      Localizations.of<WorkroomStrings>(context, WorkroomStrings) ??
      const WorkroomStrings(Locale('en'));
  String choose(String ko, String en) => locale.languageCode == 'ko'
      ? ko
      : translateEnglish(locale.languageCode, en);
  static const delegate = _StringsDelegate();
}

class _StringsDelegate extends LocalizationsDelegate<WorkroomStrings> {
  const _StringsDelegate();
  @override
  bool isSupported(Locale locale) =>
      WorkroomStrings.supportedLanguageCodes.contains(locale.languageCode);
  @override
  Future<WorkroomStrings> load(Locale locale) =>
      SynchronousFuture(WorkroomStrings(locale));
  @override
  bool shouldReload(_StringsDelegate old) => false;
}

String tr(BuildContext context, String ko, String en) =>
    WorkroomStrings.of(context).choose(ko, en);
String activityErrorText(BuildContext context, String code) => switch (code) {
  'rpc-timeout' => tr(
    context,
    '거래 조회 시간이 초과됐어요. 잠시 후 다시 시도해 주세요.',
    'The activity request timed out. Please try again.',
  ),
  'rpc-unavailable' || 'network' => tr(
    context,
    '지갑 활동에 연결할 수 없어요. 개인 기록은 계속 사용할 수 있습니다.',
    'Wallet activity is unavailable. Your personal records still work offline.',
  ),
  'parse-unavailable' => tr(
    context,
    '거래 정보를 안전하게 해석하지 못했어요.',
    'We could not safely interpret this activity.',
  ),
  'account-changed' => tr(
    context,
    '지갑 계정이 바뀌었어요. 다시 연결해 주세요.',
    'The wallet account changed. Please reconnect.',
  ),
  'too-many-requests' => tr(
    context,
    '조회 횟수가 잠시 많아졌어요. 몇 분 후 다시 시도해 주세요.',
    'Too many requests. Try again in a few minutes.',
  ),
  'sign-in-required' || 'sign-in-expired' => tr(
    context,
    '지갑을 다시 연결해 주세요.',
    'Please reconnect your wallet.',
  ),
  'journal-read-failed' => tr(
    context,
    '저장된 일지를 읽지 못했어요. 데이터를 지우지 말고 다시 시도해 주세요.',
    'Your journals could not be read. Retry without deleting your data.',
  ),
  _ => tr(
    context,
    '지금은 연결할 수 없어요. 잠시 후 다시 시도해 주세요.',
    'Unable to connect right now. Please try again.',
  ),
};
