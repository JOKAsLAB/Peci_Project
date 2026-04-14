import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/remote/student_repository.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/topic.dart';


// Classe que encapsula o estado dos filtros
class FeedFilters {
  final int? courseId;
  final String? topicName;
  final ExerciseDifficulty? difficulty;
  final ExerciseType? type;

  const FeedFilters({this.courseId, this.topicName, this.difficulty, this.type});
}

// Classe que encapsula o estado completo do ecrã
class FeedState {
  final FeedFilters filters;
  final List<Exercise> currentDeck;
  final int currentIndex;
  final int cycleSize;
  final int cycleNumber;
  final List<Topic> availableTopics;
  final bool isLoading;

  const FeedState({
    this.filters = const FeedFilters(),
    this.currentDeck = const [],
    this.currentIndex = 0,
    this.cycleSize = 0,
    this.cycleNumber = 1,
    this.availableTopics = const [],
    this.isLoading = false,
  });

  FeedState copyWith({
    FeedFilters? filters,
    List<Exercise>? currentDeck,
    int? currentIndex,
    int? cycleSize,
    int? cycleNumber,
    List<String>? availableTopics,
    bool? isLoading,
  }) {
    return FeedState(
      filters: filters ?? this.filters,
      currentDeck: currentDeck ?? this.currentDeck,
      currentIndex: currentIndex ?? this.currentIndex,
      cycleSize: cycleSize ?? this.cycleSize,
      cycleNumber: cycleNumber ?? this.cycleNumber,
      availableTopics: this.availableTopics,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// O controlador da lógica de negócio
class FeedNotifier extends StateNotifier<FeedState> {
  final StudentRepository _repo;

  FeedNotifier(this._repo) : super(const FeedState()) {
    loadExercises();
  }

  final _random = Random();

  Future<void> loadExercises() async {
    state = state.copyWith(isLoading: true);

    try {
      // 🔹 1. Carregar topics (se houver curso selecionado)
      if (state.filters.courseId != null) {
        final topics = await _repo.getTopics(state.filters.courseId!);

        state = state.copyWith(
          availableTopics: topics.map((t) => t.name).toList(),
        );
      }

      // 🔹 2. Carregar exercícios
      final exercises = await _repo.getExercises(
        idUc: state.filters.courseId,
        topicName: state.filters.topicName,
        difficulty: state.filters.difficulty?.name,
      );

      state = state.copyWith(
        currentDeck: _shuffleRound(exercises),
        cycleSize: exercises.length,
        currentIndex: 0,
        isLoading: false,
      );

    } catch (e) {
      print('🔴 Erro ao carregar exercícios: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  void updateCourseFilter(String? courseId) {
    state = state.copyWith(
      filters: FeedFilters(
        courseId: courseId != null ? int.tryParse(courseId) : null,
        topicName: state.filters.topicName,
        difficulty: state.filters.difficulty,
        type: state.filters.type,
      ),
    );
    loadExercises();
  }

  void updateTopicFilter(String? topic) {
    state = state.copyWith(
      filters: FeedFilters(
        courseId: state.filters.courseId,
        topicName: topic,
        difficulty: state.filters.difficulty,
        type: state.filters.type,
      ),
    );
    loadExercises();
  }

  void updateDifficultyFilter(ExerciseDifficulty? diff) {
    state = state.copyWith(
      filters: FeedFilters(courseId: state.filters.courseId, topicName: state.filters.topicName, difficulty: diff, type: state.filters.type),
    );
    loadExercises();
  }

  void updateTypeFilter(ExerciseType? type) {
    state = state.copyWith(
      filters: FeedFilters(courseId: state.filters.courseId, topicName: state.filters.topicName, difficulty: state.filters.difficulty, type: type),
    );
    loadExercises();
  }

  void clearFilters() {
    state = state.copyWith(filters: const FeedFilters());
    loadExercises();
  }

  void updateIndex(int index) {
    state = state.copyWith(currentIndex: index);
    _ensureDeckAhead();
  }

  List<Exercise> _shuffleRound(List<Exercise> source, {String? avoidFirstId}) {
    if (source.isEmpty) return const [];
    final round = List<Exercise>.from(source)..shuffle(_random);
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

  void _ensureDeckAhead() {
    if (state.currentDeck.isEmpty) return;
    final threshold = state.currentDeck.length - 3;
    if (state.currentIndex >= threshold) {
      final avoidFirstId = state.currentDeck.last.id;
      final source = state.currentDeck.sublist(0, state.cycleSize);
      final nextRound = _shuffleRound(source, avoidFirstId: avoidFirstId);
      state = state.copyWith(
        currentDeck: [...state.currentDeck, ...nextRound],
        cycleNumber: (state.currentIndex ~/ state.cycleSize) + 1,
      );
    }
  }
}

final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  return FeedNotifier(ref.watch(studentRepositoryProvider));
});