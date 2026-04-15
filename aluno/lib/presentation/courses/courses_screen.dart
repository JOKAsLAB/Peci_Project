import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/learning_path.dart';
import '../../data/remote/student_repository.dart';
import '../../features/gamification/providers/feed_provider.dart';
import '../../features/profile/providers/profile_provider.dart';
import '../shared/tutor_chat_dialog.dart';
import '../shared/xp_gain_overlay.dart';

// ─── Ecrã principal: lista de UCs ────────────────────────────────────────────

class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pathsAsync = ref.watch(learningPathsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Cursos', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.surfaceSecondary,
        elevation: 0,
      ),
      body: pathsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Erro ao carregar cursos: $e',
              style: const TextStyle(color: AppTheme.textSecondary)),
        ),
        data: (paths) => paths.isEmpty
            ? const Center(
                child: Text('Sem cursos disponíveis.',
                    style: TextStyle(color: AppTheme.textSecondary)),
              )
            : ListView.builder(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: paths.length,
                itemBuilder: (context, index) {
                  final path = paths[index];
                  final shortName = path.name
                      .split(' ')
                      .where((w) => w.isNotEmpty)
                      .map((w) => w[0])
                      .take(3)
                      .join()
                      .toUpperCase();

                  return _CourseCard(
                    name: path.name,
                    shortName: shortName,
                    totalTopics: path.totalTopics,
                    totalExercises: path.totalExercises,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CoursePathScreen(path: path),
                      ),
                    ),
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
  final int totalTopics;
  final int totalExercises;
  final VoidCallback onTap;

  const _CourseCard({
    required this.name,
    required this.shortName,
    required this.totalTopics,
    required this.totalExercises,
    required this.onTap,
  });

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
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.brandAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      shortName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brandAccent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalTopics tópicos · $totalExercises exercícios',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
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

// ─── Ecrã path (zigzag) ───────────────────────────────────────────────────────

class CoursePathScreen extends StatelessWidget {
  final LearningPath path;

  const CoursePathScreen({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    final checkpoints = path.checkpoints;

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: Text(path.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.surfaceSecondary,
        elevation: 0,
      ),
      body: checkpoints.isEmpty
          ? const Center(child: Text('Sem tópicos disponíveis.', style: TextStyle(color: AppTheme.textSecondary)))
          : SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                children: List.generate(checkpoints.length, (index) {
                  final checkpoint = checkpoints[index];
                  // Alternado: par = esquerda, ímpar = direita
                  final alignment = index % 2 == 0 ? Alignment.centerLeft : Alignment.centerRight;
                  return Column(
                    children: [
                      if (index > 0) _PathConnector(),
                      Align(
                        alignment: alignment,
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: index % 2 == 0 ? 56 : 0,
                            right: index % 2 != 0 ? 56 : 0,
                          ),
                          child: _CheckpointNode(
                            checkpoint: checkpoint,
                            index: index,
                            courseUnitId: path.idUc,
                          ),
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

// ─── Linha de ligação entre nós ───────────────────────────────────────────────

class _PathConnector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Center(
        child: Container(
          width: 3,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.brandAccent.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

// ─── Nó circular do checkpoint ────────────────────────────────────────────────

class _CheckpointNode extends StatelessWidget {
  final Checkpoint checkpoint;
  final int index;
  final int courseUnitId;

  const _CheckpointNode({
    required this.checkpoint,
    required this.index,
    required this.courseUnitId,
  });

  @override
  Widget build(BuildContext context) {
    final hasExercises = checkpoint.exercises.isNotEmpty;

    return GestureDetector(
      onTap: hasExercises
          ? () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ExerciseScreen(checkpoint: checkpoint, courseUnitId: courseUnitId),
              ))
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Círculo principal
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasExercises
                  ? AppTheme.brandAccent
                  : Colors.grey.shade900,
              border: Border.all(
                color: hasExercises ? AppTheme.brandAccent : Colors.grey.shade700,
                width: 3,
              ),
              boxShadow: hasExercises
                  ? [
                      BoxShadow(
                        color: AppTheme.brandAccent.withValues(alpha: 0.35),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              hasExercises ? Icons.play_arrow_rounded : Icons.lock_rounded,
              color: hasExercises ? Colors.white : Colors.grey.shade700,
              size: 34,
            ),
          ),
          const SizedBox(height: 8),
          // Nome do tópico
          SizedBox(
            width: 160,
            child: Text(
              checkpoint.topicName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: hasExercises ? AppTheme.textPrimary : AppTheme.textSecondary.withValues(alpha: 0.5),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Contagem de exercícios
          Text(
            hasExercises ? '${checkpoint.exercises.length} exercícios' : 'Sem exercícios',
            style: TextStyle(
              color: hasExercises
                  ? AppTheme.brandAccent.withValues(alpha: 0.8)
                  : AppTheme.textSecondary.withValues(alpha: 0.35),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─── Ecrã de exercícios ───────────────────────────────────────────────────────

class ExerciseScreen extends ConsumerStatefulWidget {
  final Checkpoint checkpoint;
  final int courseUnitId;

  const ExerciseScreen({super.key, required this.checkpoint, required this.courseUnitId});

  @override
  ConsumerState<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends ConsumerState<ExerciseScreen> {
  int _current = 0;
  int? _selectedIndex;   // índice da opção selecionada
  bool _answered = false;

  LearningExercise get _ex => widget.checkpoint.exercises[_current];
  int get _total => widget.checkpoint.exercises.length;

  bool get _isCorrect {
    if (_selectedIndex == null) return false;
    final selected = _ex.options[_selectedIndex!];
    final letter = selected.length >= 2 && selected[1] == ')' ? selected[0] : selected;
    return letter == _ex.correct || selected == _ex.correct;
  }

  void _confirm() {
    if (_selectedIndex == null || _answered) return;
    setState(() => _answered = true);
    _recordProgress();
  }

  Future<void> _recordProgress() async {
    final repo = ref.read(studentRepositoryProvider);
    final result = await repo.postProgress(
      exerciseId: _ex.id,
      isCorrect: _isCorrect,
      difficulty: _ex.difficulty,
    );
    if (!mounted) return;
    // Invalida o perfil para que apareça actualizado quando o aluno for ao separador
    ref.invalidate(profileStateProvider);
    if (result.xpEarned > 0) {
      XpGainOverlay.show(context, xp: result.xpEarned, levelUp: result.levelUp, newLevel: result.newLevel);
    }
  }

  void _next() {
    if (_current < _total - 1) {
      setState(() {
        _current++;
        _selectedIndex = null;
        _answered = false;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  // Extrai label (A, B, …) e texto da opção
  (String label, String text) _parseOption(String option, int index) {
    if (option.length >= 2 && option[1] == ')') {
      return (option[0], option.substring(2).trim());
    }
    // True/False sem prefixo
    if (_ex.isTrueFalse) {
      return (index == 0 ? 'V' : 'F', option);
    }
    return (String.fromCharCode(65 + index), option);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: Text(widget.checkpoint.topicName, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.surfaceSecondary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: (_current + 1) / _total,
            backgroundColor: Colors.grey.shade800,
            color: AppTheme.brandAccent,
            minHeight: 3,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Zona da pergunta ───────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contador + dificuldade
                  Row(
                    children: [
                      Text(
                        'Pergunta ${_current + 1} de $_total',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                      const Spacer(),
                      _DiffBadge(_ex.difficulty),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Pergunta
                  Text(
                    _ex.question,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w600, height: 1.45),
                  ),
                ],
              ),
            ),
          ),

          // ── Painel de opções + ações ───────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.surfaceSecondary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 14),
                // Opções — altura fixa para todas
                if (_ex.options.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Sem opções disponíveis.', style: TextStyle(color: AppTheme.textSecondary)),
                  )
                else
                  ...List.generate(_ex.options.length, (i) {
                    final (label, text) = _parseOption(_ex.options[i], i);
                    final isSelected = _selectedIndex == i;
                    final isCorrectOption = _answered && _ex.options[i] == _ex.correct ||
                        (_answered &&
                            _ex.options[i].length >= 2 &&
                            _ex.options[i][1] == ')' &&
                            _ex.options[i][0] == _ex.correct);

                    Color borderColor;
                    Color labelBg;
                    Color labelColor;

                    if (_answered) {
                      if (isCorrectOption) {
                        borderColor = AppTheme.successState;
                        labelBg = AppTheme.successState.withValues(alpha: 0.2);
                        labelColor = AppTheme.successState;
                      } else if (isSelected) {
                        borderColor = AppTheme.errorState;
                        labelBg = AppTheme.errorState.withValues(alpha: 0.2);
                        labelColor = AppTheme.errorState;
                      } else {
                        borderColor = Colors.grey.shade800;
                        labelBg = Colors.grey.shade800;
                        labelColor = AppTheme.textSecondary;
                      }
                    } else {
                      borderColor = isSelected ? AppTheme.brandAccent : Colors.grey.shade700;
                      labelBg = isSelected ? AppTheme.brandAccent.withValues(alpha: 0.2) : Colors.grey.shade800;
                      labelColor = isSelected ? AppTheme.brandAccent : AppTheme.textSecondary;
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      child: InkWell(
                        onTap: _answered ? null : () => setState(() => _selectedIndex = i),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          constraints: const BoxConstraints(minHeight: 52),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: _answered && isCorrectOption
                                ? AppTheme.successState.withValues(alpha: 0.07)
                                : _answered && isSelected
                                    ? AppTheme.errorState.withValues(alpha: 0.07)
                                    : null,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor, width: isSelected || (_answered && isCorrectOption) ? 1.8 : 1),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Label A / B / V / F
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(color: labelBg, borderRadius: BorderRadius.circular(7)),
                                child: Center(
                                  child: Text(label, style: TextStyle(color: labelColor, fontWeight: FontWeight.w700, fontSize: 13)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(text, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, height: 1.35)),
                              ),
                              if (_answered && isCorrectOption)
                                const Icon(Icons.check_circle_rounded, color: AppTheme.successState, size: 18),
                              if (_answered && isSelected && !isCorrectOption)
                                const Icon(Icons.cancel_rounded, color: AppTheme.errorState, size: 18),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                // ── Feedback / Botões ────────────────────────────────────
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.topCenter,
                  child: _answered
                      ? _buildFeedback()
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _selectedIndex == null ? null : _confirm,
                              child: const Text('Confirmar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            ),
                          ),
                        ),
                ),
                SafeArea(top: false, child: const SizedBox(height: 8)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedback() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Resultado
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _isCorrect ? AppTheme.successState.withValues(alpha: 0.1) : AppTheme.errorState.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _isCorrect ? AppTheme.successState.withValues(alpha: 0.35) : AppTheme.errorState.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Icon(_isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: _isCorrect ? AppTheme.successState : AppTheme.errorState, size: 18),
                const SizedBox(width: 8),
                Text(
                  _isCorrect ? 'Correto!' : 'Incorreto',
                  style: TextStyle(color: _isCorrect ? AppTheme.successState : AppTheme.errorState, fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ],
            ),
          ),
          // Explicação
          if (_ex.explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(maxHeight: 90),
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
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Text(_ex.explanation, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, height: 1.4)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          // Tutor IA
          SizedBox(
            width: double.infinity,
            height: 42,
            child: TextButton.icon(
              onPressed: () => TutorChatDialog.showForLearning(context, exercise: _ex, wasCorrect: _isCorrect, courseUnitId: widget.courseUnitId),
              icon: const Icon(Icons.smart_toy_rounded, size: 16),
              label: const Text('Pedir explicação ao Tutor IA', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.brandAccent,
                backgroundColor: AppTheme.brandAccent.withValues(alpha: 0.07),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Próxima / Terminar
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _next,
              child: Text(_current < _total - 1 ? 'Próxima' : 'Terminar', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

// Badge de dificuldade
class _DiffBadge extends StatelessWidget {
  final String difficulty;
  const _DiffBadge(this.difficulty);

  @override
  Widget build(BuildContext context) {
    final color = switch (difficulty.toLowerCase()) {
      'easy'   => AppTheme.successState,
      'hard'   => AppTheme.errorState,
      _        => AppTheme.warningState,
    };
    final label = switch (difficulty.toLowerCase()) {
      'easy'   => 'Fácil',
      'hard'   => 'Difícil',
      _        => 'Médio',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}