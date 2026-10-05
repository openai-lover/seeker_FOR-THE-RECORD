import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:seeker_workroom/data/direct_activity.dart';
import 'package:seeker_workroom/data/remote.dart';
import 'package:seeker_workroom/data/repository.dart';
import 'package:seeker_workroom/domain/controller.dart';
import 'package:seeker_workroom/domain/trade_journal.dart';
import 'package:seeker_workroom/platform/native.dart';
import 'package:seeker_workroom/ui/app.dart';

// Manual debug evidence harness only. Neither lib/main.dart nor production DB.
// Build/install/capture requires a separate root go and manifest/package checks.
const knownPublicCase8Signature =
    '2vCgWskb1AV9UVvhmv1vuQdh8pdH5tAWyoqzsgXnF5z3ohpT9RALaPFb7tGiN8xCViJb7kdcLgBXWqe3pvGLuSY8';
const isolatedPackage = 'app.workroom.seeker_workroom.integration';
const rpcEndpoint = 'https://api.mainnet-beta.solana.com';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kDebugMode ||
      !const bool.fromEnvironment(
        'FTR_ISOLATED_PUBLIC_CASE8',
        defaultValue: false,
      )) {
    throw StateError(
      'This manual proof requires an explicitly enabled debug build.',
    );
  }
  final databaseRoot = await getDatabasesPath();
  // Fail before RPC/openDatabase if the actual Android storage path is not the
  // exact separate package. This read does not load any production records.
  if (!path.split(databaseRoot).contains(isolatedPackage)) {
    throw StateError(
      'Refusing evidence operations outside the isolated package.',
    );
  }
  runApp(MaterialApp(home: KnownPublicCase8Menu(databaseRoot: databaseRoot)));
}

class FreshPublicCase8 {
  const FreshPublicCase8(this.activity, this.address, this.receipt);
  final WalletActivity activity;
  final String address;
  final Map<String, Object?> receipt;
}

