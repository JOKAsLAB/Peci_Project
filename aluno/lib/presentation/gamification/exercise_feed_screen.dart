import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peci_project/data/models/topic.dart';
import '../../core/theme/app_theme.dart';
import '../shared/tutor_chat_dialog.dart';
import '../../features/gamification/providers/feed_provider.dart';
import '../../data/models/exercise.dart';
import '../../data/remote/student_repository.dart';

class ExerciseFeedScreen extends ConsumerStatefulWidget {
  const ExerciseFeedScreen({super.key});

  @override
  ConsumerState<ExerciseFeedScreen> createState() => _ExerciseFeedScreenState();
}

class _ExerciseFeedScreenState extends ConsumerState<ExerciseFeedScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: ref.read(feedProvider).currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _syncPageController(int newIndex) {
    if (_pageController.hasClients && _pageController.page?.round() != newIndex) {
      _pageController.jumpToPage(newIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);
    final feedNotifier = ref.read(feedProvider.notifier);

    ref.listen<FeedState>(feedProvider, (previous, next) {
      if (previous?.currentIndex != next.currentIndex) {
        _syncPageController(next.currentIndex);
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: _CompactFilterBar(
              selectedCourseId: feedState.filters.courseId,
              selectedTopicName: feedState.filters.topicName,
              selectedDifficulty: feedState.filters.difficulty,
              selectedType: feedState.filters.type,
              availableCourses: feedState.availableCourses,
              availableTopics: feedState.availableTopics,
              currentIndex: feedState.currentIndex + 1,
              totalExercises: feedState.currentDeck.length,
              onCourseChanged: feedNotifier.updateCourseFilter,
              onTopicChanged: feedNotifier.updateTopicFilter,
              onDifficultyChanged: feedNotifier.updateDifficultyFilter,
              onTypeChanged: feedNotifier.updateTypeFilter,
              onClearFilters: feedNotifier.clearFilters,
              onApplyAll: ({required courseId, required topicName, required difficulty, required type}) =>
                  feedNotifier.applyFilters(courseId: courseId, topicName: topicName, difficulty: difficulty, type: type),
              onLoadTopics: ref.read(studentRepositoryProvider).getTopics,
            ),
          ),
          Expanded(
            child: feedState.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.brandAccent))
                : feedState.currentDeck.isEmpty
                    ? _EmptyState(hasFilters: feedState.filters.courseId != null || feedState.filters.difficulty != null || feedState.filters.type != null)
                    : PageView.builder(
                        controller: _pageController,
                        scrollDirection: Axis.vertical,
                        physics: const PageScrollPhysics(parent: ClampingScrollPhysics()),
                        itemCount: feedState.currentDeck.length,
                        onPageChanged: (index) => feedNotifier.updateIndex(index),
                        itemBuilder: (context, index) {
                          final exercise = feedState.currentDeck[index];
                          return _ExerciseFeedCard(
                            key: ValueKey('${exercise.id}_$index'),
                            exercise: exercise,
                            onProgress: null,
                            onReport: (id) => ref.read(studentRepositoryProvider).reportExercise(id),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── Barra de Filtros Compacta ────────────────────────────────────────────────
class _CompactFilterBar extends StatelessWidget {
  final int? selectedCourseId;
  final String? selectedTopicName;
  final ExerciseDifficulty? selectedDifficulty;
  final ExerciseType? selectedType;
  final List<Map<String, dynamic>> availableCourses;
  final List<Topic> availableTopics;
  final int currentIndex;
  final int totalExercises;
  final ValueChanged<int?> onCourseChanged;
  final ValueChanged<String?> onTopicChanged;
  final ValueChanged<ExerciseDifficulty?> onDifficultyChanged;
  final ValueChanged<ExerciseType?> onTypeChanged;
  final VoidCallback onClearFilters;
  final _ApplyCallback onApplyAll;
  final Future<List<Topic>> Function(int courseId) onLoadTopics;

  const _CompactFilterBar({
    required this.selectedCourseId,
    required this.selectedTopicName,
    required this.selectedDifficulty,
    required this.selectedType,
    required this.availableCourses,
    required this.availableTopics,
    required this.currentIndex,
    required this.totalExercises,
    required this.onCourseChanged,
    required this.onTopicChanged,
    required this.onDifficultyChanged,
    required this.onTypeChanged,
    required this.onClearFilters,
    required this.onApplyAll,
    required this.onLoadTopics,
  });

  bool get _hasActiveFilters =>
      selectedCourseId != null || selectedDifficulty != null || selectedType != null || selectedTopicName != null;

  int get _activeFilterCount {
    int count = 0;
    if (selectedCourseId != null) count++;
    if (selectedTopicName != null) count++;
    if (selectedDifficulty != null) count++;
    if (selectedType != null) count++;
    return count;
  }

  String? get _courseName => availableCourses
      .where((c) => c['id_uc'] == selectedCourseId)
      .map((c) => c['name'] as String)
      .firstOrNull;

  String? get _difficultyLabel => switch (selectedDifficulty) {
        ExerciseDifficulty.easy   => 'Fácil',
        ExerciseDifficulty.medium => 'Médio',
        ExerciseDifficulty.hard   => 'Difícil',
        null                      => null,
      };

  String? get _typeLabel => switch (selectedType) {
        ExerciseType.multipleChoice => 'Escolha Múltipla',
        ExerciseType.trueFalse      => 'V / F',
        null                        => null,
      };

  @override
  Widget build(BuildContext context) {
    final tags = <String>[
      if (_courseName != null) _courseName!,
      if (selectedTopicName != null) selectedTopicName!,
      if (_difficultyLabel != null) _difficultyLabel!,
      if (_typeLabel != null) _typeLabel!,
    ];

    return Container(
      color: AppTheme.surfaceSecondary,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 4, 6),
            child: Row(
              children: [
                const Text(
                  'Prática',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                if (totalExercises > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.brandAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.brandAccent.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      '$currentIndex/$totalExercises',
                      style: const TextStyle(color: AppTheme.brandAccent, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                const Spacer(),
                if (_hasActiveFilters)
                  GestureDetector(
                    onTap: onClearFilters,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.errorState.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.close_rounded, size: 12, color: AppTheme.errorState),
                          const SizedBox(width: 3),
                          Text(
                            'Limpar ($_activeFilterCount)',
                            style: const TextStyle(color: AppTheme.errorState, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                IconButton(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.tune_rounded, color: AppTheme.textSecondary, size: 22),
                      if (_hasActiveFilters)
                        Positioned(
                          top: -3,
                          right: -3,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: AppTheme.brandAccent, shape: BoxShape.circle),
                          ),
                        ),
                    ],
                  ),
                  onPressed: () => _showFilterSheet(context),
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 36),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          if (tags.isNotEmpty) ...[
            SizedBox(
              height: 30,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: tags
                    .map((t) => Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.brandAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.brandAccent, width: 1.2),
                          ),
                          child: Text(
                            t,
                            style: const TextStyle(color: AppTheme.brandAccent, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
          ] else
            const SizedBox(height: 6),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceSecondary,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (_) => _FilterSheet(
        selectedCourseId: selectedCourseId,
        selectedTopicName: selectedTopicName,
        selectedDifficulty: selectedDifficulty,
        selectedType: selectedType,
        availableCourses: availableCourses,
        initialTopics: availableTopics,
        onApply: onApplyAll,
        onClearFilters: onClearFilters,
        onLoadTopics: onLoadTopics,
      ),
    );
  }
}

// ─── Bottom Sheet de Filtros ──────────────────────────────────────────────────
typedef _ApplyCallback = void Function({
  required int? courseId,
  required String? topicName,
  required ExerciseDifficulty? difficulty,
  required ExerciseType? type,
});

class _FilterSheet extends StatefulWidget {
  final int? selectedCourseId;
  final String? selectedTopicName;
  final ExerciseDifficulty? selectedDifficulty;
  final ExerciseType? selectedType;
  final List<Map<String, dynamic>> availableCourses;
  final List<Topic> initialTopics;
  final _ApplyCallback onApply;
  final VoidCallback onClearFilters;
  final Future<List<Topic>> Function(int courseId) onLoadTopics;

  const _FilterSheet({
    required this.selectedCourseId,
    required this.selectedTopicName,
    required this.selectedDifficulty,
    required this.selectedType,
    required this.availableCourses,
    required this.initialTopics,
    required this.onApply,
    required this.onClearFilters,
    required this.onLoadTopics,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _subPage;

  late int? _tempCourseId;
  late String? _tempTopicName;
  late ExerciseDifficulty? _tempDifficulty;
  late ExerciseType? _tempType;

  List<Topic> _sheetTopics = [];
  bool _loadingTopics = false;

  @override
  void initState() {
    super.initState();
    _tempCourseId   = widget.selectedCourseId;
    _tempTopicName  = widget.selectedTopicName;
    _tempDifficulty = widget.selectedDifficulty;
    _tempType       = widget.selectedType;
    _sheetTopics    = widget.initialTopics;
  }

  Future<void> _loadTopicsFor(int courseId) async {
    setState(() => _loadingTopics = true);
    try {
      final topics = await widget.onLoadTopics(courseId);
      if (mounted) setState(() { _sheetTopics = topics; _loadingTopics = false; });
    } catch (_) {
      if (mounted) setState(() { _sheetTopics = []; _loadingTopics = false; });
    }
  }

  String? get _courseName => widget.availableCourses
      .where((c) => c['id_uc'] == _tempCourseId)
      .map((c) => c['name'] as String)
      .firstOrNull;

  String? get _difficultyName => switch (_tempDifficulty) {
        ExerciseDifficulty.easy   => 'Fácil',
        ExerciseDifficulty.medium => 'Médio',
        ExerciseDifficulty.hard   => 'Difícil',
        null                      => null,
      };

  String? get _typeName => switch (_tempType) {
        ExerciseType.multipleChoice => 'Escolha Múltipla',
        ExerciseType.trueFalse      => 'V / F',
        null                        => null,
      };

  bool get _hasAnyFilter =>
      _tempCourseId != null ||
      _tempTopicName != null ||
      _tempDifficulty != null ||
      _tempType != null;

  void _applyFilters() {
    widget.onApply(
      courseId: _tempCourseId,
      topicName: _tempTopicName,
      difficulty: _tempDifficulty,
      type: _tempType,
    );
    Navigator.pop(context);
  }

  void _clearAll() {
    setState(() {
      _tempCourseId   = null;
      _tempTopicName  = null;
      _tempDifficulty = null;
      _tempType       = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
        child: _subPage == null ? _buildMain(context) : _buildSub(context, _subPage!),
      ),
    );
  }

  Widget _buildMain(BuildContext context) {
    return Column(
      key: const ValueKey('main'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _Handle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
          child: Row(
            children: [
              const Text('Filtros', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        _FilterRow(
          label: 'Disciplina',
          value: _courseName,
          onTap: () => setState(() => _subPage = 'course'),
        ),
        _Divider(),
        _FilterRow(
          label: 'Tópico',
          value: _tempTopicName,
          disabled: _tempCourseId == null,
          onTap: () { if (_tempCourseId != null) setState(() => _subPage = 'topic'); },
        ),
        _Divider(),
        _FilterRow(
          label: 'Tipo',
          value: _typeName,
          onTap: () => setState(() => _subPage = 'type'),
        ),
        _Divider(),
        _FilterRow(
          label: 'Dificuldade',
          value: _difficultyName,
          onTap: () => setState(() => _subPage = 'difficulty'),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _hasAnyFilter ? _clearAll : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorState,
                    side: BorderSide(color: _hasAnyFilter ? AppTheme.errorState : Colors.grey.shade700),
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Limpar tudo'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Aplicar'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSub(BuildContext context, String page) {
    final String title;
    final List<_FilterOption> options;

    switch (page) {
      case 'course':
        title = 'Disciplina';
        options = [
          _FilterOption(label: 'Todas', isSelected: _tempCourseId == null,
              onTap: () => setState(() { _tempCourseId = null; _tempTopicName = null; _sheetTopics = []; _subPage = null; })),
          ...widget.availableCourses.map((c) => _FilterOption(
                label: c['name'] as String,
                isSelected: _tempCourseId == c['id_uc'],
                onTap: () {
                  final newId = _tempCourseId == c['id_uc'] ? null : c['id_uc'] as int;
                  setState(() { _tempCourseId = newId; _tempTopicName = null; _subPage = null; });
                  if (newId != null) _loadTopicsFor(newId);
                },
              )),
        ];
      case 'topic':
        title = 'Tópico';
        options = [
          _FilterOption(label: 'Todos', isSelected: _tempTopicName == null,
              onTap: () => setState(() { _tempTopicName = null; _subPage = null; })),
          ..._sheetTopics.map((t) => _FilterOption(
                label: t.name,
                isSelected: _tempTopicName == t.name,
                onTap: () => setState(() {
                  _tempTopicName = _tempTopicName == t.name ? null : t.name;
                  _subPage = null;
                }),
              )),
        ];
      case 'difficulty':
        title = 'Dificuldade';
        options = [
          _FilterOption(label: 'Fácil', isSelected: _tempDifficulty == ExerciseDifficulty.easy, color: AppTheme.successState,
              onTap: () => setState(() { _tempDifficulty = _tempDifficulty == ExerciseDifficulty.easy ? null : ExerciseDifficulty.easy; _subPage = null; })),
          _FilterOption(label: 'Médio', isSelected: _tempDifficulty == ExerciseDifficulty.medium, color: AppTheme.warningState,
              onTap: () => setState(() { _tempDifficulty = _tempDifficulty == ExerciseDifficulty.medium ? null : ExerciseDifficulty.medium; _subPage = null; })),
          _FilterOption(label: 'Difícil', isSelected: _tempDifficulty == ExerciseDifficulty.hard, color: AppTheme.errorState,
              onTap: () => setState(() { _tempDifficulty = _tempDifficulty == ExerciseDifficulty.hard ? null : ExerciseDifficulty.hard; _subPage = null; })),
        ];
      default: // 'type'
        title = 'Tipo';
        options = [
          _FilterOption(label: 'Escolha Múltipla', isSelected: _tempType == ExerciseType.multipleChoice,
              onTap: () => setState(() { _tempType = _tempType == ExerciseType.multipleChoice ? null : ExerciseType.multipleChoice; _subPage = null; })),
          _FilterOption(label: 'Verdadeiro / Falso', isSelected: _tempType == ExerciseType.trueFalse,
              onTap: () => setState(() { _tempType = _tempType == ExerciseType.trueFalse ? null : ExerciseType.trueFalse; _subPage = null; })),
        ];
    }

    return ConstrainedBox(
      key: ValueKey('sub_$page'),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Handle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 8, 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textSecondary, size: 22),
                  onPressed: () => setState(() => _subPage = null),
                ),
                Expanded(
                  child: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          if (page == 'topic' && _loadingTopics)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(color: AppTheme.brandAccent, strokeWidth: 2)),
            )
          else if (page == 'topic' && _sheetTopics.isEmpty && !_loadingTopics)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Sem tópicos disponíveis.', style: TextStyle(color: AppTheme.textSecondary))),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: options.length,
                separatorBuilder: (_, __) => _Divider(),
                itemBuilder: (_, i) {
                  final opt = options[i];
                  return InkWell(
                    onTap: opt.onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: opt.isSelected
                                  ? (opt.color ?? AppTheme.brandAccent).withValues(alpha: 0.2)
                                  : Colors.grey.shade800,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                opt.label[0].toUpperCase(),
                                style: TextStyle(
                                  color: opt.isSelected ? (opt.color ?? AppTheme.brandAccent) : AppTheme.textSecondary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              opt.label,
                              style: TextStyle(
                                color: opt.isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                                fontSize: 15,
                                fontWeight: opt.isSelected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: opt.isSelected ? (opt.color ?? AppTheme.brandAccent) : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: opt.isSelected ? (opt.color ?? AppTheme.brandAccent) : Colors.grey.shade600,
                                width: 2,
                              ),
                            ),
                            child: opt.isSelected
                                ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Auxiliares ───────────────────────────────────────────────────────────────
class _FilterOption {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;
  _FilterOption({required this.label, required this.isSelected, required this.onTap, this.color});
}

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 10, bottom: 4),
        width: 40,
        height: 4,
        decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(2)),
      );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, color: Colors.grey.shade800, indent: 20, endIndent: 20);
}

class _FilterRow extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;
  final bool disabled;

  const _FilterRow({required this.label, this.value, required this.onTap, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: disabled ? AppTheme.textSecondary.withValues(alpha: 0.4) : AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (value != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(value!, style: const TextStyle(color: AppTheme.brandAccent, fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            Icon(
              Icons.chevron_right_rounded,
              color: disabled ? AppTheme.textSecondary.withValues(alpha: 0.3) : AppTheme.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;
  final bool small;

  const _Chip({required this.label, required this.isSelected, required this.onTap, this.color, this.small = false});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.brandAccent;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: small ? 10 : 12, vertical: small ? 5 : 7),
          decoration: BoxDecoration(
            color: isSelected ? c.withValues(alpha: 0.18) : AppTheme.backgroundPrimary,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? c : Colors.grey.shade800,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? c : AppTheme.textPrimary,
              fontSize: small ? 11 : 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Estado Vazio ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  const _EmptyState({required this.hasFilters});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasFilters ? Icons.filter_alt_off_rounded : Icons.quiz_outlined,
              size: 56,
              color: AppTheme.textSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'Nenhum exercício para estes filtros.' : 'Ainda não há exercícios disponíveis.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Card de Exercício ────────────────────────────────────────────────────────
typedef _ProgressCallback = Future<void> Function(
  String exerciseId,
  bool isCorrect,
  ExerciseDifficulty difficulty,
);

//Para o report de exercícios
typedef _ReportCallback = Future<bool> Function(String exerciseId);

class _ExerciseFeedCard extends StatefulWidget {
  final Exercise exercise;
  final _ProgressCallback? onProgress;
  final _ReportCallback? onReport;
  const _ExerciseFeedCard({super.key, required this.exercise, this.onProgress, this.onReport});

  @override
  State<_ExerciseFeedCard> createState() => _ExerciseFeedCardState();
}

class _ExerciseFeedCardState extends State<_ExerciseFeedCard> with AutomaticKeepAliveClientMixin {
  int? _selectedOption;
  bool _answered = false;
  bool _progressSent = false;

  @override
  bool get wantKeepAlive => true;

  bool get _isCorrect => _selectedOption == widget.exercise.correctIndex;

  void _confirm() {
    if (_selectedOption == null || _answered) return;
    setState(() => _answered = true);
    _recordProgress();
  }

  void _recordProgress() {
    if (_progressSent) return;
    _progressSent = true;
    widget.onProgress?.call(
      widget.exercise.id,
      _isCorrect,
      widget.exercise.difficulty,
    );
  }

  Future<void> _reportExercise() async {
    try {
      final success = await widget.onReport?.call(widget.exercise.id) ?? false;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.info_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                success
                    ? 'Obrigado! O exercício foi reportado.'
                    : 'Já reportaste este exercício anteriormente.',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ]),
          backgroundColor: success ? AppTheme.successState : AppTheme.textSecondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(children: [
            Icon(Icons.error_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(child: Text('Erro ao reportar. Tenta novamente.', style: TextStyle(fontSize: 14))),
          ]),
          backgroundColor: AppTheme.errorState,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Color get _difficultyColor {
    switch (widget.exercise.difficulty) {
      case ExerciseDifficulty.easy:   return AppTheme.successState;
      case ExerciseDifficulty.medium: return AppTheme.warningState;
      case ExerciseDifficulty.hard:   return AppTheme.errorState;
    }
  }

  String get _difficultyLabel {
    switch (widget.exercise.difficulty) {
      case ExerciseDifficulty.easy:   return 'Fácil';
      case ExerciseDifficulty.medium: return 'Médio';
      case ExerciseDifficulty.hard:   return 'Difícil';
    }
  }

  String get _typeLabel =>
      widget.exercise.type == ExerciseType.trueFalse ? 'V / F' : 'Escolha Múltipla';

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ex = widget.exercise;

    // FIX 1 & 2: O card inteiro é um Column onde a secção de opções usa
    // um SingleChildScrollView para não causar overflow, e a pergunta usa
    // ClampingScrollPhysics em vez de NeverScrollableScrollPhysics.
    return Column(
      children: [
        // Secção da pergunta — scrollable, flex para usar o espaço disponível
        Expanded(
          flex: 45,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tags de taxonomia
                Row(
                  children: [
                    if (ex.courseName.isNotEmpty)
                      _Tag(text: ex.courseName, color: AppTheme.brandAccent),
                    if (ex.courseName.isNotEmpty) const SizedBox(width: 6),
                    if (ex.chapterName.isNotEmpty)
                      Expanded(
                        child: Text(
                          ex.chapterName,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const Spacer(),
                    _Tag(text: _difficultyLabel, color: _difficultyColor),
                    const SizedBox(width: 6),
                    _Tag(text: _typeLabel, color: Colors.grey.shade500),
                  ],
                ),
                // FIX 2: Substituída NeverScrollableScrollPhysics → ClampingScrollPhysics
                // para que perguntas longas possam ser lidas sem overflow.
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Text(
                        ex.question,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // FIX 1: Painel de opções — sem altura máxima fixa, usa
        // SingleChildScrollView para absorver overflow em ecrãs pequenos.
        Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceSecondary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          // Limita a altura máxima a 60 % do ecrã para não engolir a pergunta.
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.60,
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: SafeArea(
              top: false,
              // FIX 3 (SafeArea bottom): aplicada aqui, dentro do painel,
              // em vez de envolver o Scaffold inteiro — evita espaço branco
              // excessivo em dispositivos sem notch e respeita o home indicator.
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  ..._buildOptions(ex),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) => SizeTransition(
                      sizeFactor: anim,
                      axisAlignment: -1,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: _answered
                        ? _buildFeedback(ex)
                        : Padding(
                            key: const ValueKey('btn-confirm'),
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                            child: SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _selectedOption == null ? null : _confirm,
                                child: const Text('Confirmar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildOptions(Exercise ex) {
    return List.generate(ex.options.length, (i) {
      final isSelected = _selectedOption == i;
      final isCorrect = i == ex.correctIndex;

      Color borderColor;
      Color textColor;
      Color? bgColor;

      if (_answered) {
        if (isCorrect) {
          borderColor = AppTheme.successState;
          textColor = AppTheme.successState;
          bgColor = AppTheme.successState.withValues(alpha: 0.08);
        } else if (isSelected) {
          borderColor = AppTheme.errorState;
          textColor = AppTheme.errorState;
          bgColor = AppTheme.errorState.withValues(alpha: 0.08);
        } else {
          borderColor = Colors.grey.shade800;
          textColor = AppTheme.textSecondary;
          bgColor = null;
        }
      } else {
        borderColor = isSelected ? AppTheme.brandAccent : Colors.grey.shade800;
        textColor = isSelected ? AppTheme.brandAccent : AppTheme.textPrimary;
        bgColor = isSelected ? AppTheme.brandAccent.withValues(alpha: 0.08) : null;
      }

      final label = ex.type == ExerciseType.trueFalse
          ? (i == 0 ? 'V' : 'F')
          : String.fromCharCode(65 + i);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: InkWell(
          onTap: _answered ? null : () => setState(() => _selectedOption = i),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.all(
                color: borderColor,
                width: (isSelected || (_answered && isCorrect)) ? 1.8 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  child: Text(
                    label,
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ex.options[i],
                    style: TextStyle(color: textColor, fontSize: 14, height: 1.3),
                    // FIX: removido maxLines + ellipsis — o texto expande naturalmente
                    // dentro do SingleChildScrollView do painel.
                  ),
                ),
                if (_answered && isCorrect)
                  const Icon(Icons.check_circle_rounded, color: AppTheme.successState, size: 18),
                if (_answered && isSelected && !isCorrect)
                  const Icon(Icons.cancel_rounded, color: AppTheme.errorState, size: 18),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildFeedback(Exercise ex) {
    return Padding(
      key: const ValueKey('feedback'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Resultado
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _isCorrect
                  ? AppTheme.successState.withValues(alpha: 0.1)
                  : AppTheme.errorState.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isCorrect
                    ? AppTheme.successState.withValues(alpha: 0.3)
                    : AppTheme.errorState.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: _isCorrect ? AppTheme.successState : AppTheme.errorState,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _isCorrect ? 'Correto!' : 'Incorreto',
                  style: TextStyle(
                    color: _isCorrect ? AppTheme.successState : AppTheme.errorState,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // FIX 4: Caixa de explicação sem maxHeight fixo — expande livremente
          // e usa SingleChildScrollView apenas se o conteúdo for muito longo.
          if (ex.explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.brandAccent.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.brandAccent.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome, color: AppTheme.brandAccent, size: 13),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      ex.explanation,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: TextButton.icon(
              onPressed: () => TutorChatDialog.show(context, exercise: ex, wasCorrect: _isCorrect),
              icon: const Icon(Icons.smart_toy_rounded, size: 17),
              label: const Text('Pedir explicação ao Andy', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.brandAccent,
                backgroundColor: AppTheme.brandAccent.withValues(alpha: 0.07),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),

          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: TextButton.icon(
              onPressed: () => _reportExercise(),
              icon: const Icon(Icons.flag_rounded, size: 16),
              label: const Text(
                'Reportar problema',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.errorState,
                backgroundColor: AppTheme.errorState.withValues(alpha: 0.07),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),

        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}
