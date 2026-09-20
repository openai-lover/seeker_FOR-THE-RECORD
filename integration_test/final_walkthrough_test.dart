import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:seeker_workroom/data/remote.dart';
import 'package:seeker_workroom/data/repository.dart';
import 'package:seeker_workroom/domain/controller.dart';
import 'package:seeker_workroom/platform/native.dart';
import 'package:seeker_workroom/ui/app.dart';
import 'package:seeker_workroom/domain/trade_journal.dart';

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
    await tap('Workroom');
    await tap('Continue from your bookmark');
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      'Test the same flow with large text',
    );
    await shot('12-return-next-step-en');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tap('Journal');
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
    await binding.takeScreenshot('22-no-wallet-error-en');
    await Future<void>.delayed(const Duration(seconds: 3));
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
    final fixtureController = WorkroomController(reopened, native);
    await fixtureController.load();
    final fixture = _SampleRemote(native, fixtureController);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: [
            Container(
              color: const Color(0xFFFFE9A7),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: const Text(
                'SAMPLE DATA · UI DEMONSTRATION · NOT A LIVE TRADE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF191F28),
                ),
              ),
            ),
            Expanded(
              child: WorkroomApp(
                controller: fixtureController,
                remote: fixture,
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tap('Open trade journal');
    await shot('13-sample-trade-en');
    await tap('Write reflection');
    await tester.enterText(
      find.byType(TextField).first,
      'I wanted to test a small position after reviewing the project.',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await shot('14-sample-reason-en');
    await tap('Next');
    await tester.enterText(
      find.byType(TextField).first,
      'Keep the position small. Review the assumptions tomorrow.',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await shot('15-sample-plan-en');
    await tap('Next');
    await tap('Calm');
    await shot('16-sample-emotion-en');
    await tap('Next');
    await tester.enterText(
      find.byType(TextField).first,
      'Check whether the original reason still holds.',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await shot('17-sample-next-en');
    await tap('Save on this device');
    expect(
      fixtureController.journals.entries.single.nextAction,
      'Check whether the original reason still holds.',
    );
    await shot('18-sample-saved-en');
    await tap('Recorded · Open journal');
    await shot('19-sample-reopen-en');
    await tap('Reflect');
    await tester.enterText(
      find.byType(TextField).first,
      'A clear reason made the next decision easier to review.',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await shot('20-sample-review-en');
    await tap('Save on this device');
    await shot('21-sample-reviewed-en');
    expect(
      fixtureController.journals.entries.single.review,
      'A clear reason made the next decision easier to review.',
    );
    await tester.pumpWidget(const SizedBox());
    fixture.dispose();
    fixtureController.dispose();
    await reopened.database.close();
  });
}

/// Recording-only fixture. It never reaches the release entrypoint or network.
class _SampleRemote extends RemoteService {
  _SampleRemote(super.native, super.local) {
    initialized = true;
    wallet = 'SAMPLE-WALLET-NOT-ON-CHAIN';
    activityLoaded = true;
    activities = [
      const WalletActivity(
        id: 'sample-only',
        signature: 'SAMPLE-NOT-A-TRANSACTION',
        blockTime: 1789876800,
        status: 'success',
        type: 'swap',
        source: 'Jupiter (sample)',
        fee: '0.000005',
        input: ActivityAsset(mint: 'sample-usdc', symbol: 'USDC', amount: '25'),
        output: ActivityAsset(
          mint: 'sample-token',
          symbol: 'TOKEN',
          amount: '10',
        ),
      ),
    ];
  }
  @override
  bool get signedIn => true;
  @override
  String? get uid => wallet;
  @override
  Future<void> loadActivity({bool more = false}) async {}
  @override
  Future<void> currentRoom() async {}
}
