import 'dart:async';
import 'dart:convert';
import 'package:bs58/bs58.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../domain/controller.dart';
import '../platform/native.dart';
import 'transaction_guard.dart';
import 'direct_activity.dart';
import '../domain/trade_journal.dart';

class ServiceError implements Exception {
  ServiceError(this.code);
  final String code;
  @override
  String toString() => errorText(code);
}

String errorText(String code) => switch (code) {
  'not-configured' ||
  'identity-not-configured' => '공동 작업 연결을 준비 중입니다. 개인 작업실은 지금 사용할 수 있어요.',
  'payments-not-configured' ||
  'price-not-configured' => '아직 판매를 시작하지 않았습니다. 전시 팩을 미리 볼 수 있어요.',
  'sgt-not-owned' => '이 지갑에서 Seeker Genesis Token을 찾지 못했어요. 기본 계정을 확인해 주세요.',
  'sgt-check-unavailable' ||
  'service-unavailable' => '서버에서 확인하지 못했어요. 잠시 후 다시 시도해 주세요. 개인 기록은 안전합니다.',
  'no-wallet' => 'MWA 호환 지갑을 찾지 못했어요. Seeker의 Seed Vault Wallet을 설정해 주세요.',
  'wallet-declined' => '지갑 승인이 취소되었습니다. 전송하지 않은 주문은 다시 확인할 수 있어요.',
  'account-changed' => '선택한 지갑 계정이 바뀌었습니다. 다시 연결해 주세요.',
  'sign-in-required' ||
  'sign-in-expired' ||
  'challenge-expired' ||
  'nonce-used' => '연결 시간이 만료되었어요. 지갑을 다시 연결해 주세요.',
  'room-full' => '이미 두 자리가 찼습니다.',
  'same-sgt' => '같은 SGT로 두 자리에 앉을 수 없습니다.',
  'invite-invalid-or-expired' ||
  'room-expired' => '초대가 만료되었거나 코드가 올바르지 않아요. 새 초대를 받아 주세요.',
  'active-room-exists' => '진행 중인 공동 작업실이 있어요. 먼저 기존 방을 열어 주세요.',
  'both-must-be-ready' => '두 사람 모두 준비를 마치면 함께 시작할 수 있어요.',
  'insufficient-skr' => 'SKR 잔액이 부족합니다. 아직 전송하지 않았어요.',
  'insufficient-sol' => '네트워크 수수료를 위한 SOL이 부족합니다.',
  'token-account-missing' => '결제에 필요한 SKR 토큰 계정을 찾지 못했습니다.',
  'order-expired' ||
  'blockhash-expired' => '주문 시간이 만료되었습니다. 기존 거래 확인 후 새 주문을 만들 수 있어요.',
  'already-owned' => '이미 보유한 팩입니다. 구매 복원을 눌러 주세요.',
  'too-many-requests' => '요청이 잠시 많아졌어요. 조금 후 다시 시도해 주세요.',
  'network' => '연결이 끊겼어요. 개인 작업은 계속할 수 있습니다.',
  _ => '요청을 완료하지 못했어요. 다시 확인해 주세요. ($code)',
};

