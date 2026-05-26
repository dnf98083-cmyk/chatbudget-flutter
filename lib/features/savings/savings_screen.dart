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
    DateTime? selectedDeadline;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('저축 목표 추가'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('목표 날짜', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 14),
                        label: Text(
                          selectedDeadline != null
                              ? DateFormat('yyyy.MM.dd').format(selectedDeadline!)
                              : '선택 (선택사항)',
                          style: const TextStyle(fontSize: 13),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                          );
                          if (picked != null) setDlg(() => selectedDeadline = picked);
                        },
                      ),
                    ),
                    if (selectedDeadline != null)
                      IconButton(
                        icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                        onPressed: () => setDlg(() => selectedDeadline = null),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                if (errorMsg != null) ...[
                  const SizedBox(height: 8),
                  Text(errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ],
              ],
            ),
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
                    SavingsGoalModel(
                      userId: AuthService.currentUserId,
                      title: title,
                      targetAmount: target,
                      deadline: selectedDeadline,
                    ),
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

  String? _estimatedCompletion() {
    final daysSinceCreation = DateTime.now().difference(goal.createdAt).inDays;
    if (daysSinceCreation <= 0 || goal.currentAmount <= 0) return null;
    final remaining = goal.targetAmount - goal.currentAmount;
    if (remaining <= 0) return null;
    final dailyRate = goal.currentAmount / daysSinceCreation;
    if (dailyRate <= 0) return null;
    final daysToComplete = (remaining / dailyRate).ceil();
    final estimatedDate = DateTime.now().add(Duration(days: daysToComplete));
    return DateFormat('yyyy.MM.dd').format(estimatedDate);
  }

  @override
  Widget build(BuildContext context) {
    final pct = goal.progress;
    final remaining = goal.targetAmount - goal.currentAmount;
    final estimated = _estimatedCompletion();

    String? dDayText;
    Color dDayColor = const Color(0xFF2E75B6);
    if (goal.deadline != null && remaining > 0) {
      final daysLeft = goal.deadline!.difference(DateTime.now()).inDays;
      if (daysLeft > 0) {
        dDayText = 'D-$daysLeft';
      } else if (daysLeft == 0) {
        dDayText = 'D-Day';
        dDayColor = Colors.orange;
      } else {
        dDayText = '목표일 +${-daysLeft}일';
        dDayColor = Colors.red;
      }
    }

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
            children: [
              Expanded(
                child: Text(goal.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F4E79))),
              ),
              if (dDayText != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: dDayColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: dDayColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(dDayText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: dDayColor)),
                ),
                const SizedBox(width: 6),
              ],
              IconButton(icon: const Icon(Icons.add_circle_outline, color: Color(0xFF2E75B6)), onPressed: onDeposit, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              const SizedBox(width: 4),
              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: onDelete, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
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
          if (goal.deadline != null || estimated != null) ...[
            const Divider(height: 14, thickness: 0.5),
            Row(
              children: [
                if (goal.deadline != null) ...[
                  const Icon(Icons.flag_outlined, size: 12, color: Colors.grey),
                  const SizedBox(width: 3),
                  Text('목표일 ${DateFormat('yyyy.MM.dd').format(goal.deadline!)}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
                if (goal.deadline != null && estimated != null) const Text('  ·  ', style: TextStyle(color: Colors.grey, fontSize: 11)),
                if (estimated != null) ...[
                  const Icon(Icons.trending_up, size: 12, color: Colors.blueGrey),
                  const SizedBox(width: 3),
                  Text('달성 예상일 $estimated', style: const TextStyle(color: Colors.blueGrey, fontSize: 11)),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
