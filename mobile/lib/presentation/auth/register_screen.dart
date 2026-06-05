import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/remote/auth_repository.dart';
import '../../features/auth/providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _codeController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  bool _showVerify = false;
  bool _verifyLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _register() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Preenche todos os campos.');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'A password deve ter pelo menos 6 caracteres.');
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = 'As passwords não coincidem.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _loading = true;
    });

    ref.read(authProvider.notifier).register(
      name: name,
      email: email,
      password: password,
      role: 'Student',
    );
  }

  Future<void> _verify() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();

    if (code.length != 6) {
      setState(() => _errorMessage = 'Introduz o código de 6 dígitos.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _verifyLoading = true;
    });

    try {
      await ref.read(authRepositoryProvider).verifyEmail(email, code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verificado! Faz login para entrar.'),
            backgroundColor: AppTheme.brandAccent,
          ),
        );
        context.go('/login');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Código inválido ou expirado. Tenta novamente.';
        _verifyLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (!_loading) return;

      if (next.registrationSuccess || next.isAuthenticated) {
        if (next.isAuthenticated) {
          ref.read(authProvider.notifier).logout();
        }
        setState(() {
          _loading = false;
          _showVerify = true;
          _errorMessage = null;
        });
      } else if (next.error != null) {
        setState(() {
          _errorMessage = next.error;
          _loading = false;
        });
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: _showVerify ? _buildVerifyStep(authState) : _buildRegisterStep(authState),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterStep(AuthState authState) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Back + Title
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
              onPressed: () => context.pop(),
            ),
            const SizedBox(width: 8),
            Text(
              'Criar Conta',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(left: 48),
            child: Text(
              'Regista-te com o teu email',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Nome
        _buildField(
          controller: _nameController,
          hint: 'Nome completo',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 14),

        // Email
        _buildField(
          controller: _emailController,
          hint: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),

        // Password
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Password (min. 6 caracteres)',
            hintStyle: const TextStyle(color: AppTheme.textSecondary),
            prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textSecondary, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppTheme.textSecondary, size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: AppTheme.surfaceSecondary,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.brandAccent, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        const SizedBox(height: 14),

        // Confirmar password
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirm,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Confirmar password',
            hintStyle: const TextStyle(color: AppTheme.textSecondary),
            prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textSecondary, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppTheme.textSecondary, size: 20,
              ),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            filled: true,
            fillColor: AppTheme.surfaceSecondary,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.brandAccent, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          onSubmitted: (_) => _register(),
        ),
        const SizedBox(height: 16),

        // Erro
        if (_errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.errorState.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppTheme.errorState, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.errorState, fontSize: 13)),
                ),
              ],
            ),
          ),

        // Botão criar conta
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: authState.isLoading ? null : _register,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: authState.isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text(
                    'Criar Conta',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        const SizedBox(height: 16),

        // Link login
        TextButton(
          onPressed: () => context.pop(),
          child: const Text.rich(
            TextSpan(
              text: 'Já tens conta? ',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              children: [
                TextSpan(
                  text: 'Entrar',
                  style: TextStyle(color: AppTheme.brandAccent, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildVerifyStep(AuthState authState) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.mark_email_unread_outlined, color: AppTheme.brandAccent, size: 56),
        const SizedBox(height: 20),
        Text(
          'Verifica o teu email',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 10),
        Text(
          'Enviámos um código de 6 dígitos para\n${_emailController.text.trim()}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 32),

        // Código
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 22, letterSpacing: 8),
          decoration: InputDecoration(
            hintText: '000000',
            hintStyle: const TextStyle(color: AppTheme.textSecondary, letterSpacing: 8),
            counterText: '',
            filled: true,
            fillColor: AppTheme.surfaceSecondary,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.brandAccent, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          ),
          onSubmitted: (_) => _verify(),
        ),
        const SizedBox(height: 16),

        // Erro
        if (_errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.errorState.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppTheme.errorState, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.errorState, fontSize: 13)),
                ),
              ],
            ),
          ),

        // Botão verificar
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _verifyLoading ? null : _verify,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _verifyLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text(
                    'Verificar Email',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        const SizedBox(height: 14),

        TextButton(
          onPressed: () => setState(() {
            _showVerify = false;
            _codeController.clear();
            _errorMessage = null;
          }),
          child: const Text(
            'Voltar ao registo',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
        filled: true,
        fillColor: AppTheme.surfaceSecondary,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.brandAccent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
