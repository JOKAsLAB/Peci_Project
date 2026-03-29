import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/mock_data.dart';

// Classe que encapsula o estado dos filtros
class FeedFilters {
  final String? courseId;
  final String? chapterId;
  final ExerciseDifficulty? difficulty;
  final ExerciseType? type;

  const FeedFilters({this.courseId, this.chapterId, this.difficulty, this.type});
}

// Classe que encapsula o estado completo do ecrã
class FeedState {
  final FeedFilters filters;
  final List<MockExercise> currentDeck;
  final int currentIndex;
  final int cycleSize;
  final int cycleNumber;
  final List<Chapter> availableChapters;

  const FeedState({
    this.filters = const FeedFilters(),
    this.currentDeck = const [],
    this.currentIndex = 0,
    this.cycleSize = 0,
    this.cycleNumber = 1,
    this.availableChapters = const [],
  });

  FeedState copyWith({
    FeedFilters? filters,
    List<MockExercise>? currentDeck,
    int? currentIndex,
    int? cycleSize,
    int? cycleNumber,
    List<Chapter>? availableChapters,
  }) {
    return FeedState(
      filters: filters ?? this.filters,
      currentDeck: currentDeck ?? this.currentDeck,
      currentIndex: currentIndex ?? this.currentIndex,
      cycleSize: cycleSize ?? this.cycleSize,
      cycleNumber: cycleNumber ?? this.cycleNumber,
      availableChapters: availableChapters ?? this.availableChapters,
    );
  }
}

// O controlador da lógica de negócio
class FeedNotifier extends StateNotifier<FeedState> {
  FeedNotifier() : super(const FeedState()) {
    _applyFilters(); // Inicializa o baralho no arranque
  }

  final _random = Random();

  void updateCourseFilter(String? courseId) {
    state = state.copyWith(
      filters: FeedFilters(
        courseId: courseId,
        chapterId: null, // Reset ao capítulo se mudar de curso
        difficulty: state.filters.difficulty,
        type: state.filters.type,
      ),
    );
    _applyFilters();
  }

  void updateChapterFilter(String? chapterId) {
    state = state.copyWith(filters: FeedFilters(
      courseId: state.filters.courseId, chapterId: chapterId, difficulty: state.filters.difficulty, type: state.filters.type,
    ));
    _applyFilters();
  }

  void updateDifficultyFilter(ExerciseDifficulty? diff) {
    state = state.copyWith(filters: FeedFilters(
      courseId: state.filters.courseId, chapterId: state.filters.chapterId, difficulty: diff, type: state.filters.type,
    ));
    _applyFilters();
  }

  void updateTypeFilter(ExerciseType? type) {
    state = state.copyWith(filters: FeedFilters(
      courseId: state.filters.courseId, chapterId: state.filters.chapterId, difficulty: state.filters.difficulty, type: type,
    ));
    _applyFilters();
  }

  void clearFilters() {
    state = state.copyWith(filters: const FeedFilters());
    _applyFilters();
  }

  void updateIndex(int index) {
    state = state.copyWith(currentIndex: index);
    _ensureDeckAhead();
  }

  List<MockExercise> _getFilteredSource() {
    var exercises = mockExercises;
    if (state.filters.courseId != null) exercises = exercises.where((e) => e.courseId == state.filters.courseId).toList();
    if (state.filters.chapterId != null) exercises = exercises.where((e) => e.chapterId == state.filters.chapterId).toList();
    if (state.filters.difficulty != null) exercises = exercises.where((e) => e.difficulty == state.filters.difficulty).toList();
    if (state.filters.type != null) exercises = exercises.where((e) => e.type == state.filters.type).toList();
    return exercises;
  }

  List<MockExercise> _shuffleRound(List<MockExercise> source, {String? avoidFirstId}) {
    if (source.isEmpty) return const [];
    final round = List<MockExercise>.from(source)..shuffle(_random);
    if (round.length > 1 && avoidFirstId != null && round.first.id == avoidFirstId) {
      final swapIndex = round.indexWhere((e) => e.id != avoidFirstId);
      if (swapIndex > 0) {
        final first = round.first;
        round[0] = round[swapIndex];
        round[swapIndex] = first;
      }
    }
    return round;
  }

  void _applyFilters() {
    final source = _getFilteredSource();
    
    // Calcula os capítulos disponíveis com base no curso selecionado
    List<Chapter> chapters = [];
    if (state.filters.courseId != null) {
      chapters = mockCourses.firstWhere((c) => c.id == state.filters.courseId).chapters;
    }

    state = state.copyWith(
      currentDeck: _shuffleRound(source),
      currentIndex: 0,
      cycleSize: source.length,
      availableChapters: chapters,
    );
  }

  void _ensureDeckAhead() {
    final source = _getFilteredSource();
    if (source.isEmpty) return;

    final threshold = state.currentDeck.length - 3;
    if (state.currentIndex >= threshold) {
      final avoidFirstId = state.currentDeck.isNotEmpty ? state.currentDeck.last.id : null;
      final nextRound = _shuffleRound(source, avoidFirstId: avoidFirstId);
      
      state = state.copyWith(
        currentDeck: [...state.currentDeck, ...nextRound],
        cycleNumber: (state.currentIndex ~/ state.cycleSize) + 1,
      );
    }
  }
}

final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) => FeedNotifier());