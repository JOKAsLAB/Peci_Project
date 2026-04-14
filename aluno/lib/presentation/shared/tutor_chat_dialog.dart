import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../features/tutor_ai/providers/chat_provider.dart';
import '../../data/models/exercise.dart';

class TutorChatDialog extends ConsumerStatefulWidget {
  final Exercise exercise;
  final bool wasCorrect;

  const TutorChatDialog({
    super.key,
    required this.exercise,
    required this.wasCorrect,
  });

  static void show(BuildContext context, {required Exercise exercise, required bool wasCorrect}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TutorChatDialog(exercise: exercise, wasCorrect: wasCorrect),
    );
  }

  @override
  ConsumerState<TutorChatDialog> createState() => _TutorChatDialogState();
}

class _TutorChatDialogState extends ConsumerState<TutorChatDialog> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    
    _controller.clear();
    ref.read(chatProvider(widget.exercise.id).notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100, // Overhead para compensar o streaming
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Escuta ativa do histórico conversacional do exercício específico
    final messages = ref.watch(chatProvider(widget.exercise.id));
    final isGenerating = messages.isNotEmpty && messages.last.isStreaming;

    // Se a stream estiver ativa, força o scroll suave para baixo
    if (isGenerating) _scrollToBottom();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.backgroundPrimary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(2)),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade800, width: 0.5))),
                child: Row(
                  children: [
                    Icon(Icons.smart_toy_rounded, color: Theme.of(context).primaryColor, size: 22),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tutor IA', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                          Text('Assistente de estudo', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: Row(
                    children: [
                      _quickChip('Explica passo a passo'),
                      _quickChip('Dá-me um exemplo'),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final m = messages[i];
                    return m.role == MessageRole.user 
                        ? _userBubble(m.text) 
                        : _assistantBubble(m.text, m.isStreaming);
                  },
                ),
              ),
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
                          enabled: !isGenerating,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: isGenerating ? 'A IA está a pensar...' : 'Pergunta sobre este exercício...',
                            hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            filled: true,
                            fillColor: AppTheme.backgroundPrimary,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                          ),
                          onSubmitted: (_) => _send(),
                          textInputAction: TextInputAction.send,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: isGenerating ? Colors.grey.shade800 : Theme.of(context).primaryColor, 
                          shape: BoxShape.circle
                        ),
                        child: IconButton(
                          icon: isGenerating 
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                          onPressed: isGenerating ? null : _send,
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

  Widget _quickChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).primaryColor)),
        backgroundColor: AppTheme.surfaceSecondary,
        side: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
        visualDensity: VisualDensity.compact,
        onPressed: () {
          _controller.text = label;
          _send();
        },
      ),
    );
  }

  Widget _userBubble(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, left: 50),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16), topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16), bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
      ),
    );
  }

  Widget _assistantBubble(String text, bool isStreaming) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, right: 40),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceSecondary,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16), topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4), bottomRight: Radius.circular(16),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 2),
              child: Icon(Icons.auto_awesome, color: Theme.of(context).primaryColor, size: 16),
            ),
            Flexible(
              child: Text(
                text + (isStreaming ? ' █' : ''), // Bloco curssor estilo terminal
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, height: 1.5)
              ),
            ),
          ],
        ),
      ),
    );
  }
}