import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seeker_workroom/ui/brand.dart';

void main() {
  Future<void> show(
    WidgetTester tester, {
    bool reduce = false,
    bool enabled = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduce),
          child: RecordLaunch(
            enabled: enabled,
            child: const Scaffold(body: Text('Your journal')),
          ),
        ),
      ),
    );
  }

  testWidgets('intro ends without delaying the already mounted journal', (
    tester,
  ) async {
    await show(tester);
    expect(find.text('Your journal'), findsOneWidget);
    expect(find.byKey(const ValueKey('record-launch')), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('record-launch')), findsNothing);
  });
  testWidgets('intro can be skipped immediately', (tester) async {
    await show(tester);
    await tester.tap(find.byKey(const ValueKey('record-launch')));
    await tester.pump();
    expect(find.byKey(const ValueKey('record-launch')), findsNothing);
    await tester.pumpAndSettle();
  });
  testWidgets('reduced motion bypasses intro', (tester) async {
    await show(tester, reduce: true);
    expect(find.byKey(const ValueKey('record-launch')), findsNothing);
  });
  testWidgets('active sessions bypass intro', (tester) async {
    await show(tester, enabled: false);
    expect(find.byKey(const ValueKey('record-launch')), findsNothing);
  });
}
