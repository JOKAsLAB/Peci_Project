import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/student_profile.dart';
import '../../features/profile/providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileStateProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppTheme.backgroundPrimary,
        body: Center(child: CircularProgressIndicator(color: AppTheme.brandAccent)),
      ),
      error: (e, stack) => Scaffold(
        backgroundColor: AppTheme.backgroundPrimary,
        appBar: AppBar(
          title: const Text('Perfil'),
          backgroundColor: AppTheme.surfaceSecondary,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppTheme.errorState, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Erro ao carregar perfil:\n$e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(profileStateProvider),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Tentar de novo'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (profile) => _ProfileView(profile: profile, onRefresh: () => ref.invalidate(profileStateProvider)),
    );
  }
}

class _ProfileView extends StatelessWidget {
  final StudentProfile profile;
  final VoidCallback? onRefresh;
  const _ProfileView({required this.profile, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final nextMilestone = ((profile.streakDays ~/ 7) + 1) * 7;
    final streakProgress = (profile.streakDays / nextMilestone).clamp(0.0, 1.0);
    final initials = profile.name.isNotEmpty
        ? profile.name.trim().split(' ').take(2).map((w) => w[0]).join().toUpperCase()
        : '?';

      return Scaffold(
        backgroundColor: AppTheme.backgroundPrimary,
        appBar: AppBar(
          title: const Text('Perfil', style: TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: AppTheme.surfaceSecondary,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: AppTheme.textSecondary),
              onPressed: () => context.push('/settings'),
            ),
          ],
        ),
        body: RefreshIndicator(
          color: AppTheme.brandAccent,
          onRefresh: () async => onRefresh?.call(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),

                // ── Avatar + nome ──────────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.brandAccent, width: 3),
                  ),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: AppTheme.brandAccent.withValues(alpha: 0.15),
                    child: Text(initials, style: const TextStyle(color: AppTheme.brandAccent, fontSize: 28, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  profile.name.isNotEmpty ? profile.name : 'Aluno',
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD54F).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events_rounded, size: 14, color: Color(0xFFFFD54F)),
                      const SizedBox(width: 5),
                      Text(
                        'Nível ${profile.currentLevel}',
                        style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Streak card ────────────────────────────────────────────────
                _StreakCard(streakDays: profile.streakDays, nextMilestone: nextMilestone, progress: streakProgress),
                const SizedBox(height: 12),

                // ── Stats grid ────────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(child: _StatCard(icon: Icons.bolt_rounded, value: '${profile.totalXp}', label: 'XP Total', color: AppTheme.successState)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(icon: Icons.local_fire_department_rounded, value: '${profile.streakDays}', label: 'Streak', color: const Color(0xFFFF7043))),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(icon: Icons.emoji_events_rounded, value: 'N${profile.currentLevel}', label: 'Nível', color: const Color(0xFFFFD54F))),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Barra de nível ────────────────────────────────────────────
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
                          const Text('Progresso para o próximo nível',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          Text(
                            '${profile.xpInCurrentLevel} / ${profile.xpForNextLevel} XP',
                            style: const TextStyle(color: AppTheme.brandAccent, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: profile.levelProgress,
                          backgroundColor: Colors.grey.shade800,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD54F)),
                          minHeight: 10,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Nível ${profile.currentLevel}',
                              style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 11, fontWeight: FontWeight.w700)),
                          Text('Nível ${profile.currentLevel + 1}',
                              style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.7), fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      );
  }
}

// ─── Streak Card ──────────────────────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  final int streakDays;
  final int nextMilestone;
  final double progress;
  const _StreakCard({required this.streakDays, required this.nextMilestone, required this.progress});

  @override
  Widget build(BuildContext context) {
    final remaining = (nextMilestone - streakDays).clamp(0, nextMilestone);
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
                child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Streak diária', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    Text('$streakDays dias seguidos', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const Text('Não pares! 🔥', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.28),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            remaining == 0 ? 'Marco de $nextMilestone dias atingido! 🎉' : 'Faltam $remaining dias para o marco de $nextMilestone dias.',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatCard({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: AppTheme.surfaceSecondary, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}
