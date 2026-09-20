import 'dart:async';
import 'package:flutter/material.dart';
import 'data/repository.dart';
import 'data/remote.dart';
import 'domain/controller.dart';
import 'platform/native.dart';
import 'ui/app.dart';
import 'ui/design.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final native = NativePlatform();
  LocalRepository? repository;
  try {
    repository = await LocalRepository.open();
    final controller = WorkroomController(repository, native);
    await controller.load();
    await native.syncLanguage(
      controller.state.settings['language'] as String? ?? 'en',
    );
    final remote = RemoteService(native, controller);
    runApp(WorkroomApp(controller: controller, remote: remote));
    unawaited(remote.initialize());
  } catch (_) {
    runApp(
      MaterialApp(
        theme: workroomTheme(),
        home: Scaffold(
          body: SafeArea(
            child: PageBody(
              children: [
                const SizedBox(height: 80),
                const Icon(Icons.menu_book_rounded, size: 56, color: green),
                const SizedBox(height: 24),
                const Text(
                  'Your records are still safe.',
                  style: TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 16),
                const Text(
                  'We could not open your journal. Your existing data has not been reset. Reopen the app or export a recovery copy.',
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: repository == null
                      ? null
                      : () async {
                          await native.export(await repository!.rawExport());
                        },
                  child: const Text('Export a recovery copy'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
