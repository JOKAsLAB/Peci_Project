import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peci_project/data/models/exercise.dart';
import 'package:peci_project/data/models/learning_path.dart';
import 'package:peci_project/data/models/topic.dart';
import 'package:peci_project/data/remote/student_repository.dart';

/// Provider que vai buscar as disciplinas (course units) para os filtros.
final courseUnitsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  final studentRepository = ref.watch(studentRepositoryProvider);
  return studentRepository.getCourseUnits();
});

/// Provider que vai buscar os learning paths completos
final learningPathsProvider = FutureProvider<List<LearningPath>>((ref) async {
  final studentRepository = ref.watch(studentRepositoryProvider);
  return await studentRepository.getLearningPaths();
});

// Estado do feed de exercícios (modo exploração livre — sem limites)
@immutable
class FeedState {
  final List<Exercise> currentDeck;
  final int currentIndex;
  final FeedFilters filters;
  final List<Topic> availableTopics;
  final List<Map<String, dynamic>> availableCourses;
  final bool isLoading;

  const FeedState({
    this.currentDeck = const [],
    this.currentIndex = 0,
    this.filters = const FeedFilters(),
    this.availableTopics = const [],
    this.availableCourses = const [],
    this.isLoading = true,
  });

  FeedState copyWith({
    List<Exercise>? currentDeck,
    int? currentIndex,
    FeedFilters? filters,
    List<Topic>? availableTopics,
    List<Map<String, dynamic>>? availableCourses,
    bool? isLoading,
  }) {
    return FeedState(
      currentDeck: currentDeck ?? this.currentDeck,
      currentIndex: currentIndex ?? this.currentIndex,
      filters: filters ?? this.filters,
      availableTopics: availableTopics ?? this.availableTopics,
      availableCourses: availableCourses ?? this.availableCourses,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Filtros aplicados
@immutable
class FeedFilters {
  final int? courseId;
  final String? topicName;
  final ExerciseDifficulty? difficulty;
  final ExerciseType? type;

  const FeedFilters({
    this.courseId,
    this.topicName,
    this.difficulty,
    this.type,
  });

  FeedFilters copyWith({
    ValueGetter<int?>? courseId,
    ValueGetter<String?>? topicName,
    ValueGetter<ExerciseDifficulty?>? difficulty,
    ValueGetter<ExerciseType?>? type,
  }) {
    return FeedFilters(
      courseId: courseId != null ? courseId() : this.courseId,
      topicName: topicName != null ? topicName() : this.topicName,
      difficulty: difficulty != null ? difficulty() : this.difficulty,
      type: type != null ? type() : this.type,
    );
  }
}

// Notifier que gere o estado do feed (exploração livre)
class FeedNotifier extends Notifier<FeedState> {
  late final StudentRepository _studentRepository;

  @override
  FeedState build() {
    _studentRepository = ref.read(studentRepositoryProvider);
    Future.microtask(_init);
    return const FeedState();
  }

  Future<void> _init() async {
    await _fetchCourseUnits();
    await _fetchExercises();
  }

  Future<void> _fetchCourseUnits() async {
    final courses = await _studentRepository.getCourseUnits();
    state = state.copyWith(availableCourses: courses);
  }

  Future<void> _fetchExercises() async {
    state = state.copyWith(isLoading: true);
    final exercises = await _studentRepository.getExercises(
      courseId: state.filters.courseId,
      topicName: state.filters.topicName,
      difficulty: state.filters.difficulty,
      type: state.filters.type,
    );
    state = state.copyWith(
      currentDeck: exercises,
      currentIndex: 0,
      isLoading: false,
    );
    _updateAvailableTopics();
  }

  Future<void> _updateAvailableTopics() async {
    if (state.filters.courseId != null) {
      final topics = await _studentRepository.getTopics(state.filters.courseId!);
      state = state.copyWith(availableTopics: topics);
    } else {
      state = state.copyWith(availableTopics: []);
    }
  }

  void updateCourseFilter(int? courseId) {
    state = state.copyWith(
      filters: state.filters.copyWith(
        courseId: () => courseId,
        topicName: () => null,
      ),
    );
    if (courseId != null) {
      _loadTopicsFor(courseId);
    } else {
      state = state.copyWith(availableTopics: []);
    }
    _fetchExercises();
  }

  void updateTopicFilter(String? topicName) {
    state = state.copyWith(
      filters: state.filters.copyWith(topicName: () => topicName),
    );
    _fetchExercises();
  }

  void updateDifficultyFilter(ExerciseDifficulty? diff) {
    state = state.copyWith(
      filters: state.filters.copyWith(difficulty: () => diff),
    );
    _fetchExercises();
  }

  void updateTypeFilter(ExerciseType? type) {
    state = state.copyWith(
      filters: state.filters.copyWith(type: () => type),
    );
    _fetchExercises();
  }

  void applyFilters({
    required int? courseId,
    required String? topicName,
    required ExerciseDifficulty? difficulty,
    required ExerciseType? type,
  }) {
    state = state.copyWith(
      filters: FeedFilters(courseId: courseId, topicName: topicName, difficulty: difficulty, type: type),
    );
    if (courseId != null) {
      _loadTopicsFor(courseId);
    } else {
      state = state.copyWith(availableTopics: []);
    }
    _fetchExercises();
  }

  Future<void> _loadTopicsFor(int courseId) async {
    final topics = await _studentRepository.getTopics(courseId);
    state = state.copyWith(availableTopics: topics);
  }

  void clearFilters() {
    state = state.copyWith(
      filters: const FeedFilters(),
      availableTopics: [],
    );
    _fetchExercises();
  }

  void updateIndex(int index) {
    state = state.copyWith(currentIndex: index);
  }
}

final feedProvider = NotifierProvider<FeedNotifier, FeedState>(FeedNotifier.new);
