import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/mock_data.dart';
import '../../features/profile/providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileStateProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const Scaffold(
        body: Center(child: Text('Erro ao carregar perfil')),
      ),
      data: (p) => _buildProfile(context, p),
    );
  }

  Widget _buildProfile(BuildContext context, ProfileState p) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title:
            const Text('Perfil', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.surfaceSecondary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: AppTheme.textSecondary),
            onPressed: () => context.push('/settings'),
            tooltip: 'Definições',
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            // Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.brandAccent, width: 3),
              ),
              child: const CircleAvatar(
                radius: 52,
                backgroundColor: AppTheme.surfaceSecondary,
                child:
                    Icon(Icons.person, size: 52, color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              p.studentName,
              style: Theme.of(context)
                  .textTheme
                  .displayLarge
                  ?.copyWith(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSecondary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.badge_outlined,
                      size: 16, color: AppTheme.brandAccent),
                  const SizedBox(width: 6),
                  Text(
                    'NMec ${p.studentMec}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.email_outlined,
                      size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    p.studentEmail,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            _StreakHighlightCard(
              streakDays: p.streakDays,
              nextMilestone: p.nextStreakMilestone,
              progress: p.streakProgress,
            ),

            const SizedBox(height: 12),

            // Estatísticas gerais
            Row(
              children: [
                Expanded(
                    child: _StatCard(
                  icon: Icons.star_rounded,
                  value: '${p.totalXp} XP',
                  label: 'XP Total',
                  color: AppTheme.successState,
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: _StatCard(
                  icon: Icons.check_circle_rounded,
                  value: '${p.totalCompletedChapters}',
                  label: 'Capítulos',
                  color: AppTheme.brandAccent,
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: _StatCard(
                  icon: Icons.task_alt_rounded,
                  value: '${p.totalExercises}',
                  label: 'Exercícios',
                  color: const Color(0xFF64B5F6),
                )),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _StatCard(
                  icon: Icons.local_fire_department_rounded,
                  value: '${p.streakDays} dias',
                  label: 'Streak',
                  color:const Color(0xFFFF7043),
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: _StatCard(
                  icon: Icons.school_rounded,
                  value: '${p.enrolledCourses.length}',
                  label: 'Cursos',
                  color: const Color(0xFFAB47BC),
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: _StatCard(
                  icon: Icons.emoji_events_rounded,
                  value: p.currentLevel,
                  label: 'Nível',
                  color: const Color(0xFFFFD54F),
                )),
              ],
            ),

            // Level progress bar
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSecondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Progresso para o próximo nível',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                      ),
                      Text(
                        '${p.totalXp - p.currentThreshold} / ${p.nextThreshold - p.currentThreshold} XP',
                        style: const TextStyle(
                            color: AppTheme.brandAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: p.levelProgress,
                      backgroundColor: Colors.grey.shade800,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFFFD54F)),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(p.currentLevel,
                          style: const TextStyle(
                              color: Color(0xFFFFD54F),
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                      Text(
                        p.currentLevel != 'N6'
                            ? p.levels[p.levels.indexWhere(
                                        (l) => l.label == p.currentLevel) +
                                    1]
                                .label
                            : 'MAX',
                        style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // XP Breakdown
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSecondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Fontes de XP',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  _XpSourceRow(
                      icon: Icons.menu_book_rounded,
                      label: 'Capítulos completados',
                      xp: p.chapterXp,
                      color: AppTheme.brandAccent),
                  const SizedBox(height: 8),
                  _XpSourceRow(
                      icon: Icons.task_alt_rounded,
                      label:
                          'Exercícios resolvidos ($p.totalExercises × ${p.xpPerExercise}XP)',
                      xp: p.exerciseXp,
                      color: const Color(0xFF64B5F6)),
                  const SizedBox(height: 8),
                  _XpSourceRow(
                      icon: Icons.local_fire_department_rounded,
                      label: 'Bónus de streak ($p.streakDays dias × 10XP)',
                      xp: p.streakBonus,
                      color:  const Color(0xFFFF7043)),
                  const Divider(color: Colors.grey, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total',
                          style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                      Text('$p.totalXp XP',
                          style: const TextStyle(
                              color: AppTheme.successState,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Cursos inscritos
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Cursos Inscritos',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...mockCourses
                .where((c) => c.enrolled)
                .map((course) => _CourseProgressTile(course: course)),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _StreakHighlightCard extends StatelessWidget {
  final int streakDays;
  final int nextMilestone;
  final double progress;

  const _StreakHighlightCard({
    required this.streakDays,
    required this.nextMilestone,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final remainingDays = (nextMilestone - streakDays).clamp(0, nextMilestone);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6A3D), Color(0xFFFFB25C)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Streak diária',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '$streakDays dias seguidos',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const Text(
                'Nao pares',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Abre a app todos os dias para manter o ritmo e acelerar o ganho de XP.',
            style: TextStyle(color: Colors.white, fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.28),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Faltam $remainingDays dias para o marco de $nextMilestone dias.',
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _CourseProgressTile extends StatelessWidget {
  final Course course;

  const _CourseProgressTile({required this.course});

  @override
  Widget build(BuildContext context) {
    final progressPercent = (course.progress * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.brandAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                course.shortName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.brandAccent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: course.progress,
                    backgroundColor: Colors.grey.shade800,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.brandAccent),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$progressPercent%',
            style: const TextStyle(
              color: AppTheme.brandAccent,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _XpSourceRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int xp;
  final Color color;

  const _XpSourceRow(
      {required this.icon,
      required this.label,
      required this.xp,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12))),
        Text('+$xp XP',
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
