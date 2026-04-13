import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/remote/student_repository.dart';
import '../../../features/auth/providers/auth_provider.dart';

/// State holder que concentra os dados processados do perfil
class ProfileState {
  final String studentName;
  final String studentMec;
  final String studentEmail;
  final int totalXp;
  final int chapterXp;
  final int exerciseXp;
  final int streakBonus;
  final int totalCompletedChapters;
  final int totalExercises;
  final int streakDays;
  final int nextStreakMilestone;
  final double streakProgress;
  final String currentLevel;
  final int currentThreshold;
  final int nextThreshold;
  final double levelProgress;
  final List<Course> enrolledCourses;

  ProfileState({
    required this.studentName,
    required this.studentMec,
    required this.studentEmail,
    required this.totalXp,
    required this.chapterXp,
    required this.exerciseXp,
    required this.streakBonus,
    required this.totalCompletedChapters,
    required this.totalExercises,
    required this.streakDays,
    required this.nextStreakMilestone,
    required this.streakProgress,
    required this.currentLevel,
    required this.currentThreshold,
    required this.nextThreshold,
    required this.levelProgress,
    required this.enrolledCourses,
  });
}

/// Provider responsável pelo processamento assíncrono ou cached dos dados do utilizador.
final profileStateProvider = FutureProvider<ProfileState>((ref) async {
  final repo = ref.watch(studentRepositoryProvider);
  final authUser = ref.watch(authProvider).user;

  final profile = await repo.getProfile();
  final courses = await repo.getCourseUnits();
  final streakList = await repo.getStreak();

  final studentName = authUser?['name'] as String? ?? '';
  final studentEmail = authUser?['email'] as String? ?? '';
  final studentMec = '';

  final totalXp = profile['total_xp'] as int? ?? 0;
  final streakDays = profile['streak_days'] as int? ?? 0;

  const xpPerExercise = 25;
  const streakMilestoneStep = 7;
  final streakBonus = streakDays * 10;
  final nextStreakMilestone = ((streakDays ~/ streakMilestoneStep) + 1) * streakMilestoneStep;
  final streakProgress = (streakDays / nextStreakMilestone).clamp(0.0, 1.0);

  final levels = [
    (threshold: 0, label: 'N1'),
    (threshold: 100, label: 'N2'),
    (threshold: 300, label: 'N3'),
    (threshold: 600, label: 'N4'),
    (threshold: 1000, label: 'N5'),
    (threshold: 1500, label: 'N6'),
  ];

  String currentLevel = 'N1';
  int currentThreshold = 0;
  int nextThreshold = 100;

  for (int i = levels.length - 1; i >= 0; i--) {
    if (totalXp >= levels[i].threshold) {
      currentLevel = levels[i].label;
      currentThreshold = levels[i].threshold;
      nextThreshold = i < levels.length - 1
          ? levels[i + 1].threshold
          : levels[i].threshold + 500;
      break;
    }
  }

  final levelProgress = nextThreshold > currentThreshold
      ? ((totalXp - currentThreshold) / (nextThreshold - currentThreshold)).clamp(0.0, 1.0)
      : 1.0;

  return ProfileState(
    studentName: studentName,
    studentMec: studentMec,
    studentEmail: studentEmail,
    totalXp: totalXp,
    chapterXp: 0,
    exerciseXp: totalXp - streakBonus,
    streakBonus: streakBonus,
    totalCompletedChapters: 0,
    totalExercises: 0,
    streakDays: streakDays,
    nextStreakMilestone: nextStreakMilestone,
    streakProgress: streakProgress,
    currentLevel: currentLevel,
    currentThreshold: currentThreshold,
    nextThreshold: nextThreshold,
    levelProgress: levelProgress,
    enrolledCourses: [],
  );
});