Future<FreshPublicCase8?> fetchKnownPublicCase8(String databaseRoot) async {
  if (!path.split(databaseRoot).contains(isolatedPackage)) {
    throw StateError('Isolated storage required.');
  }
  final session = DateTime.now().toUtc().microsecondsSinceEpoch.toString();
  final folder = Directory(
    path.join(databaseRoot, 'known-public-case8-0512', session),
  );
  await folder.create(recursive: true);
  final request = <String, Object?>{
    'jsonrpc': '2.0',
    'id': 1,
    'method': 'getTransaction',
    'params': [
      knownPublicCase8Signature,
      {
        'encoding': 'jsonParsed',
        'maxSupportedTransactionVersion': 1,
        'commitment': 'finalized',
      },
    ],
  };
  final requestBytes = utf8.encode(jsonEncode(request));
  await File(path.join(folder.path, 'request.json')).writeAsBytes(requestBytes);
  final attempts = <Map<String, Object?>>[];
  Map<String, dynamic>? envelope;
  String? rawSha;
  final client = http.Client();
  try {
    for (var attempt = 1; attempt <= 3; attempt++) {
      final started = DateTime.now().toUtc().toIso8601String();
      rawSha = null;
      int? httpStatus;
      String? error;
      var retry = false;
      String? filename;
      try {
        final response = await client
            .post(
              Uri.parse(rpcEndpoint),
              headers: {'Content-Type': 'application/json'},
              body: requestBytes,
            )
            .timeout(const Duration(seconds: 25));
        httpStatus = response.statusCode;
        filename = 'response-attempt-$attempt.json';
        await File(
          path.join(folder.path, filename),
        ).writeAsBytes(response.bodyBytes);
        rawSha = sha256.convert(response.bodyBytes).toString();
        if (httpStatus == 200) {
          envelope = Map<String, dynamic>.from(
            jsonDecode(response.body) as Map,
          );
        } else {
          error = 'HTTP $httpStatus';
          retry = const [429, 500, 502, 503, 504].contains(httpStatus);
        }
      } on TimeoutException {
        error = 'timeout';
        retry = true;
      } on SocketException {
        error = 'socket';
        retry = true;
      } on http.ClientException {
        error = 'transport';
        retry = true;
      } catch (exception) {
        error = exception.runtimeType.toString();
      }
      attempts.add({
        'attempt': attempt,
        'startedAtUtc': started,
        'finishedAtUtc': DateTime.now().toUtc().toIso8601String(),
        'httpStatus': httpStatus,
        'responseFile': filename,
        'responseSha256': rawSha,
        'error': error,
        'rpcError': envelope?['error'],
        'resultNull': envelope == null ? null : envelope['result'] == null,
      });
      if (!retry || attempt == 3) {
        break;
      }
      await Future<void>.delayed(Duration(seconds: attempt == 1 ? 2 : 4));
    }
  } finally {
    client.close();
  }
  final receipt = <String, Object?>{
    'scope':
        'Fresh read-only RPC retrieval of deliberately selected known historical public case8. Not owner activity, held-out data or a new trade.',
    'appUiVersion': '0.5.12+19',
    'appSource': 'ee650639670c7ab35081a92e3435a185b73a6642',
    'expectedParserSha256':
        '5acb14ea6c56ac658766bf4d3ba5e0199762afc2e7313f997631568083a30760',
    'method': 'getTransaction',
    'endpoint': rpcEndpoint,
    'signature': knownPublicCase8Signature,
    'requestSha256': sha256.convert(requestBytes).toString(),
    'attempts': attempts,
    'freshFetchedAtUtc': DateTime.now().toUtc().toIso8601String(),
    'responseSha256': rawSha,
    'noCachedResponseFallback': true,
    'walletConnection': false,
    'isolatedActualSqlitePath': 'known-public-case8-flow-0512.sqlite',
    'networkAvailableRequired': true,
  };
  FreshPublicCase8? result;
  try {
    if (envelope == null ||
        envelope['error'] != null ||
        envelope['result'] is! Map) {
      receipt['outcome'] = 'Unavailable/null/error; no activity substituted.';
    } else {
      final transaction = Map<String, dynamic>.from(envelope['result'] as Map);
      final txBody = transaction['transaction'] as Map;
      if ((txBody['signatures'] as List).first != knownPublicCase8Signature ||
          transaction['slot'] != 453197269) {
        throw StateError('Unexpected known public transaction identity.');
      }
      final keys = ((txBody['message'] as Map)['accountKeys'] as List)
          .cast<Map>();
      final signer =
          keys.firstWhere((key) => key['signer'] == true)['pubkey'] as String;
      final info = <String, dynamic>{
        'signature': knownPublicCase8Signature,
        'err': (transaction['meta'] as Map)['err'],
        'blockTime': transaction['blockTime'],
        'slot': transaction['slot'],
        'confirmationStatus': 'finalized',
      };
      final activity = normalizeDirectActivity(signer, info, transaction);
      receipt.addAll({
        'version': transaction['version'],
        'slot': transaction['slot'],
        'perspective':
            'First signer from public RPC response, ownership not asserted.',
        'status': activity.status,
        'type': activity.type,
        'issue': activity.issue,
        'canJournal': activity.canJournal,
        'canRecordReason': activity.canRecordReason,
        'input': activity.input?.toJson(),
        'output': activity.output?.toJson(),
      });
      result = FreshPublicCase8(activity, signer, receipt);
    }
  } catch (exception) {
    receipt['outcome'] =
        'Response could not be validated; no fixture fallback.';
    receipt['validationError'] = exception.runtimeType.toString();
  }
  await File(
    path.join(folder.path, 'receipt.json'),
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(receipt));
  debugPrintSynchronously('FTR_FRESH_PUBLIC_CASE8 ${jsonEncode(receipt)}');
  return result;
}

class KnownPublicCase8Menu extends StatefulWidget {
  const KnownPublicCase8Menu({super.key, required this.databaseRoot});
  final String databaseRoot;
  @override
  State<KnownPublicCase8Menu> createState() => _KnownPublicCase8MenuState();
}

