import 'package:flutter/material.dart';
import 'package:peci_project/core/theme/app_theme.dart';


class XpBadge extends StatelessWidget {
  final String difficulty;
  final bool bonus;
  const XpBadge({super.key, required this.difficulty, required this.bonus});

  @override
  Widget build(BuildContext context) {
    final (base, bonusXp) = switch (difficulty.toLowerCase()) {
      'easy' => (10, 15),
      'hard' => (35, 53),
      _      => (20, 30),
    };
    final xp = bonus ? bonusXp : base;
    final color = bonus ? const Color(0xFFFB923C) : AppTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: bonus ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (bonus) ...[
            const Icon(Icons.local_fire_department_rounded, size: 10, color: Color(0xFFFB923C)),
            const SizedBox(width: 2),
          ],
          Text(
            '+$xp XP',
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class XpTable extends StatelessWidget {
  const XpTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPrimary.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          XpRow(label: 'Fácil',   normal: 10, bonus: 15,  color: AppTheme.successState),
          const SizedBox(height: 4),
          XpRow(label: 'Médio',   normal: 20, bonus: 30,  color: AppTheme.warningState),
          const SizedBox(height: 4),
          XpRow(label: 'Difícil', normal: 35, bonus: 53,  color: AppTheme.errorState),
        ],
      ),
    );
  }
}

class XpRow extends StatelessWidget {
  final String label;
  final int normal;
  final int bonus;
  final Color color;

  const XpRow({super.key, required this.label, required this.normal, required this.bonus, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        Text('$normal XP', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.arrow_forward_rounded, size: 10, color: AppTheme.textSecondary),
        ),
        Text('$bonus XP', style: const TextStyle(color: Color(0xFFFB923C), fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(width: 4),
        const Text('com bónus', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
      ],
    );
  }
}

class XpChip extends StatelessWidget {
  final String label;
  final int normal;
  final int bonusXp;
  final bool bonusActive;
  final Color color;
  const XpChip({super.key, required this.label, required this.normal, required this.bonusXp, required this.bonusActive, required this.color});

  @override
  Widget build(BuildContext context) {
    final xp = bonusActive ? bonusXp : normal;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 4),
        Text(
          '$xp XP',
          style: TextStyle(
            color: bonusActive ? const Color(0xFFFB923C) : AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: bonusActive ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

