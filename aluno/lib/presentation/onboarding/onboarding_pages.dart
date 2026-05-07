import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../shared/rule_item.dart';
import '../shared/xp_widgets.dart';

// Modelo simples para cada página
class OnboardingPageData {
  final Widget child;
  const OnboardingPageData({required this.child});
}

// ─── Página 1: Boas-vindas / Andy ────────────────────────────────────────────
class OnboardingPageWelcome extends StatelessWidget {
  const OnboardingPageWelcome({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppTheme.backgroundPrimary,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.brandAccent.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Image.asset(
              'assets/chatbot_photo.png',
              fit: BoxFit.contain,
              color: Colors.white,
              colorBlendMode: BlendMode.difference,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Olá! Sou o Andy 👋',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'O teu companheiro de estudo com IA.\nAbre-me depois de qualquer exercício para esclarecer dúvidas e aprender melhor.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}

// ─── Página 2: XP e Streak ───────────────────────────────────────────────────
class OnboardingPageXp extends StatelessWidget {
  const OnboardingPageXp({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFB923C).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Color(0xFFFB923C),
              size: 36,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'XP e Streak',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
        ),
        const SizedBox(height: 20),
        RuleItem(
          icon: Icons.local_fire_department_rounded,
          color: const Color(0xFFFB923C),
          title: '5 exercícios diários = Bónus XP',
          description: 'Os primeiros 5 por dia têm 1.5× XP de bónus e mantêm o teu streak:',
          extra: const XpTable(),
        ),
        const SizedBox(height: 16),
        RuleItem(
          icon: Icons.play_circle_outline_rounded,
          color: const Color(0xFF60A5FA),
          title: 'Podes continuar depois',
          description: 'Após os 5 diários, podes continuar a praticar com XP normal.',
        ),
      ],
    );
  }
}

// ─── Página 3: Progressão ────────────────────────────────────────────────────
class OnboardingPageProgression extends StatelessWidget {
  const OnboardingPageProgression({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.successState.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: AppTheme.successState,
              size: 36,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'Progressão por dificuldade',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
        ),
        const SizedBox(height: 20),
        RuleItem(
          icon: Icons.trending_up_rounded,
          color: AppTheme.successState,
          title: 'Fácil → Médio → Difícil',
          description: 'Cada tópico segue esta ordem. Tens de completar um nível para desbloquear o seguinte.',
        ),
        const SizedBox(height: 16),
        RuleItem(
          icon: Icons.lock_open_rounded,
          color: AppTheme.brandAccent,
          title: 'Desbloqueia tópicos',
          description: 'Completa os exercícios de um tópico para avançar na árvore do curso.',
        ),
      ],
    );
  }
}