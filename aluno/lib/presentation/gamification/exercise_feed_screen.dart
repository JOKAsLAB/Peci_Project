import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../shared/tutor_chat_dialog.dart';
import '../../features/gamification/providers/feed_provider.dart';

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

  void _jumpToSpecificExercise(String exerciseId) {
    final state = ref.read(feedProvider);
    final targetIndex = state.currentDeck.indexWhere(
      (e) => e.id == exerciseId, 
      state.currentIndex,
    );
    
    if (targetIndex != -1) {
      _pageController.animateToPage(
        targetIndex,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
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

    final cyclePosition = feedState.cycleSize == 0 ? 0 : (feedState.currentIndex % feedState.cycleSize) + 1;

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: _FilterBar(
              selectedCourseId: feedState.filters.courseId,
              selectedChapterId: feedState.filters.chapterId,
              selectedDifficulty: feedState.filters.difficulty,
              selectedType: feedState.filters.type,
              availableChapters: feedState.availableChapters,
              onCourseChanged: feedNotifier.updateCourseFilter,
              onChapterChanged: feedNotifier.updateChapterFilter,
              onDifficultyChanged: feedNotifier.updateDifficultyFilter,
              onTypeChanged: feedNotifier.updateTypeFilter,
              onClearFilters: feedNotifier.clearFilters,
              currentExerciseIndex: cyclePosition,
              currentCycle: feedState.cycleNumber,
              totalExercises: feedState.cycleSize,
              onJumpToExercise: () => _showExercisePicker(context, feedState.currentDeck.take(feedState.cycleSize).toList()),
            ),
          ),
          Expanded(
            child: feedState.currentDeck.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded, size: 64, color: AppTheme.textSecondary),
                        SizedBox(height: 16),
                        Text(
                          'Nenhum exercício encontrado\npara estes filtros.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
                        ),
                      ],
                    ),
                  )
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showExercisePicker(BuildContext context, List<MockExercise> cycleExercises) {
    if (cycleExercises.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Escolher exercício',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: cycleExercises.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final ex = cycleExercises[index];
                      final isCurrent = ref.read(feedProvider).currentDeck[ref.read(feedProvider).currentIndex].id == ex.id;
                      
                      return ListTile(
                        dense: true,
                        title: Text(
                          'Exercício ${index + 1}',
                          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          ex.question,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                        trailing: isCurrent ? const Icon(Icons.check_circle, color: AppTheme.brandAccent, size: 18) : null,
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _jumpToSpecificExercise(ex.id);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Barra de Filtros ────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final String? selectedCourseId;
  final String? selectedChapterId;
  final ExerciseDifficulty? selectedDifficulty;
  final ExerciseType? selectedType;
  final List<Chapter> availableChapters;
  final ValueChanged<String?> onCourseChanged;
  final ValueChanged<String?> onChapterChanged;
  final ValueChanged<ExerciseDifficulty?> onDifficultyChanged;
  final ValueChanged<ExerciseType?> onTypeChanged;
  final VoidCallback onClearFilters;
  final int currentExerciseIndex;
  final int currentCycle;
  final int totalExercises;
  final VoidCallback onJumpToExercise;

  const _FilterBar({
    required this.selectedCourseId,
    required this.selectedChapterId,
    required this.selectedDifficulty,
    required this.selectedType,
    required this.availableChapters,
    required this.onCourseChanged,
    required this.onChapterChanged,
    required this.onDifficultyChanged,
    required this.onTypeChanged,
    required this.onClearFilters,
    required this.currentExerciseIndex,
    required this.currentCycle,
    required this.totalExercises,
    required this.onJumpToExercise,
  });

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = selectedCourseId != null || selectedDifficulty != null || selectedType != null;

    return Container(
      color: AppTheme.surfaceSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                const Text(
                  'Prática',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                if (totalExercises > 0)
                  GestureDetector(
                    onTap: onJumpToExercise,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.brandAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.brandAccent.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'Ex $currentExerciseIndex/$totalExercises • Ciclo $currentCycle',
                        style: const TextStyle(color: AppTheme.brandAccent, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                const Spacer(),
                if (hasActiveFilters)
                  GestureDetector(
                    onTap: onClearFilters,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.errorState.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.clear_rounded, size: 14, color: AppTheme.errorState),
                          SizedBox(width: 4),
                          Text('Limpar', style: TextStyle(color: AppTheme.errorState, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.tune_rounded, color: AppTheme.textSecondary),
                  onPressed: () => _showFilterSheet(context),
                  tooltip: 'Filtros',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
            child: Text('DISCIPLINA', style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.6), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          ),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _FilterChip(
                  label: 'Todas',
                  isSelected: selectedCourseId == null,
                  onTap: () => onCourseChanged(null),
                ),
                ...mockCourses.map((course) => _FilterChip(
                      label: course.shortName,
                      isSelected: selectedCourseId == course.id,
                      onTap: () => onCourseChanged(selectedCourseId == course.id ? null : course.id),
                    )),
              ],
            ),
          ),
          if (selectedCourseId != null && availableChapters.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 6, bottom: 4),
              child: Text('MATÉRIA', style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.6), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            ),
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _FilterChip(
                    label: 'Todos',
                    isSelected: selectedChapterId == null,
                    onTap: () => onChapterChanged(null),
                    small: true,
                  ),
                  ...availableChapters.map((chapter) => _FilterChip(
                        label: chapter.title,
                        isSelected: selectedChapterId == chapter.id,
                        onTap: () => onChapterChanged(selectedChapterId == chapter.id ? null : chapter.id),
                        small: true,
                      )),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 6, bottom: 4),
            child: Text('DIFICULDADE & TIPO', style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.6), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          ),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _MiniFilterChip(
                  label: 'Fácil',
                  isSelected: selectedDifficulty == ExerciseDifficulty.facil,
                  color: AppTheme.successState,
                  onTap: () => onDifficultyChanged(selectedDifficulty == ExerciseDifficulty.facil ? null : ExerciseDifficulty.facil),
                ),
                _MiniFilterChip(
                  label: 'Médio',
                  isSelected: selectedDifficulty == ExerciseDifficulty.medio,
                  color: const Color(0xFFFFB300),
                  onTap: () => onDifficultyChanged(selectedDifficulty == ExerciseDifficulty.medio ? null : ExerciseDifficulty.medio),
                ),
                _MiniFilterChip(
                  label: 'Difícil',
                  isSelected: selectedDifficulty == ExerciseDifficulty.dificil,
                  color: AppTheme.errorState,
                  onTap: () => onDifficultyChanged(selectedDifficulty == ExerciseDifficulty.dificil ? null : ExerciseDifficulty.dificil),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Container(width: 1, height: 20, color: Colors.grey.shade700),
                ),
                _MiniFilterChip(
                  label: 'Escolha Múltipla',
                  isSelected: selectedType == ExerciseType.multipleChoice,
                  color: AppTheme.brandAccent,
                  onTap: () => onTypeChanged(selectedType == ExerciseType.multipleChoice ? null : ExerciseType.multipleChoice),
                ),
                _MiniFilterChip(
                  label: 'V/F',
                  isSelected: selectedType == ExerciseType.trueFalse,
                  color: AppTheme.brandAccent,
                  onTap: () => onTypeChanged(selectedType == ExerciseType.trueFalse ? null : ExerciseType.trueFalse),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceSecondary,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 24),
              const Text('Filtros de Prática', style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Use os chips na barra superior para filtrar por disciplina, tópico, dificuldade e tipo de pergunta. Pode combinar múltiplos filtros.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              const SizedBox(height: 8),
              const Text('• Disciplina: SD, AC, SE\n• Tópico: Capítulos da disciplina\n• Dificuldade: Fácil, Médio, Difícil\n• Tipo: Escolha Múltipla, V/F', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.6)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fechar')),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool small;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: small ? 10 : 14, vertical: small ? 5 : 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.brandAccent.withValues(alpha: 0.2) : AppTheme.backgroundPrimary,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? AppTheme.brandAccent : Colors.grey.shade800, width: 1.5),
          ),
          child: Text(
            label,
            style: TextStyle(color: isSelected ? AppTheme.brandAccent : AppTheme.textPrimary, fontSize: small ? 11 : 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400),
          ),
        ),
      ),
    );
  }
}

