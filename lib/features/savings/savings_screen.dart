import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/database/db_helper.dart';
import '../../core/models/savings_goal_model.dart';
import '../../core/services/auth_service.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  List<SavingsGoalModel> _goals = [];
  final _fmt = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await DbHelper.instance.getSavingsGoals(userId: AuthService.currentUserId);
    if (mounted) setState(() => _goals = list);
  }

  void _showAddDialog() {
    final titleCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('저축 목표 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: '목표 이름 (예: 여행 자금)'),
                onChanged: (_) => setDlg(() => errorMsg = null),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: targetCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '목표 금액 (원)', hintText: '예: 500000'),
                onChanged: (_) => setDlg(() => errorMsg = null),
              ),
              if (errorMsg != null) ...[
                const SizedBox(height: 8),
                Text(errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E75B6)),
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final raw = targetCtrl.text.replaceAll(',', '').replaceAll(' ', '');
                final target = int.tryParse(raw);
                if (title.isEmpty) {
                  setDlg(() => errorMsg = '목표 이름을 입력해주세요');
                  return;
                }
                if (target == null || target <= 0) {
                  setDlg(() => errorMsg = '올바른 금액을 숫자로 입력해주세요 (예: 500000)');
                  return;
                }
                try {
                  await DbHelper.instance.insertSavingsGoal(
                    SavingsGoalModel(userId: AuthService.currentUserId, title: title, targetAmount: target),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                } catch (e) {
                  setDlg(() => errorMsg = '저장 실패: $e');
                }
              },
              child: const Text('추가', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDepositDialog(SavingsGoalModel goal) {
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${goal.title} 저축'),
        content: TextField(
          controller: amountCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '저축 금액 (원)'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E75B6)),
            onPressed: () async {
              final amount = int.tryParse(amountCtrl.text.replaceAll(',', ''));
              if (amount == null || amount <= 0) return;
              final updated = goal.copyWith(currentAmount: goal.currentAmount + amount);
              await DbHelper.instance.updateSavingsGoal(updated);
              if (ctx.mounted) Navigator.pop(ctx);
              _load();
            },
            child: const Text('저축', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('저축 목표', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1F4E79),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF2E75B6),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _goals.isEmpty
          ? const Center(child: Text('저축 목표를 추가해보세요!\n+ 버튼을 눌러 시작하세요.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _goals.length,
              itemBuilder: (_, i) => _GoalCard(
                goal: _goals[i],
                fmt: _fmt,
                onDeposit: () => _showDepositDialog(_goals[i]),
                onDelete: () async {
                  await DbHelper.instance.deleteSavingsGoal(_goals[i].id!);
                  _load();
                },
              ),
            ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final SavingsGoalModel goal;
  final NumberFormat fmt;
  final VoidCallback onDeposit;
  final VoidCallback onDelete;

  const _GoalCard({required this.goal, required this.fmt, required this.onDeposit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final pct = goal.progress;
    final remaining = goal.targetAmount - goal.currentAmount;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(goal.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F4E79))),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.add_circle_outline, color: Color(0xFF2E75B6)), onPressed: onDeposit, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                  const SizedBox(width: 4),
                  IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: onDelete, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${fmt.format(goal.currentAmount)}원', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2E75B6))),
              Text('/ ${fmt.format(goal.targetAmount)}원', style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: const Color(0xFFE3EEFF),
              valueColor: AlwaysStoppedAnimation<Color>(pct >= 1.0 ? Colors.green : const Color(0xFF2E75B6)),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(pct * 100).toStringAsFixed(1)}% 달성', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              if (remaining > 0)
                Text('${fmt.format(remaining)}원 남음', style: const TextStyle(color: Colors.grey, fontSize: 12))
              else
                const Text('목표 달성! 🎉', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