class _KnownPublicCase8MenuState extends State<KnownPublicCase8Menu> {
  bool busy = false;
  bool attempted = false;
  FreshPublicCase8? fetched;
  String? error;
  Future<void> fetch() async {
    if (busy || attempted) {
      return;
    }
    setState(() {
      busy = true;
      attempted = true;
      error = null;
    });
    try {
      final result = await fetchKnownPublicCase8(widget.databaseRoot);
      if (!mounted) {
        return;
      }
      setState(() {
        fetched = result;
        error = result == null
            ? 'Null/error retained. No cached fallback.'
            : null;
      });
    } catch (exception) {
      if (mounted) {
        setState(() {
          error = 'Fetch did not complete: ${exception.runtimeType}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('0.5.12 - fresh public historical response'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'ISOLATED DEBUG / REAL RPC READ / KNOWN HISTORICAL CASE\nNo owner wallet, MWA connection, signing or new trade.\nThe existing case8 transaction was deliberately selected; not held-out.',
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: busy || attempted ? null : fetch,
          child: Text(
            busy
                ? 'Fetching exact known signature...'
                : 'Fetch known finalized public case8 once',
          ),
        ),
        if (error != null) Text(error!),
        if (fetched case final result?) ...[
          SelectableText(
            'Fetched UTC: ${result.receipt['freshFetchedAtUtc']}\nRaw SHA256: ${result.receipt['responseSha256']}\n${result.activity.status} / ${result.activity.type}\ncanJournal: ${result.activity.canJournal}\nNo cached response fallback.',
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => launchFreshCase8(result, widget.databaseRoot),
            child: const Text(
              'Open current product UI with this freshly fetched response',
            ),
          ),
        ],
        const SizedBox(height: 20),
        const Text(
          'New isolated SQLite only. Any writing is authored DEMO text, not the public trader\'s reason. The product UI Refresh uses this fetched snapshot; it does not request another signature.',
        ),
      ],
    ),
  );
}

class FreshPublicCase8Remote extends RemoteService {
  FreshPublicCase8Remote(super.native, super.local, this.fetched)
    : super(directWalletEnabled: false) {
    initialized = true;
    wallet = fetched.address;
  }
  final FreshPublicCase8 fetched;
  @override
  bool get directMode => false;
  @override
  bool get onlineAvailable => true;
  @override
  String? get uid => 'FRESH-PUBLIC-CASE8-ISOLATED';
  @override
  Future<void> currentRoom() async {}
  @override
  Future<void> connect() async =>
      throw StateError('No wallet connection in this proof.');
  @override
  Future<Map<String, dynamic>> call(
    String action, [
    Map<String, dynamic> body = const {},
    bool authenticated = true,
  ]) async {
    if (action != 'wallet-activity') {
      throw StateError('This proof exposes only one fetched public activity.');
    }
    return {
      'wallet': wallet,
      'items': [fetched.activity.toJson()],
      'nextCursor': null,
    };
  }
}

Future<void> launchFreshCase8(
  FreshPublicCase8 fetched,
  String databaseRoot,
) async {
  if (!path.split(databaseRoot).contains(isolatedPackage)) {
    throw StateError('Refusing production storage.');
  }
  final repository = await LocalRepository.open(
    databasePath: path.join(
      databaseRoot,
      'known-public-case8-flow-0512.sqlite',
    ),
  );
  final native = NativePlatform();
  final controller = WorkroomController(repository, native);
  await controller.load();
  await controller.setting('roomWelcome', 1);
  await controller.setting('language', 'en');
  runApp(
    Builder(
      builder: (context) => MediaQuery.fromView(
        view: View.of(context),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              ColoredBox(
                color: const Color(0xff263c34),
                child: SafeArea(
                  bottom: false,
                  child: SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Text(
                        '0.5.12 ISOLATED / FRESH RPC, HISTORICAL CASE8 / NO OWNER WALLET\nFetched ${fetched.receipt['freshFetchedAtUtc']} / AUTHORED DEMO NOTES\nIn-app Refresh uses this fetched snapshot; not another RPC request.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: WorkroomApp(
                  controller: controller,
                  remote: FreshPublicCase8Remote(native, controller, fetched),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
