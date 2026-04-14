import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/mock_data.dart';
import '../../../data/models/exercise.dart';

enum MessageRole { user, assistant }

class ChatMessage {
  final MessageRole role;
  final String text;
  final bool isStreaming;

  const ChatMessage({
    required this.role,
    required this.text,
    this.isStreaming = false,
  });

  ChatMessage copyWith({String? text, bool? isStreaming}) {
    return ChatMessage(
      role: role,
      text: text ?? this.text,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}

/// O uso de Family permite manter uma sessão de chat independente por cada exercício.
final chatProvider = StateNotifierProvider.family<ChatNotifier, List<ChatMessage>, String>((ref, exerciseId) {
  final exercise = mockExercises.firstWhere((e) => e.id == exerciseId);
  return ChatNotifier(exercise);
});

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final Exercise exercise;
  bool _isGenerating = false;

  ChatNotifier(this.exercise) : super([]) {
    _initializeContext();
  }

  void _initializeContext() {
    final correctLabel = exercise.options[exercise.correctIndex];
    state = [
      ChatMessage(
        role: MessageRole.assistant,
        text: 'A pergunta era:\n\n«${exercise.question}»\n\nA resposta correta é: $correctLabel\n\n'
            '${exercise.explanation.isNotEmpty ? '${exercise.explanation}\n\n' : ''}'
            'Como te posso ajudar a compreender melhor este conceito?',
      )
    ];
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _isGenerating) return;

    // 1. Adiciona a mensagem do utilizador
    state = [...state, ChatMessage(role: MessageRole.user, text: text.trim())];
    
    // 2. Prepara o placeholder (streaming ativo) para a IA
    _isGenerating = true;
    state = [...state, const ChatMessage(role: MessageRole.assistant, text: '', isStreaming: true)];

    // 3. Simula a receção de tokens via Stream (preparação para SSE da FastAPI)
    final responsePayload = _generateMockPayload(text);
    final tokens = responsePayload.split(' ');
    
    String currentText = '';
    
    // Simula a latência de rede e processamento da LLM (token a token)
    for (int i = 0; i < tokens.length; i++) {
      await Future.delayed(Duration(milliseconds: 30 + Random().nextInt(50)));
      currentText += (i == 0 ? '' : ' ') + tokens[i];
      
      // Atualiza estritamente a última mensagem do estado
      state = [
        ...state.sublist(0, state.length - 1),
        state.last.copyWith(text: currentText),
      ];
    }

    // 4. Finaliza a stream
    state = [
      ...state.sublist(0, state.length - 1),
      state.last.copyWith(isStreaming: false),
    ];
    _isGenerating = false;
  }

  String _generateMockPayload(String query) {
    final lower = query.toLowerCase();
    if (lower.contains('passo')) {
      return 'Vamos por partes:\n1. Identificamos o pedido: "${exercise.question}"\n2. A opção correta é a única que respeita o contexto da matéria de ${exercise.courseName}.';
    }
    if (lower.contains('exemplo')) {
      return 'Pensa nesta analogia prática para Sistemas Digitais/Arquitetura: A resposta atua como um interruptor que valida apenas a condição "${exercise.options[exercise.correctIndex]}".';
    }
    return 'Compreendo a tua dúvida. Em ${exercise.courseName}, é essencial dominar "${exercise.chapterName}". A resposta correta aplica-se porque a lógica subjacente exige esse comportamento exato.';
  }
}