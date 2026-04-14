import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../shared/tutor_chat_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/mock_data.dart';
import '../../../data/remote/student_repository.dart';
import '../../data/models/exercise.dart';

/// Lista de cursos/disciplinas disponíveis.
/// O aluno pode inscrever-se numa disciplina e depois ver o caminho Duolingo de capítulos.
class CoursesScreen extends ConsumerStatefulWidget {
  const CoursesScreen({super.key});
  @override
  ConsumerState<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends ConsumerState<CoursesScreen> {
  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(courseListProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Cursos', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.surfaceSecondary,
        elevation: 0,
      ),
      body: coursesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(
          child: Text('Erro ao carregar cursos', style: TextStyle(color: AppTheme.textSecondary)),
        ),
        data: (courses) => ListView.builder(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            return _CourseCard(
              name: course['name'] as String,
              shortName: (course['name'] as String).split(' ').map((w) => w[0]).take(3).join(),
              onTap: () {},
            );
          },
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final String name;
  final String shortName;
  final VoidCallback onTap;

  const _CourseCard({required this.name, required this.shortName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.brandAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(shortName, style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.brandAccent,
                    )),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(name, style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600,
                  )),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ecrã Duolingo-style path para um curso específico.
/// Mostra os capítulos como nós num caminho vertical com zig-zag.
class CoursePathScreen extends StatelessWidget {
  final Course course;

  const CoursePathScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: Text(course.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.surfaceSecondary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: List.generate(course.chapters.length, (index) {
            final chapter = course.chapters[index];
            // Zig-zag: alterna entre esquerda e direita
            final alignment = index % 2 == 0
                ? Alignment.centerLeft
                : Alignment.centerRight;

            return Column(
              children: [
                if (index > 0) _PathConnector(chapter: chapter),
                Align(
                  alignment: alignment,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: index % 2 == 0 ? 48 : 0,
                      right: index % 2 != 0 ? 48 : 0,
                    ),
                    child: _ChapterNode(chapter: chapter, index: index),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _PathConnector extends StatelessWidget {
  final Chapter chapter;

  const _PathConnector({required this.chapter});

  @override
  Widget build(BuildContext context) {
    final color = switch (chapter.status) {
      ChapterStatus.completed => AppTheme.brandAccent,
      ChapterStatus.inProgress => AppTheme.brandAccent.withValues(alpha: 0.5),
      ChapterStatus.available => Colors.grey.shade600,
      ChapterStatus.locked => Colors.grey.shade800,
    };

    return SizedBox(
      height: 40,
      child: Center(
        child: Container(
          width: 3,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _ChapterNode extends StatelessWidget {
  final Chapter chapter;
  final int index;

  const _ChapterNode({required this.chapter, required this.index});

  @override
  Widget build(BuildContext context) {
    final isLocked = chapter.status == ChapterStatus.locked;
    final isCompleted = chapter.status == ChapterStatus.completed;
    final isInProgress = chapter.status == ChapterStatus.inProgress;

    final nodeColor = switch (chapter.status) {
      ChapterStatus.completed => AppTheme.brandAccent,
      ChapterStatus.inProgress => AppTheme.brandAccent,
      ChapterStatus.available => AppTheme.surfaceSecondary,
      ChapterStatus.locked => Colors.grey.shade900,
    };

    final borderColor = switch (chapter.status) {
      ChapterStatus.completed => AppTheme.successState,
      ChapterStatus.inProgress => AppTheme.brandAccent,
      ChapterStatus.available => Colors.grey.shade600,
      ChapterStatus.locked => Colors.grey.shade800,
    };

    final icon = switch (chapter.status) {
      ChapterStatus.completed => Icons.check_rounded,
      ChapterStatus.inProgress => Icons.play_arrow_rounded,
      ChapterStatus.available => Icons.circle_outlined,
      ChapterStatus.locked => Icons.lock_rounded,
    };

    return GestureDetector(
      onTap: isLocked ? null : () => _showChapterDetail(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nó circular (estilo Duolingo)
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: nodeColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 3),
              boxShadow: isInProgress
                  ? [
                      BoxShadow(
                        color: AppTheme.brandAccent.withValues(alpha: 0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: isLocked ? Colors.grey.shade700 : AppTheme.textPrimary,
              size: 32,
            ),
          ),
          const SizedBox(height: 8),
          // Título do capítulo
          SizedBox(
            width: 160,
            child: Text(
              chapter.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isLocked ? Colors.grey.shade700 : AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (isInProgress) ...[
            const SizedBox(height: 4),
            Text(
              '${chapter.completedExercises}/${chapter.totalExercises}',
              style: const TextStyle(color: AppTheme.brandAccent, fontSize: 11),
            ),
          ],
          if (isCompleted) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, size: 14, color: AppTheme.successState),
                const SizedBox(width: 2),
                Text(
                  '${chapter.xpReward} XP',
                  style: const TextStyle(color: AppTheme.successState, fontSize: 11),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showChapterDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                chapter.title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                chapter.description,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.bolt_outlined,
                    label: '${chapter.totalExercises} exercícios',
                  ),
                  const SizedBox(width: 12),
                  _InfoChip(
                    icon: Icons.star_outline_rounded,
                    label: '${chapter.xpReward} XP',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChapterExercisesScreen(chapter: chapter),
                      ),
                    );
                  },
                  child: Text(
                    chapter.status == ChapterStatus.completed
                        ? 'Rever Capítulo'
                        : chapter.status == ChapterStatus.inProgress
                            ? 'Continuar'
                            : 'Começar',
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPrimary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.brandAccent),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
        ],
      ),
    );
  }
}

// ─── Ecrã de exercícios do capítulo ──────────────────────────────────────────

class ChapterExercisesScreen extends StatefulWidget {
  final Chapter chapter;
  const ChapterExercisesScreen({super.key, required this.chapter});

  @override
  State<ChapterExercisesScreen> createState() => _ChapterExercisesScreenState();
}

class _ChapterExercisesScreenState extends State<ChapterExercisesScreen> {
  late final List<Exercise> _exercises;
  int _currentIndex = 0;
  int? _selectedOption;
  bool _answered = false;
  int _correctCount = 0;

  @override
  void initState() {
    super.initState();
    _exercises = mockExercises
        .where((e) => e.chapterId == widget.chapter.id)
        .toList();
  }

  bool get _isCorrect =>
      _selectedOption != null &&
      _selectedOption == _exercises[_currentIndex].correctIndex;

  void _confirm() {
    if (_selectedOption == null) return;
    setState(() {
      _answered = true;
      if (_isCorrect) _correctCount++;
    });
  }

  void _next() {
    if (_currentIndex < _exercises.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _answered = false;
      });
    } else {
      _showSummary();
    }
  }

  void _showSummary() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final pct = (_correctCount / _exercises.length * 100).round();
        final exerciseXp = _correctCount * 25;
        final totalXp = widget.chapter.xpReward + exerciseXp;
        return AlertDialog(
          backgroundColor: AppTheme.surfaceSecondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Capítulo Concluído!',
              style: TextStyle(color: AppTheme.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                pct >= 70 ? Icons.emoji_events_rounded : Icons.refresh_rounded,
                size: 56,
                color: pct >= 70 ? AppTheme.brandAccent : const Color(0xFFFFB300),
              ),
              const SizedBox(height: 16),
              Text(
                '$_correctCount / ${_exercises.length} corretas ($pct%)',
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.brandAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Capítulo', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        Text('+${widget.chapter.xpReward} XP', style: const TextStyle(color: AppTheme.brandAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Exercícios ($_correctCount × 25)', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        Text('+$exerciseXp XP', style: const TextStyle(color: Color(0xFF64B5F6), fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const Divider(color: Colors.grey, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('+$totalXp XP', style: const TextStyle(color: AppTheme.successState, fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Voltar ao Curso'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_exercises.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundPrimary,
        appBar: AppBar(
          title: Text(widget.chapter.title),
          backgroundColor: AppTheme.surfaceSecondary,
        ),
        body: const Center(
          child: Text('Sem exercícios disponíveis.',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
      );
    }

    final exercise = _exercises[_currentIndex];
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: Text(widget.chapter.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.surfaceSecondary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / _exercises.length,
            backgroundColor: Colors.grey.shade800,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.brandAccent),
            minHeight: 4,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress counter
            Text(
              'Pergunta ${_currentIndex + 1} de ${_exercises.length}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            // Question
            Text(
              exercise.question,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            // Options
            Expanded(
              child: ListView.builder(
                physics: const ClampingScrollPhysics(),
                itemCount: exercise.options.length,
                itemBuilder: (context, i) {
                  final isSelected = _selectedOption == i;
                  final isCorrectOption = i == exercise.correctIndex;

                  Color bgColor = AppTheme.surfaceSecondary;
                  Color borderColor = Colors.transparent;
                  if (_answered) {
                    if (isCorrectOption) {
                      bgColor = AppTheme.successState.withValues(alpha: 0.15);
                      borderColor = AppTheme.successState;
                    } else if (isSelected && !isCorrectOption) {
                      bgColor = AppTheme.errorState.withValues(alpha: 0.15);
                      borderColor = AppTheme.errorState;
                    }
                  } else if (isSelected) {
                    bgColor = AppTheme.brandAccent.withValues(alpha: 0.15);
                    borderColor = AppTheme.brandAccent;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: _answered ? null : () => setState(() => _selectedOption = i),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? AppTheme.brandAccent.withValues(alpha: 0.2)
                                      : Colors.grey.shade800,
                                ),
                                child: Center(
                                  child: Text(
                                    String.fromCharCode(65 + i),
                                    style: TextStyle(
                                      color: isSelected ? AppTheme.brandAccent : AppTheme.textSecondary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  exercise.options[i],
                                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                                ),
                              ),
                              if (_answered && isCorrectOption)
                                const Icon(Icons.check_circle, color: AppTheme.successState, size: 22),
                              if (_answered && isSelected && !isCorrectOption)
                                const Icon(Icons.cancel, color: AppTheme.errorState, size: 22),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Explanation (shown after answering)
            if (_answered && exercise.explanation.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.brandAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.brandAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 18, color: AppTheme.brandAccent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        exercise.explanation,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            // Tutor IA button (after answering)
            if (_answered)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      TutorChatDialog.show(context, exercise: exercise, wasCorrect: _isCorrect);
                    },
                    icon: const Icon(Icons.smart_toy_rounded, size: 18),
                    label: const Text('Pedir explicação ao Tutor IA'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.brandAccent,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _answered
                    ? _next
                    : (_selectedOption != null ? _confirm : null),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _answered
                      ? (_currentIndex < _exercises.length - 1 ? 'Próxima' : 'Ver Resultado')
                      : 'Confirmar',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
