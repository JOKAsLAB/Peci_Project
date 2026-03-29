import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/mock_data.dart';

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
final profileStateProvider = Provider<ProfileState>((ref) {
  // Simulação de dados do Auth/User repository
  const studentName = 'Tiago Martins';
  const studentMec = '123456';
  const studentEmail = 'tiago.martins@ua.pt';
  const streakDays = 12;
  const xpPerExercise = 25;
  const streakMilestoneStep = 7;

  // Processamento O(N) extraído da UI
  final enrolled = mockCourses.where((c) => c.enrolled).toList();
  final completedChapters = enrolled
      .expand((c) => c.chapters)
      .where((ch) => ch.status == ChapterStatus.completed)
      .toList();
      
  final chapterXp = completedChapters.fold<int>(0, (sum, ch) => sum + ch.xpReward);
  final totalCompletedChapters = completedChapters.length;
  final totalExercises = enrolled
      .expand((c) => c.chapters)
      .fold<int>(0, (sum, ch) => sum + ch.completedExercises);

  final streakBonus = streakDays * 10;
  final nextStreakMilestone = ((streakDays ~/ streakMilestoneStep) + 1) * streakMilestoneStep;
  final streakProgress = (streakDays / nextStreakMilestone).clamp(0.0, 1.0);
  final exerciseXp = totalExercises * xpPerExercise;
  final totalXp = chapterXp + exerciseXp + streakBonus;

  // Algoritmo de determinação de nível
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
      nextThreshold = i < levels.length - 1 ? levels[i + 1].threshold : levels[i].threshold + 500;
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
    chapterXp: chapterXp,
    exerciseXp: exerciseXp,
    streakBonus: streakBonus,
    totalCompletedChapters: totalCompletedChapters,
    totalExercises: totalExercises,
    streakDays: streakDays,
    nextStreakMilestone: nextStreakMilestone,
    streakProgress: streakProgress,
    currentLevel: currentLevel,
    currentThreshold: currentThreshold,
    nextThreshold: nextThreshold,
    levelProgress: levelProgress,
    enrolledCourses: enrolled,
  );
});