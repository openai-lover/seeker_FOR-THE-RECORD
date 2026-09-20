import 'dart:io';

import 'package:bs58/bs58.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:seeker_workroom/config.dart';
import 'package:seeker_workroom/data/remote.dart';
import 'package:seeker_workroom/data/repository.dart';
import 'package:seeker_workroom/domain/controller.dart';
import 'package:seeker_workroom/platform/native.dart';

// Only run on a dedicated emulator with the official Solana Mobile mock wallet.
// This exercises real Android/MWA IPC, not physical Seeker/Seed Vault hardware.
// The wallet generates an unfunded disposable key; never import a user's key.
class _RecordingNative extends NativePlatform {
  final calls = <String>[];

  @override
  Future<Map<String, dynamic>> wallet(
    String method, [
    Map<String, dynamic> args = const {},
  ]) {
    calls.add(method);
    if (method != 'walletConnect' && method != 'walletDisconnect') {
      throw StateError('Authorization test must never request signing');
    }
    return super.wallet(method, args);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const enabled = bool.fromEnvironment('MOCK_WALLET_TEST');

  testWidgets(
    'official mock wallet: approve, disconnect, decline; no signing or Firebase',
    (tester) async {
      expect(AppConfig.configured, isFalse);
      final directory = await Directory.systemTemp.createTemp('mock-mwa-test-');
      final repository = await LocalRepository.open(
        databasePath: '${directory.path}/isolated.sqlite',
      );
      final native = _RecordingNative();
      final controller = WorkroomController(repository, native);
      await controller.load();
      final remote = RemoteService(
        native,
        controller,
        directWalletEnabled: true,
      );
      try {
        await remote.initialize();
        expect(remote.directMode, isTrue);
        expect(Firebase.apps, isEmpty);
        debugPrint('MOCK_MWA_STAGE_APPROVE: approve only in the test wallet');
        await remote.connect();
        expect(base58.decode(remote.wallet!), hasLength(32));
        expect(remote.signedIn, isTrue);
        expect(remote.seeker, isFalse);
        expect(remote.paymentsEnabled, isFalse);
        expect(native.calls, ['walletConnect']);
        debugPrint('MOCK_MWA_APPROVAL_PASSED');

        await remote.disconnect();
        expect(remote.wallet, isNull);
        expect(remote.signedIn, isFalse);
        expect(native.calls, ['walletConnect', 'walletDisconnect']);
        debugPrint('MOCK_MWA_DISCONNECT_PASSED');

        debugPrint('MOCK_MWA_STAGE_DECLINE: cancel only in the test wallet');
        await expectLater(
          remote.connect(),
          throwsA(
            isA<PlatformException>().having(
              (error) => error.code,
              'code',
              'wallet-declined',
            ),
          ),
        );
        expect(remote.wallet, isNull);
        expect(remote.signedIn, isFalse);
        expect(Firebase.apps, isEmpty);
        expect(native.calls, [
          'walletConnect',
          'walletDisconnect',
          'walletConnect',
        ]);
        debugPrint('MOCK_MWA_DECLINE_PASSED: no signing requested');
      } finally {
        remote.dispose();
        controller.dispose();
        await repository.database.close();
        await directory.delete(recursive: true);
      }
    },
    skip: !enabled,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
