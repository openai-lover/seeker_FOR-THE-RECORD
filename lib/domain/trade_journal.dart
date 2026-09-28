/// Server-normalized, immutable chain facts. Personal notes never travel with RPC calls.
class ActivityAsset {
  const ActivityAsset({
    required this.mint,
    required this.symbol,
    required this.amount,
  });
  final String mint, symbol, amount;
  factory ActivityAsset.fromJson(Map<String, dynamic> j) => ActivityAsset(
    mint: j['mint'] as String,
    symbol: j['symbol'] as String,
    amount: j['amount'] as String,
  );
  Map<String, dynamic> toJson() => {
    'mint': mint,
    'symbol': symbol,
    'amount': amount,
  };
}

class WalletActivity {
  const WalletActivity({
    required this.id,
    required this.signature,
    required this.status,
    required this.type,
    this.blockTime,
    this.source,
    this.fee,
    this.input,
    this.output,
    this.issue,
  });
  final String id, signature, status, type;
  final int? blockTime;
  final String? source, fee, issue;
  final ActivityAsset? input, output;
  bool get canJournal =>
      status == 'success' && type == 'swap' && input != null && output != null;
  String get explorerUrl => 'https://explorer.solana.com/tx/$signature';
  factory WalletActivity.fromJson(Map<String, dynamic> j) => WalletActivity(
    id: j['id'] as String,
    signature: j['signature'] as String,
    status: j['status'] as String,
    type: j['type'] as String,
    blockTime: j['blockTime'] as int?,
    source: j['source'] as String?,
    fee: j['fee'] as String?,
    issue: j['issue'] as String?,
    input: j['input'] == null
        ? null
        : ActivityAsset.fromJson(Map<String, dynamic>.from(j['input'])),
    output: j['output'] == null
        ? null
        : ActivityAsset.fromJson(Map<String, dynamic>.from(j['output'])),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'signature': signature,
    'blockTime': blockTime,
    'status': status,
    'type': type,
    'source': source,
    'fee': fee,
    'input': input?.toJson(),
    'output': output?.toJson(),
    'issue': issue,
  };
}

class TradeJournalEntry {
  static const _unchanged = Object();
  const TradeJournalEntry({
    required this.id,
    required this.wallet,
    required this.activity,
    required this.createdAt,
    required this.updatedAt,
    this.projectId,
    this.reason = '',
    this.plan = '',
    this.emotion = '',
    this.review = '',
    this.nextAction = '',
    this.originalReason,
    this.originalPlan,
    this.baselineSavedAt,
    this.reviewDueAt,
    this.reviewedAt,
    this.decisionRule = '',
    this.ruleSavedAt,
    this.assistantSelection,
  });
  final String id, wallet;
  final WalletActivity activity;
  final int createdAt, updatedAt;
  final String? projectId;
  final String reason, plan, emotion, review, nextAction;
  final String? originalReason, originalPlan;
  final int? baselineSavedAt, reviewDueAt, reviewedAt, ruleSavedAt;
  final String decisionRule;
  final Map<String, dynamic>? assistantSelection;
  bool isDue(int now) =>
      reviewDueAt != null && reviewDueAt! <= now && reviewedAt == null;
  String get signature => activity.signature;
  Map<String, dynamic> get notes => {
    'projectId': projectId,
    'reason': reason,
    'plan': plan,
    'emotion': emotion,
    'review': review,
    'nextAction': nextAction,
    'originalReason': originalReason,
    'originalPlan': originalPlan,
    'baselineSavedAt': baselineSavedAt,
    'reviewDueAt': reviewDueAt,
    'reviewedAt': reviewedAt,
    'decisionRule': decisionRule,
    'ruleSavedAt': ruleSavedAt,
    'assistantSelection': assistantSelection,
  };
  Map<String, dynamic> toJson() => {
    'id': id,
    'wallet': wallet,
    'activity': activity.toJson(),
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    ...notes,
  };
  factory TradeJournalEntry.fromJson(Map<String, dynamic> j) =>
      TradeJournalEntry(
        id: j['id'] as String,
        wallet: j['wallet'] as String,
        activity: WalletActivity.fromJson(
          Map<String, dynamic>.from(j['activity']),
        ),
        createdAt: j['createdAt'] as int,
        updatedAt: j['updatedAt'] as int,
        projectId: j['projectId'] as String?,
        reason: j['reason'] as String? ?? '',
        plan: j['plan'] as String? ?? '',
        emotion: j['emotion'] as String? ?? '',
        review: j['review'] as String? ?? '',
        nextAction: j['nextAction'] as String? ?? '',
        originalReason: j['originalReason'] as String?,
        originalPlan: j['originalPlan'] as String?,
        baselineSavedAt: j['baselineSavedAt'] as int?,
        reviewDueAt: j['reviewDueAt'] as int?,
        reviewedAt: j['reviewedAt'] as int?,
        decisionRule: j['decisionRule'] as String? ?? '',
        ruleSavedAt: j['ruleSavedAt'] as int?,
        assistantSelection: j['assistantSelection'] == null
            ? null
            : Map<String, dynamic>.from(j['assistantSelection']),
      );
  TradeJournalEntry edit({
    Object? projectId = _unchanged,
    String? reason,
    String? plan,
    String? emotion,
    String? review,
    String? nextAction,
    Object? reviewDueAt = _unchanged,
    Object? reviewedAt = _unchanged,
    String? decisionRule,
    Object? ruleSavedAt = _unchanged,
    Object? assistantSelection = _unchanged,
    required int updatedAt,
  }) => TradeJournalEntry(
    id: id,
    wallet: wallet,
    activity: activity,
    createdAt: createdAt,
    updatedAt: updatedAt,
    projectId: identical(projectId, _unchanged)
        ? this.projectId
        : projectId as String?,
    reason: reason ?? this.reason,
    plan: plan ?? this.plan,
    emotion: emotion ?? this.emotion,
    review: review ?? this.review,
    nextAction: nextAction ?? this.nextAction,
    originalReason: originalReason,
    originalPlan: originalPlan,
    baselineSavedAt: baselineSavedAt,
    reviewDueAt: identical(reviewDueAt, _unchanged)
        ? this.reviewDueAt
        : reviewDueAt as int?,
    reviewedAt: identical(reviewedAt, _unchanged)
        ? this.reviewedAt
        : reviewedAt as int?,
    decisionRule: decisionRule ?? this.decisionRule,
    ruleSavedAt: identical(ruleSavedAt, _unchanged)
        ? this.ruleSavedAt
        : ruleSavedAt as int?,
    assistantSelection: identical(assistantSelection, _unchanged)
        ? this.assistantSelection
        : assistantSelection as Map<String, dynamic>?,
  );

  /// Called by storage, not by the editor. Legacy entries capture their last
  /// saved text; this does not pretend to recover a missing earlier revision.
  TradeJournalEntry preserveBaseline(TradeJournalEntry previous) =>
      TradeJournalEntry.fromJson({
        ...toJson(),
        'originalReason': previous.originalReason ?? previous.reason,
        'originalPlan': previous.originalPlan ?? previous.plan,
        'baselineSavedAt': previous.baselineSavedAt ?? previous.updatedAt,
      });
}
