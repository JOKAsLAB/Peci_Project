import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/tutorial/onboarding_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/learning_path.dart';
import '../../data/remote/student_repository.dart';
import '../../features/gamification/providers/feed_provider.dart';
import '../../features/profile/providers/profile_provider.dart';
import '../shared/tutor_chat_dialog.dart';
import '../shared/xp_gain_overlay.dart';
import '../shared/xp_widgets.dart';
import '../shared/rule_item.dart';


// ─── Ecrã principal: lista de UCs ────────────────────────────────────────────
class CoursesScreen extends ConsumerStatefulWidget {
  const CoursesScreen({super.key});

  @override
  ConsumerState<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends ConsumerState<CoursesScreen> {
  @override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => OnboardingService.maybeShow(context, ref),
  );
}

  @override
  Widget build(BuildContext context) {
    final pathsAsync = ref.watch(learningPathsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Cursos', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.surfaceSecondary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: AppTheme.textSecondary),
            onPressed: () => OnboardingService.showForced(context, ref),
          ),
        ],
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

                  final totalEx = path.checkpoints.fold(0, (s, c) => s + c.totalCount);
                  final doneEx  = path.checkpoints.fold(0, (s, c) => s + c.attemptedCount);
                  final progress = totalEx > 0 ? doneEx / totalEx : 0.0;

                  return _CourseCard(
                    name: path.name,
                    shortName: shortName,
                    totalTopics: path.totalTopics,
                    totalExercises: path.totalExercises,
                    doneExercises: doneEx,
                    progress: progress,
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
  final int doneExercises;
  final double progress;
  final VoidCallback onTap;

  const _CourseCard({
    required this.name,
    required this.shortName,
    required this.totalTopics,
    required this.totalExercises,
    required this.doneExercises,
    required this.progress,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                            '$totalTopics tópicos · $doneExercises/$totalExercises exercícios',
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
                if (totalExercises > 0) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: Colors.grey.shade800,
                      color: AppTheme.brandAccent,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Ecrã path (zigzag) ───────────────────────────────────────────────────────
class CoursePathScreen extends ConsumerWidget {
  final LearningPath path;

  const CoursePathScreen({super.key, required this.path});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pathsAsync = ref.watch(learningPathsProvider);
    final currentPath = pathsAsync.asData?.value.firstWhere(
          (p) => p.idUc == path.idUc,
          orElse: () => path,
        ) ??
        path;

    final checkpoints = currentPath.checkpoints;

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: Text(currentPath.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.surfaceSecondary,
        elevation: 0,
      ),
      body: checkpoints.isEmpty
          ? const Center(child: Text('Sem tópicos disponíveis.', style: TextStyle(color: AppTheme.textSecondary)))
          : LayoutBuilder(
              builder: (context, constraints) {
                // FIX 3: zigzag totalmente responsivo — o offset horizontal
                // é calculado em % da largura disponível em vez de pixels fixos (56px).
                // Usa 28% da largura (≈ mínimo razoável em qualquer tamanho de ecrã).
                final nodeWidth = 160.0;
                final availableWidth = constraints.maxWidth;
                // Garante que o nó não sai do ecrã em ecrãs muito estreitos.
                final sideOffset = ((availableWidth - nodeWidth) * 0.28)
                    .clamp(8.0, 72.0);

                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Column(
                    children: List.generate(checkpoints.length, (index) {
                      final checkpoint = checkpoints[index];
                      final isLeft = index % 2 == 0;
                      return Column(
                        children: [
                          if (index > 0) _PathConnector(isLocked: checkpoint.isLocked),
                          Align(
                            alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: isLeft ? sideOffset : 0,
                                right: isLeft ? 0 : sideOffset,
                              ),
                              child: _CheckpointNode(
                                checkpoint: checkpoint,
                                courseUnitId: currentPath.idUc,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                );
              },
            ),
    );
  }
}

// ─── Popup de onboarding ──────────────────────────────────────────────────────
class _OnboardingDialog extends StatelessWidget {
  const _OnboardingDialog();

  @override
  Widget build(BuildContext context) {
    // FIX: Dialog responsivo — usa fração do ecrã e SingleChildScrollView
    // para não cortar conteúdo em ecrãs pequenos ou quando o teclado sobe.
    return Dialog(
      backgroundColor: AppTheme.surfaceSecondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
          maxWidth: 480,
        ),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Andy avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundPrimary,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.brandAccent.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Image.asset(
                    'assets/chatbot_photo.png',
                    fit: BoxFit.contain,
                    color: Colors.white,
                    colorBlendMode: BlendMode.difference,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Olá! Sou o Andy 👋',
                style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 20),
              ),
              const SizedBox(height: 8),
              const Text(
                'O teu companheiro de estudo com IA.\nAbre-me depois de qualquer exercício para esclarecer dúvidas e aprender melhor.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.55),
              ),
              const SizedBox(height: 20),
              Divider(color: Colors.grey.shade800, height: 1),
              const SizedBox(height: 16),
              RuleItem(
                icon: Icons.local_fire_department_rounded,
                color: const Color(0xFFFB923C),
                title: '5 exercícios diários = Bónus XP',
                description: 'Os primeiros 5 por dia têm 1.5× XP de bónus + mantêm o streak:',
                extra: const XpTable(),
              ),
              const SizedBox(height: 14),
              RuleItem(
                icon: Icons.trending_up_rounded,
                color: AppTheme.successState,
                title: 'Progressão por dificuldade',
                description: 'Cada tópico segue Fácil → Médio → Difícil. Após os 5, podes continuar a praticar (XP normal).',
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                    elevation: 0,
                  ),
                  child: const Text('Vamos começar!', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Linha de ligação entre nós ───────────────────────────────────────────────
class _PathConnector extends StatelessWidget {
  final bool isLocked;
  const _PathConnector({this.isLocked = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Center(
        child: Container(
          width: 3,
          height: 36,
          decoration: BoxDecoration(
            color: isLocked
                ? Colors.grey.shade800
                : AppTheme.brandAccent.withValues(alpha: 0.35),
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
  final int courseUnitId;

  const _CheckpointNode({
    required this.checkpoint,
    required this.courseUnitId,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked    = checkpoint.isLocked;
    final isCompleted = checkpoint.isCompleted;
    final isActive    = !isLocked && !isCompleted && checkpoint.totalCount > 0;
    final isEmpty     = checkpoint.totalCount == 0;

    Color nodeColor;
    Color borderColor;
    Color shadowColor;
    IconData icon;

    if (isCompleted) {
      nodeColor   = const Color(0xFF4CAF50);
      borderColor = const Color(0xFF4CAF50);
      shadowColor = const Color(0xFF4CAF50);
      icon        = Icons.check_rounded;
    } else if (isLocked || isEmpty) {
      nodeColor   = Colors.grey.shade900;
      borderColor = Colors.grey.shade700;
      shadowColor = Colors.transparent;
      icon        = isEmpty ? Icons.remove_rounded : Icons.lock_rounded;
    } else {
      nodeColor   = AppTheme.brandAccent;
      borderColor = AppTheme.brandAccent;
      shadowColor = AppTheme.brandAccent;
      icon        = Icons.play_arrow_rounded;
    }

    return GestureDetector(
      onTap: isActive
          ? () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => TopicPracticeLoader(courseUnitId: courseUnitId),
              ))
          : isLocked
              ? () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Conclui o tópico anterior primeiro.'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      duration: const Duration(seconds: 2),
                    ),
                  )
              : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: nodeColor,
              border: Border.all(color: borderColor, width: 3),
              boxShadow: shadowColor != Colors.transparent
                  ? [BoxShadow(color: shadowColor.withValues(alpha: 0.35), blurRadius: 14, spreadRadius: 1)]
                  : null,
            ),
            child: Icon(icon, color: Colors.white, size: 34),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 160,
            child: Text(
              checkpoint.topicName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isLocked ? AppTheme.textSecondary.withValues(alpha: 0.4) : AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          if (isCompleted)
            Text(
              '${checkpoint.attemptedCount}/${checkpoint.totalCount} concluídos',
              style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 11),
            )
          else if (isActive)
            Text(
              '${checkpoint.attemptedCount}/${checkpoint.totalCount} · Praticar',
              style: TextStyle(
                color: AppTheme.brandAccent.withValues(alpha: 0.9),
                fontSize: 11,
              ),
            )
          else
            Text(
              isEmpty ? 'Sem exercícios' : 'Bloqueado',
              style: TextStyle(
                color: AppTheme.textSecondary.withValues(alpha: 0.35),
                fontSize: 11,
              ),
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─── Loader de sessão de prática ─────────────────────────────────────────────
class TopicPracticeLoader extends ConsumerStatefulWidget {
  final int courseUnitId;
  const TopicPracticeLoader({super.key, required this.courseUnitId});

  @override
  ConsumerState<TopicPracticeLoader> createState() => _TopicPracticeLoaderState();
}

class _TopicPracticeLoaderState extends ConsumerState<TopicPracticeLoader> {
  late Future<PracticeSession> _sessionFuture;
  bool _didAnyExercise = false;
  ProviderContainer? _container;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _container = ProviderScope.containerOf(context);
  }

  @override
  void initState() {
    super.initState();
    _sessionFuture = ref.read(studentRepositoryProvider).getPracticeSession(widget.courseUnitId);
  }

  @override
  void dispose() {
    if (_didAnyExercise) _container?.invalidate(learningPathsProvider);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PracticeSession>(
      future: _sessionFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: AppTheme.backgroundPrimary,
            body: Center(child: CircularProgressIndicator(color: AppTheme.brandAccent)),
          );
        }
        if (snap.hasError) {
          return Scaffold(
            backgroundColor: AppTheme.backgroundPrimary,
            body: Center(
              child: Text('Erro ao carregar sessão: ${snap.error}',
                  style: const TextStyle(color: AppTheme.textSecondary)),
            ),
          );
        }

        final session = snap.data!;

        if (!session.canPractice) {
          return _DailyLimitScreen(
            doneToday: session.doneToday,
            dailyLimit: session.dailyLimit,
          );
        }

        if (session.allCompleted) {
          return const _UcCompletedScreen();
        }

        if (session.exercisesRaw.isEmpty) {
          return Scaffold(
            backgroundColor: AppTheme.backgroundPrimary,
            appBar: AppBar(
              backgroundColor: AppTheme.surfaceSecondary,
              elevation: 0,
            ),
            body: const Center(
              child: Text('Sem exercícios disponíveis neste tópico.',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
          );
        }

        final exercises = session.exercisesRaw
            .map((raw) => LearningExercise.fromJson(raw))
            .toList();

        return ExerciseScreen(
          exercises: exercises,
          topicName: session.currentTopic?.name ?? '',
          courseUnitId: widget.courseUnitId,
          doneToday: session.doneToday,
          dailyLimit: session.dailyLimit,
          streakMet: session.streakMet,
          onFirstProgress: () => _didAnyExercise = true,
        );
      },
    );
  }
}

// ─── Ecrã "limite diário atingido" ───────────────────────────────────────────
class _DailyLimitScreen extends StatelessWidget {
  final int doneToday;
  final int dailyLimit;
  const _DailyLimitScreen({required this.doneToday, required this.dailyLimit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(backgroundColor: AppTheme.surfaceSecondary, elevation: 0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wb_sunny_rounded, size: 72, color: Color(0xFFFFC107)),
              const SizedBox(height: 20),
              const Text(
                'Sessão do dia concluída!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                'Fizeste $doneToday de $dailyLimit exercícios hoje nesta UC.\nVolta amanhã para continuar.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15, height: 1.6),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.brandAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.brandAccent.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department_rounded, color: AppTheme.brandAccent, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Mantém o streak — volta amanhã!',
                      style: TextStyle(color: AppTheme.brandAccent, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Ecrã "UC concluída" ─────────────────────────────────────────────────────
class _UcCompletedScreen extends StatelessWidget {
  const _UcCompletedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(backgroundColor: AppTheme.surfaceSecondary, elevation: 0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events_rounded, size: 72, color: Color(0xFFFFC107)),
              const SizedBox(height: 20),
              const Text(
                'UC Concluída!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              const Text(
                'Completaste todos os tópicos desta disciplina.\nParabéns!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Ecrã de exercícios ───────────────────────────────────────────────────────
class ExerciseScreen extends ConsumerStatefulWidget {
  final List<LearningExercise> exercises;
  final String topicName;
  final int courseUnitId;
  final int doneToday;
  final int dailyLimit;
  final bool streakMet;
  final VoidCallback? onFirstProgress;

  const ExerciseScreen({
    super.key,
    required this.exercises,
    required this.topicName,
    required this.courseUnitId,
    required this.doneToday,
    required this.dailyLimit,
    this.streakMet = false,
    this.onFirstProgress,
  });

  @override
  ConsumerState<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends ConsumerState<ExerciseScreen> {
  int _current = 0;
  int? _selectedIndex;
  bool _answered = false;
  bool _streakDialogShown = false;
  bool _progressNotified = false;

  LearningExercise get _ex => widget.exercises[_current];
  int get _total => widget.exercises.length;

  bool get _localStreakMet =>
      widget.streakMet || (widget.doneToday + _current >= widget.dailyLimit);

  String get _progressLabel {
    if (_localStreakMet) return 'Streak mantido · Prática livre';
    final done = widget.doneToday + _current;
    return '$done/${widget.dailyLimit} · Bónus 1.5× XP ativo';
  }

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
    final doneAfterThis = widget.doneToday + _current + 1;
    final justMetStreak = !widget.streakMet &&
        doneAfterThis == widget.dailyLimit &&
        !_streakDialogShown;

    final repo = ref.read(studentRepositoryProvider);
    final result = await repo.postProgress(
      exerciseId: _ex.id,
      isCorrect: _isCorrect,
      difficulty: _ex.difficulty,
      bonus: !_localStreakMet,
    );
    if (!mounted) return;
    if (!_progressNotified) {
      _progressNotified = true;
      widget.onFirstProgress?.call();
    }
    ref.invalidate(profileStateProvider);
    ref.invalidate(topicStatsProvider);
    if (result.xpEarned > 0) {
      XpGainOverlay.show(context, xp: result.xpEarned, levelUp: result.levelUp, newLevel: result.newLevel);
    }

    if (justMetStreak && mounted) {
      _streakDialogShown = true;
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) _showStreakDialog();
      });
    }
  }

  Future<void> _reportExercise() async {
    final repo = ref.read(studentRepositoryProvider);
    
    try {
      final success = await repo.reportExercise(_ex.id);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
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
            ],
          ),
          backgroundColor: success ? AppTheme.successState : AppTheme.textSecondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Erro ao reportar. Tenta novamente.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.errorState,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _showStreakDialog() {
    final parentNav = Navigator.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: AppTheme.surfaceSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFB923C).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFB923C), size: 38),
              ),
              const SizedBox(height: 16),
              const Text(
                'Streak mantido!',
                style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(
                'Fizeste ${widget.dailyLimit} exercícios hoje.\nOs bónus de 1.5× XP foram aplicados.\nPodes continuar a praticar!',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.55),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        parentNav.pop();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.textSecondary.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Sair', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        _next();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Continuar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

  (String label, String text) _parseOption(String option, int index) {
    if (option.length >= 2 && option[1] == ')') {
      return (option[0], option.substring(2).trim());
    }
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.topicName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            Text(
              _progressLabel,
              style: TextStyle(
                color: _localStreakMet ? AppTheme.brandAccent : AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
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
      // FIX 1 & 5: O body usa Column com Expanded para a pergunta e o painel
      // de opções em baixo. O painel usa SingleChildScrollView para absorver
      // overflow. SafeArea aplicada apenas no painel inferior (bottom: true),
      // não em volta do Scaffold inteiro — comportamento correto em todos os
      // dispositivos (com e sem home indicator).
      body: Column(
        children: [
          // Secção da pergunta — scrollable, cresce com o espaço disponível
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Pergunta ${_current + 1} de $_total',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                      const Spacer(),
                      XpBadge(difficulty: _ex.difficulty, bonus: !_localStreakMet),
                      const SizedBox(width: 6),
                      _DiffBadge(_ex.difficulty),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _XpTableInline(bonus: !_localStreakMet),
                  const SizedBox(height: 12),
                  Text(
                    _ex.question,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w600, height: 1.45),
                  ),
                ],
              ),
            ),
          ),

          // Painel de opções + ações — sem altura fixa, scroll interno se necessário
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.surfaceSecondary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            // FIX 1: maxHeight relativo ao ecrã em vez de sem limite —
            // evita overflow sem cortar opções em ecrãs normais.
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.62,
            ),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: SafeArea(
                // FIX 5: SafeArea só no bottom, dentro do painel —
                // respeita o home indicator sem adicionar espaço branco no topo.
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 14),
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
                            labelBg     = AppTheme.successState.withValues(alpha: 0.2);
                            labelColor  = AppTheme.successState;
                          } else if (isSelected) {
                            borderColor = AppTheme.errorState;
                            labelBg     = AppTheme.errorState.withValues(alpha: 0.2);
                            labelColor  = AppTheme.errorState;
                          } else {
                            borderColor = Colors.grey.shade800;
                            labelBg     = Colors.grey.shade800;
                            labelColor  = AppTheme.textSecondary;
                          }
                        } else {
                          borderColor = isSelected ? AppTheme.brandAccent : Colors.grey.shade700;
                          labelBg     = isSelected ? AppTheme.brandAccent.withValues(alpha: 0.2) : Colors.grey.shade800;
                          labelColor  = isSelected ? AppTheme.brandAccent : AppTheme.textSecondary;
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

                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      alignment: Alignment.topCenter,
                      child: _answered
                          ? _buildFeedback()
                          : Padding(
                              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedback() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          // FIX 4: Caixa de explicação sem maxHeight fixo — expande livremente.
          // O SingleChildScrollView do painel pai absorve o scroll se necessário.
          if (_ex.explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
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
                      _ex.explanation,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: TextButton.icon(
              onPressed: () => TutorChatDialog.showForLearning(context, exercise: _ex, wasCorrect: _isCorrect, courseUnitId: widget.courseUnitId),
              icon: const Icon(Icons.smart_toy_rounded, size: 16),
              label: const Text('Pedir explicação ao Andy', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.brandAccent,
                backgroundColor: AppTheme.brandAccent.withValues(alpha: 0.07),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),

          //Botão report
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

          const SizedBox(height: 8),
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

// ─── Badges e tabela XP ──────────────────────────────────────────────────────
class _XpTableInline extends StatelessWidget {
  final bool bonus;
  const _XpTableInline({required this.bonus});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSecondary.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: bonus
              ? const Color(0xFFFB923C).withValues(alpha: 0.25)
              : Colors.grey.shade800,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          XpChip(label: 'Fácil',   normal: 10, bonusXp: 15, bonusActive: bonus, color: AppTheme.successState),
          XpChip(label: 'Médio',   normal: 20, bonusXp: 30, bonusActive: bonus, color: AppTheme.warningState),
          XpChip(label: 'Difícil', normal: 35, bonusXp: 53, bonusActive: bonus, color: AppTheme.errorState),
          if (bonus)
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_fire_department_rounded, size: 11, color: Color(0xFFFB923C)),
                SizedBox(width: 3),
                Text('1.5×', style: TextStyle(color: Color(0xFFFB923C), fontSize: 10, fontWeight: FontWeight.w700)),
              ],
            ),
        ],
      ),
    );
  }
}

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