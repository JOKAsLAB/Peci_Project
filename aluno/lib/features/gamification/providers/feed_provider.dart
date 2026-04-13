import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/remote/student_repository.dart';

// Classe que encapsula o estado dos filtros
class FeedFilters {
  final int? courseId;
  final String? topicName;
  final String? difficulty;
  final String? type;

  const FeedFilters({this.courseId, this.topicName, this.difficulty, this.type});
}

// Classe que encapsula o estado completo do ecrã
class FeedState {
  final FeedFilters filters;
  final List<Map<String, dynamic>> currentDeck;
  final int currentIndex;
  final int cycleSize;
  final int cycleNumber;
  final List<Map<String, dynamic>> availableTopics;
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
    List<Map<String, dynamic>>? currentDeck,
    int? currentIndex,
    int? cycleSize,
    int? cycleNumber,
    List<Map<String, dynamic>>? availableTopics,
    bool? isLoading,
  }) {
    return FeedState(
      filters: filters ?? this.filters,
      currentDeck: currentDeck ?? this.currentDeck,
      currentIndex: currentIndex ?? this.currentIndex,
      cycleSize: cycleSize ?? this.cycleSize,
      cycleNumber: cycleNumber ?? this.cycleNumber,
      availableTopics: availableTopics ?? this.availableTopics,
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
      final exercises = await _repo.getExercises(
        idUc: state.filters.courseId,
        topicName: state.filters.topicName,
        difficulty: state.filters.difficulty,
      );
      state = state.copyWith(
        currentDeck: _shuffleRound(exercises.cast<Map<String, dynamic>>()),
        cycleSize: exercises.length,
        currentIndex: 0,
        isLoading: false,
      );
    } catch (e) {
      print('🔴 Erro ao carregar exercícios: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  void updateCourseFilter(int? courseId) {
    state = state.copyWith(
      filters: FeedFilters(courseId: courseId, difficulty: state.filters.difficulty, type: state.filters.type),
    );
    loadExercises();
  }

  void updateDifficultyFilter(String? diff) {
    state = state.copyWith(
      filters: FeedFilters(courseId: state.filters.courseId, topicName: state.filters.topicName, difficulty: diff, type: state.filters.type),
    );
    loadExercises();
  }

  void updateTypeFilter(String? type) {
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

  List<Map<String, dynamic>> _shuffleRound(List<Map<String, dynamic>> source, {String? avoidFirstId}) {
    if (source.isEmpty) return const [];
    final round = List<Map<String, dynamic>>.from(source)..shuffle(_random);
    if (round.length > 1 && avoidFirstId != null && round.first['id_exercise'] == avoidFirstId) {
      final swapIndex = round.indexWhere((e) => e['id_exercise'] != avoidFirstId);
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
      final avoidFirstId = state.currentDeck.last['id_exercise'] as String?;
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