class RemoteService extends ChangeNotifier {
  RemoteService(
    this.native,
    this.local, {
    bool? directWalletEnabled,
    DirectActivityClient? activityClient,
  }) : _directWalletEnabled = directWalletEnabled ?? AppConfig.directWallet,
       directActivity = activityClient ?? DirectActivityClient();
  final bool _directWalletEnabled;
  final DirectActivityClient directActivity;
  bool get directMode => !AppConfig.configured && _directWalletEnabled;
  bool get cloudAvailable => AppConfig.configured;
  final NativePlatform native;
  final WorkroomController local;
  bool initialized = false,
      owned = false,
      paymentsEnabled = false,
      offline = false;
  String? wallet, sgtMint, setupError;
  int? sgtCheckedAt;
  Map<String, dynamic>? room;
  int? serverAnchorMs, localAnchorMs;
  int _roomGeneration = 0, _roomRequestGeneration = 0;
  int _accountGeneration = 0;
  bool _disposed = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;
  String? get uid => directMode
      ? wallet
      : initialized
      ? FirebaseAuth.instance.currentUser?.uid
      : null;
  bool get signedIn => uid != null;
  bool get onlineAvailable =>
      AppConfig.configured ||
      (directMode && AppConfig.identityUri.startsWith('https://'));
  bool get seeker =>
      sgtMint != null &&
      sgtCheckedAt != null &&
      DateTime.now().millisecondsSinceEpoch - sgtCheckedAt! < 3600000;
  List<WalletActivity> activities = [];
  bool activityLoading = false, activityLoaded = false;
  String? activityError, activityCursor;
  int _activityGeneration = 0;
  void clearActivity() {
    _activityGeneration++;
    activities = [];
    activityLoading = false;
    activityLoaded = false;
    activityError = null;
    activityCursor = null;
    notifyListeners();
  }

