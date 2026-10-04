import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seeker_workroom/platform/native.dart';
import 'package:seeker_workroom/ui/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(
    () => messenger.setMockMethodCallHandler(NativePlatform.channel, null),
  );
  for (final result in [true, false]) {
    test('native export preserves $result completion', () async {
      messenger.setMockMethodCallHandler(NativePlatform.channel, (call) async {
        expect(call.method, 'export');
        expect(call.arguments, {'content': '{"synthetic":true}'});
        return result;
      });
      expect(await NativePlatform().export('{"synthetic":true}'), result);
    });
  }
  for (final invalid in [null, 'true', 1]) {
    test('native export rejects non-boolean completion $invalid', () async {
      messenger.setMockMethodCallHandler(
        NativePlatform.channel,
        (_) async => invalid,
      );
      await expectLater(
        NativePlatform().export('{}'),
        throwsA(
          isA<PlatformException>().having(
            (e) => e.code,
            'code',
            'export-failed',
          ),
        ),
      );
    });
  }
  Future<void> show(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExportButton(
            native: NativePlatform(),
            content: () => '{"synthetic":true}',
            label: 'Export',
          ),
        ),
      ),
    );
    await tester.tap(find.text('Export'));
    await tester.pump();
  }

  testWidgets('no success before native completion; duplicate taps disabled', (
    tester,
  ) async {
    final pending = Completer<bool>();
    var calls = 0;
    messenger.setMockMethodCallHandler(NativePlatform.channel, (_) {
      calls++;
      return pending.future;
    });
    await show(tester);
    expect(find.text('Export in progress…'), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );
    expect(
      find.text('File saved. Your records remain in the app.'),
      findsNothing,
    );
    expect(calls, 1);
    pending.complete(true);
    await tester.pumpAndSettle();
    expect(
      find.text('File saved. Your records remain in the app.'),
      findsOneWidget,
    );
    expect(find.text('Export'), findsOneWidget);
  });
  testWidgets('cancellation has its own result and permits retry', (
    tester,
  ) async {
    var calls = 0;
    messenger.setMockMethodCallHandler(
      NativePlatform.channel,
      (_) async => ++calls > 1,
    );
    await show(tester);
    await tester.pumpAndSettle();
    expect(
      find.text('Export cancelled. Your records remain in the app.'),
      findsOneWidget,
    );
    expect(
      find.text('File saved. Your records remain in the app.'),
      findsNothing,
    );
    await tester.tap(find.text('Export'));
    await tester.pumpAndSettle();
    expect(
      find.text('File saved. Your records remain in the app.'),
      findsOneWidget,
    );
    expect(calls, 2);
  });
  testWidgets('writer failure is not reported as successful export', (
    tester,
  ) async {
    messenger.setMockMethodCallHandler(
      NativePlatform.channel,
      (_) async => throw PlatformException(code: 'export-failed'),
    );
    await show(tester);
    await tester.pumpAndSettle();
    expect(
      find.text('File saved. Your records remain in the app.'),
      findsNothing,
    );
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Export'), findsOneWidget);
  });
}
