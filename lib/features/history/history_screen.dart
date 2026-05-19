import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/database/db_helper.dart';
import '../../core/models/transaction_model.dart';
import '../../core/services/auth_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<TransactionModel> _transactions = [];
  final _fmt = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    AuthService.refreshNotifier.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    AuthService.refreshNotifier.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final list = await DbHelper.instance.getTransactions(userId: AuthService.currentUserId);
    if (mounted) setState(() => _transactions = list);
  }

  Map<String, List<TransactionModel>> _groupByDate() {
    final map = <String, List<TransactionModel>>{};
    for (final t in _transactions) {
      final key = DateFormat('yyyy-MM-dd').format(t.date);
      map.putIfAbsent(key, () => []).add(t);
    }
    return map;
  }

  Future<void> _delete(TransactionModel t) async {
    await DbHelper.instance.deleteTransaction(t.id!);
    AuthService.notifyRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDate();
    final dates = grouped.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('내역', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1F4E79),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: _transactions.isEmpty
          ? const Center(child: Text('아직 기록이 없어요.\n채팅에서 지출을 입력해보세요!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: dates.length,
                itemBuilder: (_, i) {
                  final date = dates[i];
                  final items = grouped[date]!;
                  final dayTotal = items.fold<int>(0, (sum, t) => t.type == 'expense' ? sum - t.amount : sum + t.amount);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('MM월 dd일 (E)', 'ko').format(DateTime.parse(date)),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F4E79)),
                            ),
                            Text(
                              '${dayTotal >= 0 ? '+' : ''}${_fmt.format(dayTotal)}원',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: dayTotal >= 0 ? Colors.green : Colors.red,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...items.map((t) => _TransactionTile(t: t, fmt: _fmt, onDelete: () => _delete(t))),
                      const SizedBox(height: 4),
                    ],
                  );
                },
              ),
            ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel t;
  final NumberFormat fmt;
  final VoidCallback onDelete;

  const _TransactionTile({required this.t, required this.fmt, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isExpense = t.type == 'expense';
    return Dismissible(
      key: Key(t.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isExpense ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text(_categoryEmoji(t.category), style: const TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.description, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  Text(t.category, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Text(
              '${isExpense ? '-' : '+'}${fmt.format(t.amount)}원',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isExpense ? Colors.red : Colors.green,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryEmoji(String category) {
    const map = {
      '식비': '🍚', '카페': '☕', '교통': '🚌', '쇼핑': '🛍️',
      '편의점': '🏪', '의료': '💊', '문화': '🎬', '통신': '📱',
      '수입': '💰', '기타': '💳',
    };
    return map[category] ?? '💳';
  }
}
