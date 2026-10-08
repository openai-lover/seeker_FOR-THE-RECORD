part of 'app.dart';

/// Local-only entry point: no remote service or active wallet is required.
class _Recall extends StatefulWidget {
  const _Recall({required this.journals});
  final TradeJournalController journals;

  @override
  State<_Recall> createState() => _RecallState();
}

class _RecallState extends State<_Recall> {
  final query = TextEditingController();
  String? wallet;

  List<String> get wallets {
    final result = widget.journals.entries
        .where((e) => RelatedRecords.evidence(e).isNotEmpty)
        .map((e) => e.wallet)
        .toSet()
        .toList();
    result.sort();
    return result;
  }

  @override
  void initState() {
    super.initState();
    widget.journals.addListener(_recordsChanged);
  }

  void _recordsChanged() {
    if (!mounted) return;
    setState(() {
      if (widget.journals.loading ||
          widget.journals.error != null ||
          !wallets.contains(wallet)) {
        wallet = null;
        query.clear();
      }
    });
  }

  @override
  void dispose() {
    widget.journals.removeListener(_recordsChanged);
    query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final savedWallets = wallets;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, '저장한 기록 찾기', 'Recall saved notes')),
      ),
      body: PageBody(
        children: [
          Text(
            tr(
              context,
              '직접 보기는 오프라인으로 가능해요. AI 검색에는 이 기기에 준비된 모델이 필요해요.',
              'Browse offline. AI search needs a model prepared on this device.',
            ),
          ),
          const SizedBox(height: 20),
          if (widget.journals.loading)
            const LinearProgressIndicator()
          else if (widget.journals.error != null) ...[
            Text(activityErrorText(context, widget.journals.error!)),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const ValueKey('recall-retry'),
              onPressed: widget.journals.load,
              child: Text(tr(context, '다시 시도', 'Try again')),
            ),
          ] else if (savedWallets.isEmpty)
            Text(
              tr(
                context,
                '이 기기에 저장한 기록이 아직 없어요.',
                'No saved records on this device yet.',
              ),
            )
          else ...[
            Text(tr(context, '저장된 지갑', 'Saved wallet')),
            DropdownButton<String>(
              key: const ValueKey('recall-wallet'),
              isExpanded: true,
              value: wallet,
              hint: Text(
                tr(context, '저장된 지갑을 선택해 주세요.', 'Choose a saved wallet.'),
              ),
              items: [
                for (final savedWallet in savedWallets)
                  DropdownMenuItem(
                    value: savedWallet,
                    child: Text(savedWallet, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (value) => setState(() {
                // A query and its results belong only to the selected wallet.
                wallet = value;
                query.clear();
              }),
            ),
            if (wallet != null) ...[
              SelectableText(wallet!, style: const TextStyle(color: muted)),
              const SizedBox(height: 20),
              TextField(
                key: const ValueKey('recall-query'),
                controller: query,
                maxLength: 480,
                minLines: 1,
                maxLines: 3,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: tr(
                    context,
                    '어떤 기록을 다시 찾고 싶나요?',
                    'What would you like to recall?',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _RelatedRecordsPanel(
                journals: widget.journals,
                wallet: wallet!,
                currentId: null,
                query: () => query.text,
                initiallyExpanded: true,
              ),
            ],
          ],
        ],
      ),
    );
  }
}
