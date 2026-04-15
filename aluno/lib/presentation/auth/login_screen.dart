import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';
import '../../features/auth/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) return;

    print('[LOGIN SCREEN] Starting login with email=$email');
    ref.read(authProvider.notifier).login(email, password);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    // Listener para navegação
    ref.listen<AuthState>(authProvider, (previous, next) {
      print('[LOGIN SCREEN] Auth state changed: authenticated=${next.isAuthenticated}, error=${next.error}');
      if (next.isAuthenticated) {
        print('[LOGIN SCREEN] User authenticated! Navigating to /courses');
        // Lê o routerProvider ATUALIZADO agora, antes de fazer go()
        final router = ref.read(routerProvider);
        Future.microtask(() {
          if (mounted) {
            router.go('/courses');
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.brandAccent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 24),
                Text('PECI Study', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text('Aprende. Pratica. Evolui.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                const SizedBox(height: 48),

                // Email
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Email institucional',
                    prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.surfaceSecondary,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),

                // Password
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppTheme.textSecondary),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceSecondary,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (_) => _login(),
                ),

                const SizedBox(height: 16),

                // Error Message
                if (authState.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(authState.error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: authState.isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Entrar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 24),
                
                // Register Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => context.push('/register'),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.textSecondary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: const Text('Criar Conta', style: TextStyle(color: AppTheme.textPrimary)),
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