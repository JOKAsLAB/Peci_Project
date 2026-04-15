class StudentProfile {
  final String id;
  final String name;
  final int currentLevel;
  final int totalXp;
  final int streakDays;
  final int xpForNextLevel;
  final int xpInCurrentLevel;

  const StudentProfile({
    required this.id,
    required this.name,
    required this.currentLevel,
    required this.totalXp,
    required this.streakDays,
    required this.xpForNextLevel,
    required this.xpInCurrentLevel,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: (json['id_student'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      currentLevel: (json['current_level'] as num? ?? 1).toInt(),
      totalXp: (json['total_xp'] as num? ?? 0).toInt(),
      streakDays: (json['streak_days'] as num? ?? 0).toInt(),
      xpForNextLevel: (json['xp_for_next_level'] as num? ?? 100).toInt(),
      xpInCurrentLevel: (json['xp_in_current_level'] as num? ?? 0).toInt(),
    );
  }

  double get levelProgress =>
      xpForNextLevel > 0 ? (xpInCurrentLevel / xpForNextLevel).clamp(0.0, 1.0) : 0.0;
}

class ProgressResult {
  final int xpEarned;
  final int newTotalXp;
  final int newLevel;
  final bool levelUp;
  final int streakDays;

  const ProgressResult({
    required this.xpEarned,
    required this.newTotalXp,
    required this.newLevel,
    required this.levelUp,
    required this.streakDays,
  });

  factory ProgressResult.fromJson(Map<String, dynamic> json) {
    return ProgressResult(
      xpEarned: (json['xp_earned'] as num? ?? 0).toInt(),
      newTotalXp: (json['new_total_xp'] as num? ?? 0).toInt(),
      newLevel: (json['new_level'] as num? ?? 1).toInt(),
      levelUp: json['level_up'] as bool? ?? false,
      streakDays: (json['streak_days'] as num? ?? 0).toInt(),
    );
  }
}
