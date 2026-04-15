import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/exercise.dart';
import '../../data/models/learning_path.dart';
import '../../data/remote/student_repository.dart';

class _ChatMessage {
  final bool isUser;
  final String text;
  _ChatMessage({required this.isUser, required this.text});
}

class TutorChatDialog extends ConsumerStatefulWidget {
  final String question;
  final List<String> options;
  final bool wasCorrect;
  final int? courseUnitId;
  final String? exerciseId;

  const TutorChatDialog._({
    required this.question,
    required this.options,
    required this.wasCorrect,
    this.courseUnitId,
    this.exerciseId,
  });

  /// Abre a partir de um exercício do feed (aba Prática)
  static void show(BuildContext context, {required Exercise exercise, required bool wasCorrect}) {
    _open(
      context,
      question: exercise.question,
      options: exercise.options,
      wasCorrect: wasCorrect,
      courseUnitId: int.tryParse(exercise.courseId),
      exerciseId: exercise.id,
    );
  }

  /// Abre a partir de um exercício da aba Cursos
  static void showForLearning(
    BuildContext context, {
    required LearningExercise exercise,
    required bool wasCorrect,
    required int courseUnitId,
  }) {
    _open(
      context,
      question: exercise.question,
      options: exercise.options,
      wasCorrect: wasCorrect,
      courseUnitId: courseUnitId,
      exerciseId: exercise.id,
    );
  }

  static void _open(
    BuildContext context, {
    required String question,
    required List<String> options,
    required bool wasCorrect,
    int? courseUnitId,
    String? exerciseId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TutorChatDialog._(
        question: question,
        options: options,
        wasCorrect: wasCorrect,
        courseUnitId: courseUnitId,
        exerciseId: exerciseId,
      ),
    );
  }

  @override
  ConsumerState<TutorChatDialog> createState() => _TutorChatDialogState();
}

class _TutorChatDialogState extends ConsumerState<TutorChatDialog> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendMessage(
        _buildInitialMessage(),
        displayText: widget.wasCorrect
            ? 'Explica-me este exercício que acertei.'
            : 'Errei este exercício. Explica-me o conceito.',
      );
    });
  }

  String _buildInitialMessage() {
    final buf = StringBuffer(widget.question);
    if (widget.options.isNotEmpty) {
      buf.write('\n\nOpções:');
      final labels = ['A', 'B', 'C', 'D', 'E'];
      for (var i = 0; i < widget.options.length; i++) {
        final label = i < labels.length ? labels[i] : '${i + 1}';
        buf.write('\n$label) ${widget.options[i]}');
      }
    }
    buf.write('\n\n${widget.wasCorrect ? "Respondi corretamente." : "Errei esta pergunta."} Explica-me o conceito.');
    return buf.toString();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text, {String? displayText}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_ChatMessage(isUser: true, text: displayText ?? trimmed));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final repo = ref.read(studentRepositoryProvider);
      final result = await repo.chatQuery(
        trimmed,
        courseUnitId: widget.courseUnitId,
        exerciseId: widget.exerciseId,
      );
      final answer = (result['answer'] as String? ?? '').trim();

      setState(() {
        _messages.add(_ChatMessage(
          isUser: false,
          text: answer.isNotEmpty ? answer : 'Sem resposta disponível.',
        ));
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[TutorChat] ❌ erro ao enviar mensagem: $e');
      String errorText;
      if (e.toString().contains('receiveTimeout') || e.toString().contains('connectTimeout')) {
        errorText = 'O Tutor IA demorou demasiado a responder. Tenta novamente.';
      } else if (e.toString().contains('503') || e.toString().contains('SERVICE_UNAVAILABLE')) {
        errorText = 'O Tutor IA não está disponível de momento.';
      } else {
        errorText = 'Não foi possível contactar o Tutor IA. Verifica a ligação e tenta novamente.';
      }
      setState(() {
        _messages.add(_ChatMessage(isUser: false, text: errorText));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    // Primeira tentativa: após o próximo frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
    // Segunda tentativa: após o markdown renderizar (pode ser lento para respostas longas)
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, _) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.backgroundPrimary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(2)),
              ),
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade800, width: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.brandAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.smart_toy_rounded, color: AppTheme.brandAccent, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tutor IA', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                          Text('Assistente de estudo', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Contexto do exercício
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade800),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.help_outline_rounded, size: 13, color: AppTheme.textSecondary),
                        const SizedBox(width: 5),
                        const Text('Exercício', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: widget.wasCorrect
                                ? AppTheme.successState.withValues(alpha: 0.15)
                                : AppTheme.errorState.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.wasCorrect ? 'Correto' : 'Incorreto',
                            style: TextStyle(
                              color: widget.wasCorrect ? AppTheme.successState : AppTheme.errorState,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.question,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, height: 1.4),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Mensagens
              Expanded(
                child: _messages.isEmpty && _isLoading
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.brandAccent),
                            ),
                            const SizedBox(height: 12),
                            Text('A analisar...', style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.7), fontSize: 13)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        itemCount: _messages.length + (_isLoading ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i == _messages.length) return _TypingIndicator();
                          final m = _messages[i];
                          return m.isUser
                              ? _UserBubble(text: m.text)
                              : _AssistantBubble(text: m.text);
                        },
                      ),
              ),
              // Input
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSecondary,
                    border: Border(top: BorderSide(color: Colors.grey.shade800, width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          enabled: !_isLoading,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: _isLoading ? 'A aguardar resposta...' : 'Faz uma pergunta...',
                            hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            filled: true,
                            fillColor: AppTheme.backgroundPrimary,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(22)),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: _isLoading ? null : _sendMessage,
                          textInputAction: TextInputAction.send,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: _isLoading ? Colors.grey.shade700 : AppTheme.brandAccent,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                          onPressed: _isLoading ? null : () => _sendMessage(_controller.text),
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Bubbles ──────────────────────────────────────────────────────────────────

class _UserBubble extends StatelessWidget {
  final String text;
  const _UserBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(
          color: AppTheme.brandAccent,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
      ),
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  final String text;
  const _AssistantBubble({required this.text});

  static final _markdownStyleSheet = MarkdownStyleSheet(
    p: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, height: 1.5),
    strong: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
    em: const TextStyle(color: AppTheme.textPrimary, fontStyle: FontStyle.italic, fontSize: 13),
    code: TextStyle(
      color: AppTheme.brandAccent,
      backgroundColor: Colors.grey.shade900,
      fontSize: 12,
      fontFamily: 'monospace',
    ),
    codeblockDecoration: BoxDecoration(
      color: Colors.grey.shade900,
      borderRadius: BorderRadius.circular(8),
    ),
    codeblockPadding: const EdgeInsets.all(10),
    listBullet: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
    h3: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
  );

  @override
  Widget build(BuildContext context) {
    // Limita a largura para que o MarkdownBody tenha sempre um espaço definido
    final maxWidth = MediaQuery.of(context).size.width * 0.82;
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: const BoxDecoration(
            color: AppTheme.surfaceSecondary,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8, top: 2),
                child: Icon(Icons.auto_awesome, color: AppTheme.brandAccent, size: 13),
              ),
              Expanded(
                child: MarkdownBody(
                  data: text,
                  styleSheet: _markdownStyleSheet,
                  shrinkWrap: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceSecondary,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 20,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 1.8, color: AppTheme.brandAccent),
            ),
            const SizedBox(width: 8),
            Text('A pensar...', style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.7), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
