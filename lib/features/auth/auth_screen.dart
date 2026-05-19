import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(color: Color(0xFF1F4E79), shape: BoxShape.circle),
                  child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 16),
                const Text('ChatBudget', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1F4E79))),
                const Text('대화하듯 기록하는 가계부', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 32),
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))]),
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tab,
                        tabs: const [Tab(text: '로그인'), Tab(text: '회원가입')],
                        labelColor: const Color(0xFF1F4E79),
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: const Color(0xFF1F4E79),
                        dividerColor: Colors.transparent,
                      ),
                      SizedBox(
                        height: 280,
                        child: TabBarView(
                          controller: _tab,
                          children: const [_LoginForm(), _RegisterForm()],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _idCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  String? _error;
  bool _loading = false;

  Future<void> _submit() async {
    setState(() { _error = null; _loading = true; });
    final err = await AuthService.login(_idCtrl.text, _pwCtrl.text);
    if (!mounted) return;
    if (err != null) {
      setState(() { _error = err; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        children: [
          _Field(controller: _idCtrl, label: '아이디', icon: Icons.person_outline),
          const SizedBox(height: 12),
          _Field(controller: _pwCtrl, label: '비밀번호', icon: Icons.lock_outline, obscure: true, onSubmit: _submit),
          const SizedBox(height: 8),
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1F4E79), padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('로그인'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterForm extends StatefulWidget {
  const _RegisterForm();

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _idCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  String? _error;
  bool _loading = false;

  Future<void> _submit() async {
    setState(() { _error = null; _loading = true; });
    final err = await AuthService.register(_idCtrl.text, _pwCtrl.text);
    if (!mounted) return;
    if (err != null) {
      setState(() { _error = err; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        children: [
          _Field(controller: _idCtrl, label: '아이디 (3자 이상)', icon: Icons.person_outline),
          const SizedBox(height: 12),
          _Field(controller: _pwCtrl, label: '비밀번호 (4자 이상)', icon: Icons.lock_outline, obscure: true, onSubmit: _submit),
          const SizedBox(height: 8),
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E75B6), padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('회원가입'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final VoidCallback? onSubmit;

  const _Field({required this.controller, required this.label, required this.icon, this.obscure = false, this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onSubmitted: onSubmit != null ? (_) => onSubmit!() : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
