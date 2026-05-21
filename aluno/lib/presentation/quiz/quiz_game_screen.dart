import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/theme/app_theme.dart';
import '../../data/remote/api_client.dart';
import '../../data/remote/auth_storage.dart';
import '../../data/remote/quiz_repository.dart';

const _apiBaseUrl = apiBaseUrl;

enum _GamePhase { lobby, question, answered, finished }

class QuizGameScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final Map<String, dynamic> sessionData;

  const QuizGameScreen({
    super.key,
    required this.sessionId,
    required this.sessionData,
  });

  @override
  ConsumerState<QuizGameScreen> createState() => _QuizGameScreenState();
}

class _QuizGameScreenState extends ConsumerState<QuizGameScreen> {
  _GamePhase _phase = _GamePhase.lobby;
  WebSocketChannel? _channel;

  // Question state
  Map<String, dynamic>? _question;
  int _countdown = 30;
  Timer? _countdownTimer;
  DateTime? _questionStartedAt;
  int? _selectedOptionIndex;
  bool _confirmed = false;

  // Answer result
  bool? _isCorrect;
  int _pointsEarned = 0;
  int _totalScore = 0;
  dynamic _correctAnswer;

  // Leaderboard
  List<Map<String, dynamic>> _leaderboard = [];

  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _connectWs();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  void _connectWs() {
    final token = ref.read(authTokenProvider) ?? '';
    final wsBase = _apiBaseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    final url = '$wsBase/quizzes/ws/student/${widget.sessionId}?token=$token';

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _channel!.stream.listen(
        _onWsMessage,
        onError: (_) => setState(() => _error = 'Ligação perdida.'),
        onDone: () {
          if (_phase != _GamePhase.finished) setState(() => _error = 'Ligação encerrada.');
        },
      );
    } catch (_) {
      setState(() => _error = 'Não foi possível ligar ao servidor.');
    }
  }

  void _onWsMessage(dynamic raw) {
    final msg = jsonDecode(raw as String) as Map<String, dynamic>;
    final type = msg['type'] as String?;
    if (type == 'question') _startQuestion(msg);
    else if (type == 'session_ended') _endGame(msg);
  }

  void _startQuestion(Map<String, dynamic> msg) {
    _countdownTimer?.cancel();
    setState(() {
      _phase = _GamePhase.question;
      _question = msg;
      _selectedOptionIndex = null;
      _confirmed = false;
      _isCorrect = null;
      _correctAnswer = null;
      _countdown = msg['time_limit_seconds'] as int? ?? 30;
      _questionStartedAt = DateTime.now();
      _error = null;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _countdown--;
        if (_countdown <= 0) {
          t.cancel();
          if (_phase == _GamePhase.question) {
            _phase = _GamePhase.answered;
            _isCorrect = false;
            _pointsEarned = 0;
          }
        }
      });
    });
  }

  void _endGame(Map<String, dynamic> msg) {
    _countdownTimer?.cancel();
    final raw = msg['leaderboard'] as List<dynamic>? ?? [];
    setState(() {
      _phase = _GamePhase.finished;
      _leaderboard = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    });
  }

  Future<void> _confirm() async {
    if (_selectedOptionIndex == null || _submitting || _confirmed) return;
    _countdownTimer?.cancel();

    final options = _questionOptions;
    final raw = options[_selectedOptionIndex!];
    // If option is "B) text...", send only the letter "B" to match the backend's `correct` field.
    final answer = (raw.length >= 2 && raw[1] == ')') ? raw[0] : raw;
    final timeTaken = _questionStartedAt != null
        ? DateTime.now().difference(_questionStartedAt!).inMilliseconds
        : 0;

    setState(() { _submitting = true; _confirmed = true; });

    try {
      final repo = ref.read(quizRepositoryProvider);
      final result = await repo.submitAnswer(widget.sessionId, answer, timeTaken);
      if (!mounted) return;
      setState(() {
        _phase = _GamePhase.answered;
        _isCorrect = result['is_correct'] as bool? ?? false;
        _pointsEarned = result['points_earned'] as int? ?? 0;
        _totalScore = result['total_score'] as int? ?? 0;
        _correctAnswer = result['correct_answer'];
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Erro ao enviar resposta.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  List<String> get _questionOptions {
    final opts = (_question?['options'] as List<dynamic>?)?.cast<String>();
    if (opts == null || opts.isEmpty) {
      // Fallback: True/False questions whose Solution has no options field.
      final type = _question?['exercise_type'] as String? ?? '';
      if (type == 'True/False') return ['A) Verdadeiro', 'B) Falso'];
    }
    return opts ?? [];
  }

  String _optionLabel(int i) {
    final exerciseType = _question?['exercise_type'] as String? ?? '';
    if (exerciseType == 'True/False') return i == 0 ? 'V' : 'F';
    return String.fromCharCode(65 + i);
  }

  // Strip "A) " prefix if the backend stores options with letter labels already.
  String _optionText(String raw) {
    if (raw.length >= 2 && raw[1] == ')') return raw.substring(2).trim();
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: SafeArea(
        bottom: false,
        child: switch (_phase) {
          _GamePhase.lobby    => _buildLobby(),
          _GamePhase.question => _buildQuestion(),
          _GamePhase.answered => _buildAnswered(),
          _GamePhase.finished => _buildLeaderboard(),
        },
      ),
    );
  }

  // ── Lobby ──────────────────────────────────────────────────────────────────
  Widget _buildLobby() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.brandAccent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.gamepad_outlined, color: AppTheme.brandAccent, size: 52),
            ),
            const SizedBox(height: 24),
            Text(
              widget.sessionData['quiz_title'] ?? 'Quiz',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Sala: ${widget.sessionData['room_code'] ?? ''}',
              style: TextStyle(
                color: AppTheme.brandAccent,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: AppTheme.brandAccent),
            const SizedBox(height: 20),
            Text(
              'Aguarda o professor para iniciar...',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            if (_error != null) ...[
              const SizedBox(height: 20),
              _ErrorBanner(_error!),
            ],
          ],
        ),
      ),
    );
  }

  // ── Question — mesma estrutura do _ExerciseFeedCard ───────────────────────
  Widget _buildQuestion() {
    final options = _questionOptions;
    final total = _question?['total'] as int? ?? 1;
    final idx = (_question?['index'] as int? ?? 0) + 1;
    final timeLimit = _question?['time_limit_seconds'] as int? ?? 30;
    final fraction = (_countdown / timeLimit).clamp(0.0, 1.0);
    final timerColor = _countdown > 10
        ? AppTheme.brandAccent
        : _countdown > 5 ? Colors.orange : Colors.red;

    return Column(
      children: [
        // ── Barra do timer ──────────────────────────────────────────────────
        Container(
          color: AppTheme.surfaceSecondary,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Text(
                      'Pergunta $idx/$total',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: timerColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: timerColor.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_outlined, color: timerColor, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '$_countdown s',
                            style: TextStyle(color: timerColor, fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              LinearProgressIndicator(
                value: fraction,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                valueColor: AlwaysStoppedAnimation(timerColor),
                minHeight: 3,
              ),
            ],
          ),
        ),

        // ── Pergunta ────────────────────────────────────────────────────────
        Expanded(
          flex: 45,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Text(
                  _question?['question'] as String? ?? '',
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
        ),

        // ── Painel de opções — cópia exata do feed ──────────────────────────
        Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceSecondary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.60,
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  ...List.generate(options.length, (i) {
                    final isSelected = _selectedOptionIndex == i;
                    final label = _optionLabel(i);

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: InkWell(
                        onTap: _confirmed ? null : () => setState(() => _selectedOptionIndex = i),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: 48),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.brandAccent.withValues(alpha: 0.08) : null,
                            border: Border.all(
                              color: isSelected ? AppTheme.brandAccent : Colors.grey.shade800,
                              width: isSelected ? 1.8 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 22,
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: isSelected ? AppTheme.brandAccent : AppTheme.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _optionText(options[i]),
                                  style: TextStyle(
                                    color: isSelected ? AppTheme.brandAccent : AppTheme.textPrimary,
                                    fontSize: 14,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) => SizeTransition(
                      sizeFactor: anim,
                      axisAlignment: -1,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: Padding(
                      key: const ValueKey('btn-confirm'),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: (_selectedOptionIndex == null || _submitting) ? null : _confirm,
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text('Confirmar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
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

  // ── Resultado ──────────────────────────────────────────────────────────────
  Widget _buildAnswered() {
    final correct = _isCorrect ?? false;
    final options = _questionOptions;

    return Column(
      children: [
        // Reutiliza a mesma barra do topo
        Container(
          color: AppTheme.surfaceSecondary,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Text(
                'Pergunta ${(_question?['index'] as int? ?? 0) + 1}/${_question?['total'] ?? '?'}',
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'À espera...',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),

        // Pergunta com opções coloridas
        Expanded(
          flex: 45,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Text(
                  _question?['question'] as String? ?? '',
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
        ),

        Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceSecondary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.60),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  ...List.generate(options.length, (i) {
                    final isSelected = _selectedOptionIndex == i;
                    final rawOpt = options[i].toString();
                    final optKey = (rawOpt.length >= 2 && rawOpt[1] == ')') ? rawOpt[0] : rawOpt;
                    final isCorrectOpt = optKey == _correctAnswer?.toString().trim();
                    final label = _optionLabel(i);

                    Color borderColor;
                    Color textColor;
                    Color? bgColor;

                    if (isCorrectOpt) {
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

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 48),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: bgColor,
                          border: Border.all(
                            color: borderColor,
                            width: (isCorrectOpt || isSelected) ? 1.8 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 22,
                              child: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 13)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(_optionText(options[i]), style: TextStyle(color: textColor, fontSize: 14, height: 1.3)),
                            ),
                            if (isCorrectOpt)
                              const Icon(Icons.check_circle_rounded, color: AppTheme.successState, size: 18),
                            if (isSelected && !isCorrectOpt)
                              const Icon(Icons.cancel_rounded, color: AppTheme.errorState, size: 18),
                          ],
                        ),
                      ),
                    );
                  }),

                  // Resultado e pontos
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: correct
                                ? AppTheme.successState.withValues(alpha: 0.1)
                                : AppTheme.errorState.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: correct
                                  ? AppTheme.successState.withValues(alpha: 0.3)
                                  : AppTheme.errorState.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                color: correct ? AppTheme.successState : AppTheme.errorState,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                correct ? 'Correto! +$_pointsEarned pts' : 'Incorreto',
                                style: TextStyle(
                                  color: correct ? AppTheme.successState : AppTheme.errorState,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              if (correct)
                                Text(
                                  'Total: $_totalScore pts',
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'À espera da próxima pergunta...',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
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

  // ── Leaderboard ────────────────────────────────────────────────────────────
  Widget _buildLeaderboard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
            const SizedBox(width: 10),
            const Text('Fim do Quiz!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 4),
          Text('Classificação final', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: _leaderboard.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final entry = _leaderboard[i];
                final rank = entry['rank'] as int? ?? (i + 1);
                final name = entry['student_name'] as String? ?? '—';
                final score = entry['score'] as int? ?? 0;
                final rankColor = rank == 1
                    ? Colors.amber
                    : rank == 2 ? Colors.grey[300]! : rank == 3 ? const Color(0xFFCD7F32) : AppTheme.textSecondary;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: rank <= 3
                          ? rankColor.withValues(alpha: 0.35)
                          : Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(children: [
                    SizedBox(
                      width: 32,
                      child: Text('$rank', style: TextStyle(color: rankColor, fontWeight: FontWeight.w900, fontSize: 18), textAlign: TextAlign.center),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                    Text('$score pts', style: TextStyle(color: AppTheme.brandAccent, fontWeight: FontWeight.w800)),
                  ]),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => context.go('/quiz'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Sair', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.errorState.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.errorState.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          Icon(Icons.error_outline, color: AppTheme.errorState, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(color: AppTheme.errorState, fontSize: 13))),
        ]),
      );
}