class _MiniFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _MiniFilterChip({required this.label, required this.isSelected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.2) : AppTheme.backgroundPrimary,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isSelected ? color : Colors.grey.shade800),
          ),
          child: Text(
            label,
            style: TextStyle(color: isSelected ? color : AppTheme.textSecondary, fontSize: 11, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400),
          ),
        ),
      ),
    );
  }
}

// ─── Card de Exercício Reativo ───────────────────────────────────────────────

class _ExerciseFeedCard extends StatefulWidget {
  final MockExercise exercise;
  const _ExerciseFeedCard({super.key, required this.exercise});

  @override
  State<_ExerciseFeedCard> createState() => _ExerciseFeedCardState();
}

class _ExerciseFeedCardState extends State<_ExerciseFeedCard> with AutomaticKeepAliveClientMixin {
  int? _selectedOption;
  bool _answered = false;

  @override
  bool get wantKeepAlive => true;

  bool get _isCorrect => _selectedOption == widget.exercise.correctIndex;

  String get _typeLabel => widget.exercise.type == ExerciseType.multipleChoice ? 'Escolha Múltipla' : 'Verdadeiro / Falso';
  String get _difficultyLabel => widget.exercise.difficulty.name.substring(0, 1).toUpperCase() + widget.exercise.difficulty.name.substring(1);
  
