import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:seeker_workroom/data/remote.dart';
import 'package:seeker_workroom/data/repository.dart';
import 'package:seeker_workroom/domain/controller.dart';
import 'package:seeker_workroom/platform/native.dart';
import 'package:seeker_workroom/ui/app.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('English Android walkthrough uses real SQLite and native clock', (
    tester,
  ) async {
    final dir = await Directory.systemTemp.createTemp('record-demo-');
    final repository = await LocalRepository.open(
      databasePath: '${dir.path}/demo.sqlite',
    );
    final native = NativePlatform();
    final c = WorkroomController(repository, native);
    await c.load();
    final r = RemoteService(native, c);
    await tester.pumpWidget(WorkroomApp(controller: c, remote: r));
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    Future<void> shot(String name) async {
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await binding.takeScreenshot(name);
      await Future<void>.delayed(const Duration(seconds: 3));
    }

    Future<void> tap(String text) async {
      await tester.ensureVisible(find.text(text).first);
      await tester.tap(find.text(text).first);
      await tester.pumpAndSettle();
    }

    await shot('01-home-en');
    await tap('Create my project');
    await tester.enterText(
      find.byType(TextField).at(0),
      'Ship a thoughtful app',
    );
    await tester.enterText(
      find.byType(TextField).at(1),
      'Make the next step easy to remember',
    );
    await shot('02-project-en');
    await tap('Create book');
    await tester.enterText(
      find.byType(TextField).first,
      'Make the first screen easier to use',
    );
    await shot('03-intention-en');
    await tap('Start focusing');
    await shot('04-focus-en');
    await tap('Finish here');
    await tester.enterText(
      find.byType(TextField).at(0),
      'The next step is now visible from the home screen.',
    );
    await tester.enterText(
      find.byType(TextField).at(1),
      'Test the same flow with large text',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await shot('05-outcome-en');
    await tap('Save in my project book');
    await shot('06-returning-en');
    await tap('Journal');
    await shot('07-journal-en');
    await tap('Trade journal');
    await shot('08-wallet-preview-en');
    // The dedicated emulator has no wallet installed: exercise the real native
    // failure path without authorizing an account or moving assets.
    await tap('Connect Seeker wallet');
    for (var i = 0; i < 20 && find.byType(SnackBar).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    expect(
      find.text(
        'No MWA compatible wallet was found. Set up Seed Vault Wallet on your Seeker.',
      ),
      findsOneWidget,
    );
    expect(r.signedIn, isFalse);
    expect(c.state.saved.length, 1);
    ScaffoldMessenger.of(
      tester.element(find.byType(SnackBar)),
    ).hideCurrentSnackBar();
    await tester.pumpAndSettle();
    await tap('Settings');
    await shot('09-settings-en');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await shot('10-languages');
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();
    await tap('Wallet and Seeker');
    await shot('11-read-only-wallet-en');
    expect(
      c.state.saved.single.nextAction,
      'Test the same flow with large text',
    );
    await tester.pumpWidget(const SizedBox());
    r.dispose();
    c.dispose();
    await repository.database.close();
    final reopened = await LocalRepository.open(
      databasePath: '${dir.path}/demo.sqlite',
    );
    expect(
      (await reopened.read()).saved.single.outcome,
      'The next step is now visible from the home screen.',
    );
    await reopened.database.close();
  });
}