  Future<void> loadActivity({bool more = false}) async {
    if (activityLoading) return;
    if (!signedIn || wallet == null) {
      activityError = 'sign-in-required';
      notifyListeners();
      return;
    }
    if (more && activityCursor == null) return;
    final account = wallet, user = uid, generation = _activityGeneration;
    activityLoading = true;
    activityError = null;
    notifyListeners();
    try {
      final result = await call('wallet-activity', {
        if (more) 'before': activityCursor,
      }).timeout(const Duration(seconds: 40));
      if (generation != _activityGeneration ||
          account != wallet ||
          user != uid) {
        return;
      }
      if (result['wallet'] != account) throw ServiceError('account-changed');
      final rows = (result['items'] as List)
          .map((e) => WalletActivity.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final merged = {
        for (final a in (more ? activities : <WalletActivity>[]))
          a.signature: a,
        for (final a in rows) a.signature: a,
      };
      activities = merged.values.take(200).toList();
      activityCursor = activities.length >= 200
          ? null
          : result['nextCursor'] as String?;
      activityLoaded = true;
    } catch (e) {
      if (generation == _activityGeneration) {
        activityError = e is ServiceError
            ? e.code
            : e is TimeoutException
            ? 'rpc-timeout'
            : 'parse-unavailable';
      }
    } finally {
      if (generation == _activityGeneration) {
        activityLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> initialize() async {
    if (directMode) {
      initialized = true;
      notifyListeners();
      return;
    }
    if (!AppConfig.configured) return;
    try {
      if (!AppConfig.apiUrl.startsWith('https://') ||
          !AppConfig.identityUri.startsWith('https://')) {
        throw ServiceError('not-configured');
      }
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: AppConfig.firebaseApiKey,
          appId: AppConfig.firebaseAppId,
          messagingSenderId: AppConfig.firebaseSenderId,
          projectId: AppConfig.firebaseProjectId,
        ),
      );
      initialized = true;
      if (signedIn) {
        await profile();
        await currentRoom();
      }
    } catch (_) {
      setupError = '연결 서비스를 불러오지 못했습니다. 개인 작업실은 사용할 수 있어요.';
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> call(
    String action, [
    Map<String, dynamic> body = const {},
    bool authenticated = true,
  ]) async {
    if (directMode) {
      if (action != 'wallet-activity') throw ServiceError('not-configured');
      final address = wallet;
      if (address == null) throw ServiceError('sign-in-required');
      try {
        return await directActivity.load(
          address,
          before: body['before'] as String?,
        );
      } on DirectActivityError catch (e) {
        throw ServiceError(e.code);
      }
    }
    if (!initialized) throw ServiceError('not-configured');
    String? token;
    if (authenticated) {
      token = await FirebaseAuth.instance.currentUser?.getIdToken().timeout(
        const Duration(seconds: 15),
      );
      if (token == null) throw ServiceError('sign-in-required');
    }
    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.apiUrl}/$action'),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 35));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) {
        throw ServiceError(data['error'] ?? 'service-unavailable');
      }
      offline = false;
      return data;
    } on ServiceError {
      rethrow;
    } catch (_) {
      offline = true;
      notifyListeners();
      throw ServiceError('network');
    }
  }

  Future<void> connect() async {
    if (!directMode && !initialized) throw ServiceError('not-configured');
    final generation = ++_accountGeneration;
    void checkCurrent() {
      if (_disposed || generation != _accountGeneration) {
        throw ServiceError('account-changed');
      }
    }

    clearActivity();
    final account = await native
        .wallet('walletConnect')
        .timeout(const Duration(minutes: 2));
    checkCurrent();
    final publicKey = account['publicKey'] as String;
    final bytes = base64Decode(publicKey);
    if (bytes.length != 32) throw ServiceError('account-changed');
    final address = base58.encode(bytes);
    if (directMode) {
      directActivity.clearCache();
      wallet = address;
      owned = false;
      paymentsEnabled = false;
      sgtMint = null;
      sgtCheckedAt = null;
      notifyListeners();
      return;
    }
    final challenge = await call('challenge', {'wallet': address}, false);
    checkCurrent();
    final signature = await native
        .wallet('walletSignMessage', {
          'publicKey': publicKey,
          'message': challenge['message'],
        })
        .timeout(const Duration(minutes: 2));
    checkCurrent();
    final response = await call('authenticate', {
      'challengeId': challenge['challengeId'],
      'wallet': address,
      'message': challenge['message'],
      'signature': signature['signature'],
    }, false);
    checkCurrent();
    await FirebaseAuth.instance
        .signInWithCustomToken(response['token'])
        .timeout(const Duration(seconds: 20));
    checkCurrent();
    await restore();
    await currentRoom();
    notifyListeners();
  }

  Future<void> profile() async {
    if (directMode) return;
    final user = uid, generation = _accountGeneration;
    final data = await call('profile');
    if (_disposed || user != uid || generation != _accountGeneration) return;
    if (wallet != data['wallet']) clearActivity();
    wallet = data['wallet'];
    owned = data['entitlement'] == true;
    sgtMint = data['sgtMint'];
    sgtCheckedAt = data['sgtCheckedAt'];
    paymentsEnabled = data['paymentsEnabled'] == true;
    notifyListeners();
  }

  Future<void> verifySeeker() async {
    final user = uid, generation = _accountGeneration;
    final data = await call('verify-seeker');
    if (_disposed || user != uid || generation != _accountGeneration) return;
    sgtMint = data['sgtMint'];
    sgtCheckedAt = data['checkedAt'];
    notifyListeners();
    if (sgtMint == null) throw ServiceError('sgt-not-owned');
  }

  Future<void> disconnect() async {
    directActivity.clearCache();
    final generation = ++_accountGeneration;
    _roomGeneration++;
    _roomRequestGeneration++;
    final subscription = _subscription;
    _subscription = null;
    room = null;
    serverAnchorMs = null;
    localAnchorMs = null;
    wallet = null;
    owned = false;
    sgtMint = null;
    sgtCheckedAt = null;
    clearActivity();
    await subscription?.cancel();
    if (_disposed || generation != _accountGeneration) return;
    try {
      await native
          .wallet('walletDisconnect')
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      /* Local disconnect must remain possible without a wallet. */
    }
    if (_disposed || generation != _accountGeneration) return;
    if (initialized && !directMode) await FirebaseAuth.instance.signOut();
    if (_disposed || generation != _accountGeneration) return;
    notifyListeners();
  }

  Future<void> _setRoom(Map<String, dynamic> data) async {
    final generation = ++_roomGeneration, user = uid;
    final sample = await native.clock();
    if (_disposed || generation != _roomGeneration || user != uid) return;
    final previous = _subscription;
    _subscription = null;
    await previous?.cancel();
    if (_disposed || generation != _roomGeneration || user != uid) return;
    serverAnchorMs = data['serverNow'];
    localAnchorMs = sample.elapsedMs;
    room = Map<String, dynamic>.from(data);
    final roomId = room!['roomId'] as String;
    _subscription = FirebaseFirestore.instance
        .doc('rooms/$roomId')
        .snapshots(includeMetadataChanges: true)
        .listen(
          (snapshot) {
            if (_disposed || generation != _roomGeneration || user != uid) {
              return;
            }
            final value = snapshot.data();
            if (value == null) {
              room = null;
              notifyListeners();
              return;
            }
            final changed = room?['startAt'] != value['startAt'];
            room = {...data, ...?room, ...value};
            offline = snapshot.metadata.isFromCache;
            notifyListeners();
            if (changed && value['startAt'] != null) {
              unawaited(
                currentRoom().catchError((_) {
                  offline = true;
                  notifyListeners();
                }),
              );
            }
          },
          onError: (_) {
            if (_disposed || generation != _roomGeneration || user != uid) {
              return;
            }
            offline = true;
            notifyListeners();
          },
        );
    notifyListeners();
  }

  Future<void> currentRoom() async {
    if (directMode) return;
    if (!signedIn) return;
    final request = ++_roomRequestGeneration, user = uid;
    await syncPendingFinish();
    final data = await call('room-current');
    if (_disposed || request != _roomRequestGeneration || user != uid) return;
    if (data['room'] != null) {
      await _setRoom({
        ...Map<String, dynamic>.from(data['room']),
        'serverNow': data['serverNow'],
      });
    } else {
      _roomGeneration++;
      final subscription = _subscription;
      _subscription = null;
      room = null;
      serverAnchorMs = null;
      localAnchorMs = null;
      await subscription?.cancel();
      notifyListeners();
    }
  }

  bool _syncingFinish = false;
  Future<void> syncPendingFinish() async {
    final roomId = local.state.settings['pendingRoomFinish'];
    if (!signedIn || roomId == null || _syncingFinish) return;
    _syncingFinish = true;
    try {
      await call('room-action', {'roomId': roomId, 'action': 'finish'});
      await local.setting('pendingRoomFinish', null);
    } on ServiceError catch (e) {
      if (['room-closed', 'room-missing', 'not-a-member'].contains(e.code)) {
        await local.setting('pendingRoomFinish', null);
      }
    } finally {
      _syncingFinish = false;
    }
  }

  Future<void> createRoom(String category) async {
    final request = ++_roomRequestGeneration, user = uid;
    final data = await call('room-create', {'category': category});
    if (_disposed || request != _roomRequestGeneration || user != uid) return;
    await _setRoom(data);
  }

  Future<void> join(String code, String category) async {
    final request = ++_roomRequestGeneration, user = uid;
    final data = await call('room-join', {
      'code': code.trim().toUpperCase(),
      'category': category,
    });
    if (_disposed || request != _roomRequestGeneration || user != uid) return;
    await _setRoom(data);
  }

  Future<void> roomAction(String action) async {
    final roomId = room?['roomId'], user = uid;
    if (roomId == null) throw ServiceError('room-missing');
    final data = await call('room-action', {
      'roomId': roomId,
      'action': action,
    });
    final c = await native.clock();
    if (_disposed || user != uid || room?['roomId'] != roomId) return;
    serverAnchorMs = data['serverNow'];
    localAnchorMs = c.elapsedMs;
    room = {...room!, ...data};
    notifyListeners();
  }

  Future<int> roomElapsed() async {
    if (serverAnchorMs == null ||
        localAnchorMs == null ||
        room?['startAt'] == null) {
      throw ServiceError('network');
    }
    final c = await native.clock();
    return serverAnchorMs! +
        c.elapsedMs -
        localAnchorMs! -
        (room!['startAt'] as int);
  }

  Future<Map<String, dynamic>> quote() async {
    final user = uid;
    final data = await call('order-create');
    await local.mutate((s) {
      if (user != uid || data['wallet'] != wallet) {
        throw ServiceError('account-changed');
      }
      s.pendingOrder = data;
    });
    return data;
  }

  Future<void> signOrder() async {
    final order = local.state.pendingOrder!;
    if (order['wallet'] != wallet) throw ServiceError('account-changed');
    validateOrderTransaction(order);
    final signed = await native.wallet('walletSignTransaction', {
      'transaction': order['transactionBase64'],
      'publicKey': base64Encode(base58.decode(wallet!)),
    });
    // Signed bytes are durably saved before any submission. A lost MWA reply cannot have transferred funds.
    await local.mutate((s) {
      if (s.pendingOrder?['orderId'] != order['orderId'] ||
          order['wallet'] != wallet) {
        throw ServiceError('account-changed');
      }
      s.pendingOrder = {
        ...order,
        'signedTransaction': signed['signedTransaction'],
      };
    });
    await submitOrder();
  }

  Future<void> submitOrder() async {
    final order = local.state.pendingOrder!;
    if (order['wallet'] != wallet) throw ServiceError('account-changed');
    final response = await call('order-submit', {
      'orderId': order['orderId'],
      'signedTransaction': order['signedTransaction'],
    });
    await _orderResult(response, order['orderId'] as String);
  }

  Future<void> checkOrder() async {
    final order = local.state.pendingOrder;
    if (order == null) {
      await restore();
      return;
    }
    if (order['wallet'] != wallet) throw ServiceError('account-changed');
    await _orderResult(
      await call('order-check', {'orderId': order['orderId']}),
      order['orderId'] as String,
    );
  }

  Future<void> _orderResult(Map<String, dynamic> data, String orderId) async {
    if (local.state.pendingOrder?['orderId'] != orderId ||
        local.state.pendingOrder?['wallet'] != wallet) {
      return;
    }
    if (data['status'] == 'paid') {
      await local.mutate((s) {
        if (s.pendingOrder?['orderId'] == orderId) s.pendingOrder = null;
      });
      await profile();
    } else if (data['status'] == 'expired') {
      await local.mutate((s) {
        if (s.pendingOrder?['orderId'] == orderId) s.pendingOrder = null;
      });
      throw ServiceError(data['reason'] ?? 'order-expired');
    } else {
      await local.mutate((s) {
        if (s.pendingOrder?['orderId'] == orderId) {
          s.pendingOrder = {...s.pendingOrder!, ...data};
        }
      });
    }
    notifyListeners();
  }

  Future<void> restore() async {
    final user = uid, generation = _accountGeneration;
    await profile();
    if (_disposed || user != uid || generation != _accountGeneration) return;
    final response = await call('order-current');
    if (_disposed || user != uid || generation != _accountGeneration) return;
    if (response['order'] != null) {
      await local.mutate((s) {
        final remote = Map<String, dynamic>.from(response['order']);
        s.pendingOrder = {
          ...remote,
          if (s.pendingOrder?['orderId'] == remote['orderId'] &&
              s.pendingOrder?['signedTransaction'] != null)
            'signedTransaction': s.pendingOrder!['signedTransaction'],
        };
      });
    } else if (local.state.pendingOrder != null &&
        (owned || local.state.pendingOrder?['wallet'] != wallet)) {
      // A submitted order is recoverable from the server under its original wallet.
      // Unsubmitted bytes cannot have moved funds; do not offer them to another account.
      await local.mutate((s) {
        s.pendingOrder = null;
      });
    }
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    await call('account-delete');
    await disconnect();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    directActivity.close();
    _disposed = true;
    _accountGeneration++;
    _activityGeneration++;
    _roomGeneration++;
    _roomRequestGeneration++;
    _subscription?.cancel();
    super.dispose();
  }
}
