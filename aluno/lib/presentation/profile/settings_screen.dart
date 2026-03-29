import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _dailyReminder = true;
  bool _soundEffects = true;
  String _selectedLanguage = 'Português';

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
          _SectionHeader(title: 'Conta'),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.person_outline,
            title: 'Editar Perfil',
            subtitle: 'Nome, foto, NMec',
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
            subtitle: 'Gerir as UCs em que estás inscrito',
            onTap: () {},
          ),

          const SizedBox(height: 32),

          // Secção Notificações
          _SectionHeader(title: 'Notificações'),
          const SizedBox(height: 12),
          _SettingsSwitch(
            icon: Icons.notifications_outlined,
            title: 'Notificações',
            subtitle: 'Receber alertas de novos exercícios',
            value: _notificationsEnabled,
            onChanged: (v) => setState(() => _notificationsEnabled = v),
          ),
          _SettingsSwitch(
            icon: Icons.alarm_outlined,
            title: 'Lembrete Diário',
            subtitle: 'Lembrete para praticar todos os dias',
            value: _dailyReminder,
            onChanged: (v) => setState(() => _dailyReminder = v),
          ),

          const SizedBox(height: 32),

          // Secção Preferências
          _SectionHeader(title: 'Preferências'),
          const SizedBox(height: 12),
          _SettingsSwitch(
            icon: Icons.volume_up_outlined,
            title: 'Sons',
            subtitle: 'Efeitos sonoros ao responder exercícios',
            value: _soundEffects,
            onChanged: (v) => setState(() => _soundEffects = v),
          ),
          _SettingsTile(
            icon: Icons.language_outlined,
            title: 'Idioma',
            subtitle: _selectedLanguage,
            trailing: DropdownButton<String>(
              value: _selectedLanguage,
              dropdownColor: AppTheme.surfaceSecondary,
              style: const TextStyle(color: AppTheme.brandAccent, fontSize: 14),
              underline: const SizedBox(),
              items: ['Português', 'English'].map((l) {
                return DropdownMenuItem(value: l, child: Text(l));
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedLanguage = v);
              },
            ),
          ),

          const SizedBox(height: 32),

          // Secção Sobre
          _SectionHeader(title: 'Sobre'),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'Sobre a App',
            subtitle: 'PECI Projeto #8 · v0.1.0 · Elaboração (M2)',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: 'Termos e Condições',
            subtitle: 'Política de privacidade e uso',
            onTap: () {},
          ),

          const SizedBox(height: 32),

          // Logout button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(mockAuthProvider.notifier).state = false;
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

class _SettingsSwitch extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: AppTheme.textSecondary, size: 22),
        title: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.brandAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
