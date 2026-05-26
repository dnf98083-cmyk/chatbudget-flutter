import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  Map<String, int> _budgets = {};
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
      _selectedMonth.year, _selectedMonth.month,
      userId: AuthService.currentUserId,
    );
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('budgets_${AuthService.currentUserId}');
    final budgets = raw != null
        ? (jsonDecode(raw) as Map<String, dynamic>).map((k, v) => MapEntry(k, v as int))
        : <String, int>{};
    if (mounted) setState(() { _transactions = list; _budgets = budgets; });
  }

  Future<void> _saveBudgets(Map<String, int> b) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('budgets_${AuthService.currentUserId}', jsonEncode(b));
    setState(() => _budgets = b);
  }

  int get _totalExpense => _transactions.where((t) => t.type == 'expense').fold(0, (s, t) => s + t.amount);
  int get _totalIncome  => _transactions.where((t) => t.type == 'income').fold(0, (s, t) => s + t.amount);
  int get _balance      => _totalIncome - _totalExpense;

  Map<String, int> get _categoryTotals {
    final map = <String, int>{};
    for (final t in _transactions.where((t) => t.type == 'expense')) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  Map<int, int> get _dailyTotals {
    final map = <int, int>{};
    for (final t in _transactions.where((t) => t.type == 'expense')) {
      final d = t.date.day;
      map[d] = (map[d] ?? 0) + t.amount;
    }
    return map;
  }

  int get _daysLeftInMonth {
    final now = DateTime.now();
    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    if (_selectedMonth.year == now.year && _selectedMonth.month == now.month) {
      return lastDay - now.day;
    }
    return 0;
  }

  int get _dailyBudget {
    final left = _daysLeftInMonth;
    if (left <= 0 || _balance <= 0) return 0;
    return _balance ~/ left;
  }

  static const _categoryColors = [
    Color(0xFF2E75B6), Color(0xFF1F4E79), Color(0xFF70AD47), Color(0xFFED7D31),
    Color(0xFFFFC000), Color(0xFF7030A0), Color(0xFF00B0F0), Color(0xFFFF0000),
    Color(0xFF00B050),
  ];

  void _showBudgetDialog() {
    final cats = _categoryTotals.keys.toList();
    if (cats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이번 달 지출 내역이 없어요')),
      );
      return;
    }
    final controllers = {for (final c in cats) c: TextEditingController(text: _budgets[c]?.toString() ?? '')};

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('카테고리별 예산 설정'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: cats.map((c) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: TextField(
                controller: controllers[c],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: '$c 예산 (원)', hintText: '비워두면 한도 없음'),
              ),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E75B6)),
            onPressed: () async {
              final newBudgets = Map<String, int>.from(_budgets);
              for (final c in cats) {
                final v = int.tryParse(controllers[c]!.text.replaceAll(',', '') );
                if (v != null && v > 0) newBudgets[c] = v;
                else newBudgets.remove(c);
              }
              await _saveBudgets(newBudgets);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('저장', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cats = _categoryTotals;
    final catKeys = cats.keys.toList();
    final daily = _dailyTotals;
    final maxDaily = daily.values.isEmpty ? 1 : daily.values.reduce((a, b) => a > b ? a : b);
    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;

    return Scaffold(
      appBar: AppBar(
        title: const Text('통계', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1F4E79),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () { setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1)); _load(); },
          ),
          TextButton(
            onPressed: null,
            child: Text(DateFormat('yyyy.MM').format(_selectedMonth),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () { setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1)); _load(); },
          ),
          IconButton(
            tooltip: '예산 설정',
            icon: const Icon(Icons.tune),
            onPressed: _showBudgetDialog,
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── 요약 카드 ──
            _SummaryRow(totalExpense: _totalExpense, totalIncome: _totalIncome, balance: _balance, fmt: _fmt),
            const SizedBox(height: 16),

            // ── 하루 추천 예산 ──
            if (_daysLeftInMonth > 0) ...[
              _BudgetTipCard(balance: _balance, daysLeft: _daysLeftInMonth, dailyBudget: _dailyBudget, fmt: _fmt),
              const SizedBox(height: 16),
            ],

            if (cats.isNotEmpty) ...[
              // ── 카테고리 도넛 차트 ──
              _SectionCard(
                title: '카테고리별 지출',
                action: TextButton.icon(
                  onPressed: _showBudgetDialog,
                  icon: const Icon(Icons.tune, size: 14),
                  label: const Text('예산', style: TextStyle(fontSize: 12)),
                ),
                child: SizedBox(
                  height: 200,
                  child: PieChart(PieChartData(
                    sections: catKeys.asMap().entries.map((e) {
                      final color = _categoryColors[e.key % _categoryColors.length];
                      final pct = cats[e.value]! / _totalExpense * 100;
                      return PieChartSectionData(
                        value: cats[e.value]!.toDouble(), color: color,
                        title: '${pct.toStringAsFixed(1)}%', radius: 70,
                        titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    }).toList(),
                    sectionsSpace: 2, centerSpaceRadius: 40,
                  )),
                ),
              ),
              const SizedBox(height: 8),

              // ── 카테고리 목록 + 예산 진행바 ──
              _SectionCard(
                title: '',
                child: Column(
                  children: catKeys.asMap().entries.map((e) {
                    final color = _categoryColors[e.key % _categoryColors.length];
                    final spent = cats[e.value]!;
                    final budget = _budgets[e.value];
                    final ratio = budget != null ? (spent / budget).clamp(0.0, 1.0) : null;
                    final over = budget != null && spent > budget;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(e.value, style: const TextStyle(fontSize: 13))),
                            Text('${_fmt.format(spent)}원',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                                    color: over ? Colors.red : Colors.black87)),
                            if (budget != null) ...[
                              Text(' / ${_fmt.format(budget)}원',
                                  style: const TextStyle(color: Colors.grey, fontSize: 11)),
                            ],
                          ]),
                          if (ratio != null) ...[
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: ratio, minHeight: 6,
                                backgroundColor: const Color(0xFFEEEEEE),
                                valueColor: AlwaysStoppedAnimation(over ? Colors.red : color),
                              ),
                            ),
                            if (over)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text('⚠️ 예산 ${_fmt.format(spent - budget)}원 초과',
                                    style: const TextStyle(color: Colors.red, fontSize: 10)),
                              ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),

              // ── 일별 막대 차트 ──
              _SectionCard(
                title: '일별 지출',
                child: SizedBox(
                  height: 180,
                  child: daily.isEmpty
                      ? const Center(child: Text('지출 없음', style: TextStyle(color: Colors.grey)))
                      : BarChart(BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: maxDaily * 1.3,
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (g, gi, rod, ri) =>
                                  BarTooltipItem('${g.x.toInt()}일\n${_fmt.format(rod.toY.toInt())}원',
                                      const TextStyle(color: Colors.white, fontSize: 11)),
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: (lastDay / 6).ceilToDouble(),
                                getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                              ),
                            ),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(lastDay, (i) {
                            final day = i + 1;
                            final amount = daily[day] ?? 0;
                            return BarChartGroupData(x: day, barRods: [
                              BarChartRodData(
                                toY: amount.toDouble(),
                                color: amount > 0 ? const Color(0xFF2E75B6) : Colors.transparent,
                                width: lastDay <= 15 ? 14 : 8,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ]);
                          }),
                        )),
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
  final int totalExpense, totalIncome, balance;
  final NumberFormat fmt;
  const _SummaryRow({required this.totalExpense, required this.totalIncome, required this.balance, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final balanceColor = balance >= 0 ? const Color(0xFF2E75B6) : Colors.red;
    final balanceText = balance >= 0 ? '${fmt.format(balance)}원' : '-${fmt.format(balance.abs())}원';
    return Row(children: [
      Expanded(child: _SummaryCard(label: '총 지출', text: '${fmt.format(totalExpense)}원', color: Colors.red)),
      const SizedBox(width: 8),
      Expanded(child: _SummaryCard(label: '총 수입', text: '${fmt.format(totalIncome)}원', color: Colors.green)),
      const SizedBox(width: 8),
      Expanded(child: _SummaryCard(label: '잔액', text: balanceText, color: balanceColor)),
    ]);
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, text;
  final Color color;
  const _SummaryCard({required this.label, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
      ]),
    );
  }
}

class _BudgetTipCard extends StatelessWidget {
  final int balance, daysLeft, dailyBudget;
  final NumberFormat fmt;
  const _BudgetTipCard({required this.balance, required this.daysLeft, required this.dailyBudget, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final ok = balance > 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ok ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ok ? const Color(0xFF81C784) : const Color(0xFFFFB74D)),
      ),
      child: Row(children: [
        Text(ok ? '💡' : '⚠️', style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('이번 달 남은 일수: $daysLeft일', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 3),
          if (ok)
            Text('하루 ${fmt.format(dailyBudget)}원 이내로 추천',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2E7D32)))
          else
            const Text('이번 달 예산을 초과했어요',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFE65100))),
        ])),
      ]),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;
  const _SectionCard({required this.title, required this.child, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (title.isNotEmpty) ...[
          Row(children: [
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1F4E79)))),
            if (action != null) action!,
          ]),
          const SizedBox(height: 12),
        ],
        child,
      ]),
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