  Color get _difficultyColor {
    switch (widget.exercise.difficulty) {
      case ExerciseDifficulty.facil: return AppTheme.successState;
      case ExerciseDifficulty.medio: return const Color(0xFFFFB300);
      case ExerciseDifficulty.dificil: return AppTheme.errorState;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final exercise = widget.exercise;

    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxHeight < 700;
          final horizontalPadding = isCompact ? 14.0 : 20.0;
          final maxContentWidth = constraints.maxWidth >= 760 ? 640.0 : (constraints.maxWidth >= 520 ? 560.0 : double.infinity);

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSecondary, 
              borderRadius: BorderRadius.circular(24.0)
            ),
            // Eliminamos o SingleChildScrollView exterior para permitir Flex/Expanded
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: isCompact ? 12 : 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min, // Garante que a coluna encolhe se houver espaço
                    children: [
                      // Cabeçalho de Taxonomia
                      Padding(
                        padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: AppTheme.brandAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                              child: Text(exercise.courseName, style: const TextStyle(color: AppTheme.brandAccent, fontSize: 11, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 8),
                            Flexible(child: Text(exercise.chapterName, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(10)),
                              child: Text(_typeLabel, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: _difficultyColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                              child: Text(_difficultyLabel, style: TextStyle(color: _difficultyColor, fontSize: 10, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                      
                      // Corpo da Pergunta
                      Padding(
                        padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 12),
                        child: Text(exercise.question, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: isCompact ? 15 : 16), textAlign: TextAlign.center),
                      ),
                      
                      // Grelha de Opções
                      ..._buildOptionsUI(exercise, horizontalPadding),
                      
                      // Bloco Estrutural de Confirmação vs Feedback
                      // O Flexible aqui permite que a secção do feedback comprima as suas dimensões sem cortar os botões
                      Flexible(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 0),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (child, animation) => SizeTransition(
                              sizeFactor: animation,
                              axisAlignment: -1.0,
                              child: FadeTransition(opacity: animation, child: child),
                            ),
                            child: _answered
                                ? _buildAnsweredFeedback(exercise)
                                : SizedBox(
                                    key: const ValueKey('btn-confirm'),
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: _selectedOption == null ? null : () => setState(() => _answered = true),
                                      child: const Text('Confirmar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnsweredFeedback(MockExercise exercise) {
    return Column(
      key: const ValueKey('feedback-answered'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Caixa de Explicação Flexível (Otimizada sem faixa redundante)
        if (exercise.explanation.isNotEmpty)
          Flexible(
            child: Container(
              width: double.infinity, 
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.brandAccent.withValues(alpha: 0.08), 
                borderRadius: BorderRadius.circular(10), 
                border: Border.all(color: AppTheme.brandAccent.withValues(alpha: 0.2))
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: AppTheme.brandAccent, size: 14), 
                          SizedBox(width: 6), 
                          Text('Explicação', style: TextStyle(color: AppTheme.brandAccent, fontSize: 12, fontWeight: FontWeight.w700))
                        ]
                      ),
                      // Feedback de Gamificação injetado inline no cabeçalho
                      if (_isCorrect)
                        const Text('+25 XP', style: TextStyle(color: AppTheme.successState, fontSize: 12, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Text(exercise.explanation, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, height: 1.4)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
        // Botão Tutor IA Ancorado
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: SizedBox(
            width: double.infinity,
            height: 44,
            child: TextButton.icon(
              onPressed: () => TutorChatDialog.show(context, exercise: widget.exercise, wasCorrect: _isCorrect),
              icon: const Icon(Icons.smart_toy_rounded, size: 18),
              label: const Text('Pedir explicação ao Tutor IA', style: TextStyle(fontWeight: FontWeight.w600)),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.brandAccent,
                backgroundColor: AppTheme.brandAccent.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildOptionsUI(MockExercise exercise, double horizontalPadding) {
    return List.generate(exercise.options.length, (optionIndex) {
      final isSelected = _selectedOption == optionIndex;
      final isCorrect = optionIndex == exercise.correctIndex;

      Color borderColor; Color textColor;
      if (_answered) {
        if (isCorrect) { borderColor = AppTheme.successState; textColor = AppTheme.successState; }
        else if (isSelected && !isCorrect) { borderColor = AppTheme.errorState; textColor = AppTheme.errorState; }
        else { borderColor = Colors.grey.shade800; textColor = AppTheme.textSecondary; }
      } else {
        borderColor = isSelected ? AppTheme.brandAccent : Colors.grey.shade800;
        textColor = isSelected ? AppTheme.brandAccent : AppTheme.textPrimary;
      }

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 4.0), // Reduzido de 5.0 para compactação
        child: InkWell(
          onTap: _answered ? null : () => setState(() => _selectedOption = optionIndex),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 44), // Reduzido de 48 para compactação
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _answered && isCorrect ? AppTheme.successState.withValues(alpha: 0.1) : _answered && isSelected && !isCorrect ? AppTheme.errorState.withValues(alpha: 0.1) : null,
              border: Border.all(color: borderColor, width: isSelected || (_answered && isCorrect) ? 2 : 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  exercise.type == ExerciseType.trueFalse ? (optionIndex == 0 ? 'V' : 'F') : String.fromCharCode(65 + optionIndex),
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(exercise.options[optionIndex], maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: textColor, fontSize: 14)),
                ),
                if (_answered && isCorrect) const Icon(Icons.check_circle_rounded, color: AppTheme.successState, size: 18),
                if (_answered && isSelected && !isCorrect) const Icon(Icons.cancel_rounded, color: AppTheme.errorState, size: 18),
              ],
            ),
          ),
        ),
      );
    });
  }
}