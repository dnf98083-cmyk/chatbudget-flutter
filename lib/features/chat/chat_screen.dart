import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/database/db_helper.dart';
import '../../core/models/savings_goal_model.dart';
import '../../core/models/transaction_model.dart';
import '../../core/parser/transaction_parser.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/category_service.dart';

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  _ChatMessage({required this.text, required this.isUser, required this.time});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final username = AuthService.currentUser?.username ?? '';
    _addBot('안녕하세요, $username님! 지출이나 수입을 입력해보세요.\n\n예시:\n• "스타벅스 6000원"\n• "어제 점심 8500"\n• "3일전 택시 12000"\n• "월급 250만원"');
  }

  void _addBot(String text) {
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: false, time: DateTime.now()));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true, time: DateTime.now()));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    final userId = AuthService.currentUserId;
    TransactionModel? transaction;

    // Try AI parsing first
    final aiResult = await AiService.parseTransaction(text);
    if (aiResult != null) {
      try {
        final now = DateTime.now();
        final offset = (aiResult['date_offset'] as num?)?.toInt() ?? 0;
        final date = now.subtract(Duration(days: offset));
        transaction = TransactionModel(
          userId: userId,
          amount: (aiResult['amount'] as num).toInt(),
          type: aiResult['type'] as String? ?? 'expense',
          category: aiResult['category'] as String? ?? '기타',
          description: aiResult['description'] as String? ?? text,
          date: date,
        );
      } catch (_) {
        transaction = null;
      }
    }

    // Fall back to rule-based parser
    if (transaction == null) {
      final parsed = TransactionParser.toTransaction(text);
      if (parsed != null) {
        transaction = TransactionModel(
          userId: userId,
          amount: parsed.amount,
          type: parsed.type,
          category: parsed.category,
          description: parsed.description,
          date: parsed.date,
        );
      }
    }

    setState(() => _isLoading = false);

    if (transaction == null) {
      _addBot('금액을 찾지 못했어요. 예시처럼 금액을 포함해서 입력해주세요.\n예: "편의점 3500원"');
      return;
    }

    await DbHelper.instance.insertTransaction(transaction);
    AuthService.notifyRefresh();

    final isNewCategory = await CategoryService.addIfNew(transaction.category);

    final fmt = NumberFormat('#,###');
    final dateFmt = DateFormat('MM/dd');
    final typeLabel = transaction.type == 'income' ? '수입' : '지출';
    final emoji = transaction.type == 'income' ? '💰' : '💸';
    final aiLabel = aiResult != null ? ' ✨' : '';

    _addBot(
      '$emoji 기록 완료!$aiLabel\n'
      '${dateFmt.format(transaction.date)} · ${transaction.category}\n'
      '${fmt.format(transaction.amount)}원 $typeLabel\n'
      '"${transaction.description}"',
    );

    if (isNewCategory) {
      _addBot('🏷️ 새 카테고리 "${transaction.category}"이(가) 추가됐어요!\n내역 수정·통계에서도 사용할 수 있습니다.');
    }

    // 저축 카테고리면 저축 목표에도 반영 제안
    if (transaction.category == '저축') {
      await _handleSavingsGoal(transaction.amount);
    }
  }

  Future<void> _handleSavingsGoal(int amount) async {
    final goals = await DbHelper.instance.getSavingsGoals(userId: AuthService.currentUserId);
    if (goals.isEmpty) {
      _addBot('💡 저축 탭에서 목표를 만들면 진행률을 추적할 수 있어요!');
      return;
    }
    if (!mounted) return;
    if (goals.length == 1) {
      _askSavingsGoal(goals.first, amount);
      return;
    }
    // 여러 목표가 있으면 선택 다이얼로그
    final selected = await showDialog<SavingsGoalModel>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('어떤 목표에 추가할까요?'),
        children: [
          ...goals.map((g) => SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, g),
            child: Text('${g.title}  (${NumberFormat('#,###').format(g.currentAmount)}/${NumberFormat('#,###').format(g.targetAmount)}원)'),
          )),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('추가 안 함', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
    if (selected != null) _askSavingsGoal(selected, amount);
  }

  void _askSavingsGoal(SavingsGoalModel goal, int amount) async {
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('저축 목표 반영'),
        content: Text('"${goal.title}"에 ${NumberFormat('#,###').format(amount)}원을 추가할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('아니요')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E75B6)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('네', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final updated = goal.copyWith(currentAmount: goal.currentAmount + amount);
      await DbHelper.instance.updateSavingsGoal(updated);
      AuthService.notifyRefresh();
      _addBot('🎯 "${goal.title}" 목표에 ${NumberFormat('#,###').format(amount)}원 추가됐어요!\n'
          '현재 ${NumberFormat('#,###').format(updated.currentAmount)} / ${NumberFormat('#,###').format(goal.targetAmount)}원');
    }
  }

  Future<void> _showSettings() async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('설정'),
        content: Text(
          '로그인: ${AuthService.currentUser?.username ?? ''}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _confirmClearRecords();
            },
            child: const Text('기록 초기화', style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.logout();
            },
            child: const Text('로그아웃', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearRecords() async {
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('기록 초기화'),
        content: const Text('모든 거래 내역이 삭제됩니다.\n이 작업은 되돌릴 수 없어요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('전체 삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await DbHelper.instance.deleteAllTransactions(userId: AuthService.currentUserId);
      AuthService.notifyRefresh();
      _addBot('🗑️ 모든 거래 내역이 초기화됐어요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ChatBudget', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1F4E79),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _showSettings,
            icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 18),
            label: const Text('설정', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (_, i) {
                if (_isLoading && i == _messages.length) {
                  return const _TypingIndicator();
                }
                return _MessageBubble(message: _messages[i]);
              },
            ),
          ),
          _InputBar(controller: _controller, onSend: _handleSend, enabled: !_isLoading),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(color: Color(0xFF1F4E79), shape: BoxShape.circle),
            child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 16),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: const SizedBox(width: 40, height: 16, child: _DotAnimation()),
          ),
        ],
      ),
    );
  }
}

class _DotAnimation extends StatefulWidget {
  const _DotAnimation();

  @override
  State<_DotAnimation> createState() => _DotAnimationState();
}

class _DotAnimationState extends State<_DotAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (i) {
            final phase = (_ctrl.value - i * 0.15).clamp(0.0, 1.0);
            final opacity = (phase < 0.5 ? phase * 2 : (1 - phase) * 2).clamp(0.3, 1.0);
            return Opacity(
              opacity: opacity,
              child: const CircleAvatar(radius: 4, backgroundColor: Color(0xFF1F4E79)),
            );
          }),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(color: Color(0xFF1F4E79), shape: BoxShape.circle),
              child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 16),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF2E75B6) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : const Color(0xFF1A1A2E),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;

  const _InputBar({required this.controller, required this.onSend, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              onSubmitted: enabled ? (_) => onSend() : null,
              decoration: InputDecoration(
                hintText: '예: 스타벅스 6000원',
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: enabled ? onSend : null,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: enabled ? const Color(0xFF2E75B6) : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
