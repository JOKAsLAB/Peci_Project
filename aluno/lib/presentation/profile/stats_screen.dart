import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../features/profile/providers/profile_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(topicStatsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Desempenho', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.surfaceSecondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: statsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.brandAccent),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppTheme.errorState, size: 40),
                const SizedBox(height: 12),
                Text('Erro ao carregar estatísticas', style: const TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(topicStatsProvider),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Tentar de novo'),
                ),
              ],
            ),
          ),
        ),
        data: (stats) {
          if (stats.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bar_chart_rounded, size: 56, color: AppTheme.textSecondary),
                    SizedBox(height: 16),
                    Text(
                      'Ainda sem dados.\nResponde a exercícios nos Cursos para veres o teu desempenho.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            );
          }

          // Métricas globais
          final totalAnswered = stats.fold(0, (s, e) => s + (e['total_answered'] as num).toInt());
          final totalCorrect  = stats.fold(0, (s, e) => s + (e['correct_count']  as num).toInt());
          final globalAcc = totalAnswered > 0 ? totalCorrect / totalAnswered * 100 : 0.0;

          // Agrupar tópicos por cadeira, preservando a ordem (melhor accuracy primeiro)
          final Map<int, _UCGroup> groups = {};
          for (final s in stats) {
            final id = (s['id_uc'] as num).toInt();
            if (!groups.containsKey(id)) {
              groups[id] = _UCGroup(id: id, name: s['course_unit_name'] as String);
            }
            groups[id]!.topics.add(s);
          }

          return RefreshIndicator(
            color: AppTheme.brandAccent,
            onRefresh: () async => ref.invalidate(topicStatsProvider),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Resumo global ────────────────────────────────────────────
                _SummaryCard(
                  topicCount: stats.length,
                  totalAnswered: totalAnswered,
                  accuracy: globalAcc,
                ),
                const SizedBox(height: 24),

                // ── Grupos por cadeira ───────────────────────────────────────
                for (final group in groups.values) ...[
                  _UCGroupSection(group: group),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Modelos locais ───────────────────────────────────────────────────────────

class _UCGroup {
  final int id;
  final String name;
  final List<Map<String, dynamic>> topics = [];
  _UCGroup({required this.id, required this.name});
}

// ─── Resumo global ────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final int topicCount;
  final int totalAnswered;
  final double accuracy;

  const _SummaryCard({
    required this.topicCount,
    required this.totalAnswered,
    required this.accuracy,
  });

  Color get _accColor {
    if (accuracy >= 80) return AppTheme.successState;
    if (accuracy >= 50) return AppTheme.warningState;
    return AppTheme.errorState;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSecondary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RESUMO GLOBAL',
            style: TextStyle(
              color: AppTheme.brandAccent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _SummaryTile(
                label: 'Tópicos',
                value: '$topicCount',
                color: AppTheme.brandAccent,
              ),
              _SummaryTile(
                label: 'Respondidos',
                value: '$totalAnswered',
                color: AppTheme.textPrimary,
              ),
              _SummaryTile(
                label: 'Acerto',
                value: '${accuracy.toStringAsFixed(0)}%',
                color: _accColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: accuracy / 100,
              minHeight: 8,
              backgroundColor: _accColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(_accColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

// ─── Grupo por cadeira ────────────────────────────────────────────────────────

class _UCGroupSection extends StatelessWidget {
  final _UCGroup group;
  const _UCGroupSection({required this.group});

  @override
  Widget build(BuildContext context) {
    // Accuracy média da cadeira
    final totalAns = group.topics.fold(0, (s, t) => s + (t['total_answered'] as num).toInt());
    final totalCor = group.topics.fold(0, (s, t) => s + (t['correct_count']  as num).toInt());
    final ucAcc = totalAns > 0 ? (totalCor / totalAns * 100).toStringAsFixed(0) : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho da cadeira
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  group.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$ucAcc%',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        // Tópicos
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceSecondary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              for (int i = 0; i < group.topics.length; i++) ...[
                if (i > 0)
                  Divider(height: 1, color: Colors.grey.shade800, indent: 16, endIndent: 16),
                _TopicRow(
                  stat: group.topics[i],
                  isBest:  i == 0,
                  isWorst: i == group.topics.length - 1 && group.topics.length > 1,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Linha de tópico ──────────────────────────────────────────────────────────

class _TopicRow extends StatelessWidget {
  final Map<String, dynamic> stat;
  final bool isBest;
  final bool isWorst;
  const _TopicRow({required this.stat, required this.isBest, required this.isWorst});

  Color get _barColor {
    final acc = (stat['accuracy'] as num).toDouble();
    if (acc >= 80) return AppTheme.successState;
    if (acc >= 50) return AppTheme.warningState;
    return AppTheme.errorState;
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = (stat['accuracy'] as num).toDouble();
    final total    = (stat['total_answered'] as num).toInt();
    final correct  = (stat['correct_count']  as num).toInt();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        stat['topic_name'] as String,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isBest) ...[
                      const SizedBox(width: 6),
                      _Badge(label: 'Melhor', color: AppTheme.successState),
                    ] else if (isWorst) ...[
                      const SizedBox(width: 6),
                      _Badge(label: 'A melhorar', color: AppTheme.errorState),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${accuracy.toStringAsFixed(0)}%',
                    style: TextStyle(color: _barColor, fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '$correct/$total',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: accuracy / 100,
              minHeight: 5,
              backgroundColor: _barColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(_barColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
    );
  }
}
