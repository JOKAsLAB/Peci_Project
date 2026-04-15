import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Definições', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.surfaceSecondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          // Secção Conta
          const _SectionHeader(title: 'Conta'),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.person_outline,
            title: 'Editar Perfil',
            subtitle: 'Alterar nome ou foto de perfil',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.lock_outline,
            title: 'Alterar Password',
            subtitle: 'Modificar as credenciais de acesso',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.school_outlined,
            title: 'Disciplinas Inscritas',
            subtitle: 'Ver as UCs em que estás inscrito',
            onTap: () {},
          ),

          const SizedBox(height: 32),

          // Secção Sobre
          const _SectionHeader(title: 'Sobre'),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'Sobre a App',
            subtitle: 'PECI Projeto #8 · v0.1.0',
            onTap: () {},
          ),

          const SizedBox(height: 32),

          // Logout button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(authProvider.notifier).logout();
                context.go('/login');
              },
              icon: const Icon(Icons.logout_rounded, color: AppTheme.errorState),
              label: const Text(
                'Terminar Sessão',
                style: TextStyle(color: AppTheme.errorState, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.errorState, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: AppTheme.brandAccent,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.textSecondary, size: 22),
        title: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary, size: 20),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

