import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/database/db_helper.dart';
import '../../core/models/transaction_model.dart';
import '../../core/services/auth_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<TransactionModel> _transactions = [];
  DateTime _selectedMonth = DateTime.now();
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
    final list = await DbHelper.instance.getTransactionsByMonth(
      _selectedMonth.year,
      _selectedMonth.month,
      userId: AuthService.currentUserId,
    );
    if (mounted) setState(() => _transactions = list);
  }

  int get _totalExpense => _transactions.where((t) => t.type == 'expense').fold(0, (s, t) => s + t.amount);
  int get _totalIncome => _transactions.where((t) => t.type == 'income').fold(0, (s, t) => s + t.amount);

  Map<String, int> get _categoryTotals {
    final map = <String, int>{};
    for (final t in _transactions.where((t) => t.type == 'expense')) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  static const _categoryColors = [
    Color(0xFF2E75B6), Color(0xFF1F4E79), Color(0xFF70AD47), Color(0xFFED7D31),
    Color(0xFFFFC000), Color(0xFF7030A0), Color(0xFF00B0F0), Color(0xFFFF0000),
  ];

  @override
  Widget build(BuildContext context) {
    final cats = _categoryTotals;
    final catKeys = cats.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('통계', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1F4E79),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () {
            setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1));
            _load();
          }),
          TextButton(
            onPressed: null,
            child: Text(DateFormat('yyyy.MM').format(_selectedMonth), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () {
            setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1));
            _load();
          }),
        ],
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _SummaryRow(totalExpense: _totalExpense, totalIncome: _totalIncome, fmt: _fmt),
            const SizedBox(height: 16),
            if (cats.isNotEmpty) ...[
              _SectionCard(
                title: '카테고리별 지출',
                child: SizedBox(
                  height: 200,
                  child: PieChart(PieChartData(
                    sections: catKeys.asMap().entries.map((e) {
                      final color = _categoryColors[e.key % _categoryColors.length];
                      final pct = cats[e.value]! / _totalExpense * 100;
                      return PieChartSectionData(
                        value: cats[e.value]!.toDouble(),
                        color: color,
                        title: '${pct.toStringAsFixed(1)}%',
                        radius: 70,
                        titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                  )),
                ),
              ),
              const SizedBox(height: 8),
              _SectionCard(
                title: '',
                child: Column(
                  children: catKeys.asMap().entries.map((e) {
                    final color = _categoryColors[e.key % _categoryColors.length];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(e.value, style: const TextStyle(fontSize: 13))),
                          Text('${_fmt.format(cats[e.value]!)}원', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ] else
              const _EmptyCard(),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final int totalExpense, totalIncome;
  final NumberFormat fmt;

  const _SummaryRow({required this.totalExpense, required this.totalIncome, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SummaryCard(label: '총 지출', amount: totalExpense, color: Colors.red, fmt: fmt)),
        const SizedBox(width: 8),
        Expanded(child: _SummaryCard(label: '총 수입', amount: totalIncome, color: Colors.green, fmt: fmt)),
        const SizedBox(width: 8),
        Expanded(child: _SummaryCard(label: '잔액', amount: totalIncome - totalExpense, color: const Color(0xFF2E75B6), fmt: fmt)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;
  final NumberFormat fmt;

  const _SummaryCard({required this.label, required this.amount, required this.color, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text('${fmt.format(amount.abs())}원', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1F4E79))),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: const Center(child: Text('이번 달 기록이 없어요', style: TextStyle(color: Colors.grey))),
    );
  }
}
