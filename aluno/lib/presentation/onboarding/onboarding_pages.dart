import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../shared/rule_item.dart';
import '../shared/xp_widgets.dart';

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
            border: Border.all(color: AppTheme.brandAccent.withValues(alpha: 0.4), width: 1.5),
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
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 22),
        ),
        const SizedBox(height: 10),
        const Text(
          'A tua app de estudo para Sistemas Digitais.\nVê como funciona em 3 passos rápidos.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.55),
        ),
        const SizedBox(height: 28),
        // Prévia das 4 tabs
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _TabPreview(icon: Icons.school, label: 'Cursos'),
            _TabPreview(icon: Icons.bolt, label: 'Prática'),
            _TabPreview(icon: Icons.gamepad, label: 'Quizzes'),
            _TabPreview(icon: Icons.person, label: 'Perfil'),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Navega entre as secções deslizando para os lados ou tocando nas tabs.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
        ),
      ],
    );
  }
}

class _TabPreview extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TabPreview({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.brandAccent, size: 22),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }
}

// ─── Página 2: Cursos e Prática ───────────────────────────────────────────────
class OnboardingPageCourses extends StatelessWidget {
  const OnboardingPageCourses({super.key});

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
              color: AppTheme.brandAccent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school_rounded, color: AppTheme.brandAccent, size: 36),
          ),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'Cursos e Prática',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 22),
          ),
        ),
        const SizedBox(height: 20),
        RuleItem(
          icon: Icons.trending_up_rounded,
          color: AppTheme.successState,
          title: 'Progressão por dificuldade',
          description: 'Em Cursos, cada tópico segue a ordem Fácil → Médio → Difícil. Completa um nível para desbloquear o seguinte na árvore.',
        ),
        const SizedBox(height: 14),
        RuleItem(
          icon: Icons.bolt_rounded,
          color: const Color(0xFF60A5FA),
          title: 'Prática livre com filtros',
          description: 'Em Prática podes escolher a disciplina, tópico, tipo e dificuldade — e fazer scroll vertical para passar de exercício.',
        ),
        const SizedBox(height: 14),
        RuleItem(
          icon: Icons.auto_awesome,
          color: AppTheme.brandAccent,
          title: 'Explicação automática',
          description: 'Após responderes aparece sempre uma explicação. Toca em "Pedir explicação ao Andy" para aprofundar com IA.',
        ),
      ],
    );
  }
}

// ─── Página 3: XP e Streak ───────────────────────────────────────────────────
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
            child: const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFB923C), size: 36),
          ),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'XP, Streak e Nível',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 22),
          ),
        ),
        const SizedBox(height: 20),
        RuleItem(
          icon: Icons.local_fire_department_rounded,
          color: const Color(0xFFFB923C),
          title: '5 exercícios diários = Bónus XP',
          description: 'Os primeiros 5 por dia têm 1.5× XP e mantêm o streak. Depois podes continuar com XP normal:',
          extra: const XpTable(),
        ),
        const SizedBox(height: 14),
        RuleItem(
          icon: Icons.emoji_events_rounded,
          color: const Color(0xFFFFD54F),
          title: 'Nível e estatísticas',
          description: 'O XP acumulado sobe o teu nível. No Perfil vês o streak, XP total e o desempenho por tópico.',
        ),
      ],
    );
  }
}

// ─── Página 4: Andy e Reportar ────────────────────────────────────────────────
class OnboardingPageAndy extends StatelessWidget {
  const OnboardingPageAndy({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.backgroundPrimary,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.brandAccent.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Image.asset(
                'assets/chatbot_photo.png',
                fit: BoxFit.contain,
                color: Colors.white,
                colorBlendMode: BlendMode.difference,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'Andy e Reportar',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 22),
          ),
        ),
        const SizedBox(height: 20),
        RuleItem(
          icon: Icons.smart_toy_rounded,
          color: AppTheme.brandAccent,
          title: 'Pede ajuda ao Andy',
          description: 'Depois de qualquer exercício, toca em "Pedir explicação ao Andy" para receber uma explicação personalizada com IA — seja resposta certa ou errada.',
        ),
        const SizedBox(height: 14),
        RuleItem(
          icon: Icons.flag_rounded,
          color: AppTheme.errorState,
          title: 'Reportar um problema',
          description: 'Se encontrares um exercício com erro ou enunciado confuso, toca no botão vermelho "Reportar problema". A equipa docente será notificada.',
        ),
        const SizedBox(height: 14),
        RuleItem(
          icon: Icons.help_outline_rounded,
          color: AppTheme.textSecondary,
          title: 'Rever este tutorial',
          description: 'Podes voltar a ver este tutorial a qualquer momento — toca no ícone "?" no ecrã de Cursos.',
        ),
      ],
    );
  }
}