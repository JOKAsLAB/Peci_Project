import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/mock_data.dart';

/// Ecrã de Exploração — chatbot IA que gera exercícios e explica matéria.
/// O aluno interage por mensagens: pode pedir novos exercícios, esclarecer
/// dúvidas ou pedir explicações sobre tópicos específicos.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

// ── Tipos de mensagem ────────────────────────────────────────────────────────

enum _MessageRole { user, assistant }
enum _AssistantContentType { text, exercise }

class _ChatMessage {
  final _MessageRole role;
  final String? text;
  final _AssistantContentType contentType;
  final MockExercise? exercise;
  _ChatMessage({
    required this.role,
    this.text,
    this.contentType = _AssistantContentType.text,
    this.exercise,
  });
}

// ── State ────────────────────────────────────────────────────────────────────

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocus = FocusNode();
  final List<_ChatMessage> _messages = [];

  String? _selectedCourseId;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Mensagem de boas-vindas
    _messages.add(_ChatMessage(
      role: _MessageRole.assistant,
      text: 'Olá! Sou o teu assistente de estudo.\n\n'
          'Posso ajudar-te a:\n'
          '\u2022 Gerar exercícios sobre qualquer tópico\n'
          '\u2022 Explicar matéria ou conceitos\n'
          '\u2022 Resolver dúvidas\n\n'
          'Seleciona uma disciplina acima e escreve a tua pergunta!',
    ));
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Course? get _selectedCourse =>
      _selectedCourseId == null
          ? null
          : mockCourses.where((c) => c.id == _selectedCourseId).firstOrNull;

  // ── Enviar mensagem ──────────────────────────────────────────────────────

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(role: _MessageRole.user, text: text));
      _inputController.clear();
      _isTyping = true;
    });
    _scrollToBottom();

    // Simula resposta da IA (mock)
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _generateResponse(text);
      });
      _scrollToBottom();
    });
  }

  void _generateResponse(String userText) {
    final lower = userText.toLowerCase();
    final course = _selectedCourse;

    // Heurística simples para decidir se gera exercício ou explicação
    final wantsExercise = lower.contains('exerc') ||
        lower.contains('pergunta') ||
        lower.contains('quest') ||
        lower.contains('treino') ||
        lower.contains('praticar') ||
        lower.contains('gera') ||
        lower.contains('quiz');

    if (wantsExercise) {
      _generateExerciseResponse(course);
    } else {
      _generateExplanationResponse(lower, course);
    }
  }

  void _generateExerciseResponse(Course? course) {
    // Filtra exercícios pelo curso selecionado
    var available = mockExercises.toList();
    if (course != null) {
      available = available.where((e) => e.courseId == course.id).toList();
    }

    if (available.isEmpty) {
      _messages.add(_ChatMessage(
        role: _MessageRole.assistant,
        text: 'Não encontrei exercícios disponíveis${course != null ? ' para ${course.name}' : ''}. '
            'Tenta selecionar outra disciplina ou pede-me para explicar algum tópico.',
      ));
      return;
    }

    // Escolhe exercício aleatório
    final exercise = available[Random().nextInt(available.length)];
    _messages.add(_ChatMessage(
      role: _MessageRole.assistant,
      text: 'Aqui tens um exercício${course != null ? ' de ${course.shortName}' : ''}:',
    ));
    _messages.add(_ChatMessage(
      role: _MessageRole.assistant,
      contentType: _AssistantContentType.exercise,
      exercise: exercise,
    ));
  }

  void _generateExplanationResponse(String query, Course? course) {
    final courseName = course?.name ?? 'a matéria';

    // Respostas mock contextualizadas
    final explanations = <String, String>{
      'flip-flop': 'Um flip-flop é um circuito sequencial básico que armazena 1 bit de informação. '
          'Existem vários tipos:\n\n'
          '\u2022 SR — Set/Reset, o mais simples\n'
          '\u2022 D — Armazena o valor da entrada D no clock\n'
          '\u2022 JK — Versão melhorada do SR sem estado inválido\n'
          '\u2022 T — Toggle, muda de estado a cada pulso\n\n'
          'São a base de registos, contadores e memórias.',
      'pipeline': 'Pipeline é uma técnica de execução de instruções onde múltiplas instruções '
          'são sobrepostas em diferentes estágios:\n\n'
          '1. Fetch — Buscar instrução\n'
          '2. Decode — Descodificar\n'
          '3. Execute — Executar\n'
          '4. Memory — Acesso à memória\n'
          '5. Write-back — Escrever resultado\n\n'
          'Idealmente, o throughput aumenta proporcionalmente ao número de estágios.',
      'rtos': 'Um RTOS (Real-Time Operating System) é um sistema operativo '
          'desenhado para responder a eventos dentro de prazos estritos.\n\n'
          '\u2022 Hard real-time — Falhar um deadline é crítico\n'
          '\u2022 Soft real-time — Atrasos são toleráveis\n\n'
          'Exemplos: FreeRTOS, Zephyr, VxWorks.',
      'mux': 'Um multiplexador (MUX) é um circuito combinatório que seleciona '
          'uma de N entradas e encaminha-a para a saída, usando linhas de seleção.\n\n'
          '\u2022 MUX 2:1 — 2 entradas, 1 seletor\n'
          '\u2022 MUX 4:1 — 4 entradas, 2 seletores\n'
          '\u2022 MUX 8:1 — 8 entradas, 3 seletores\n\n'
          'Fórmula: para N entradas, precisas de log₂(N) linhas de seleção.',
      'alu': 'A ALU (Arithmetic Logic Unit) é a unidade do processador responsável '
          'por operações aritméticas e lógicas.\n\n'
          'Operações aritméticas: soma, subtração, incremento\n'
          'Operações lógicas: AND, OR, NOT, XOR\n'
          'Deslocamento: shift left, shift right\n\n'
          'As flags (Zero, Carry, Overflow, Sign) indicam propriedades do resultado.',
      'cache': 'A cache é uma memória rápida entre o processador e a RAM.\n\n'
          'Hierarquia típica:\n'
          '\u2022 L1 — Mais rápida, menor (32-64 KB)\n'
          '\u2022 L2 — Média (256 KB - 1 MB)\n'
          '\u2022 L3 — Maior, partilhada (4-32 MB)\n\n'
          'Políticas de mapeamento: direto, associativo, set-associativo.\n'
          'Hit rate alto = programa rápido!',
      'vhdl': 'VHDL (VHSIC Hardware Description Language) é usada para descrever '
          'circuitos digitais.\n\n'
          'Estrutura básica:\n'
          '\u2022 Entity — Define portas (interface)\n'
          '\u2022 Architecture — Define comportamento\n'
          '\u2022 Process — Bloco sequencial\n'
          '\u2022 Signal — Comunicação entre componentes\n\n'
          'Dica: usa \"rising_edge(clk)\" para detetar flancos de subida.',
      'interrupt': 'Uma interrupção é um sinal que suspende temporariamente o programa '
          'em execução para atender um evento prioritário.\n\n'
          'Tipos:\n'
          '\u2022 Hardware — Periféricos (teclado, timer, UART)\n'
          '\u2022 Software — Instruções especiais (SWI/SVC)\n'
          '\u2022 Exceção — Erros (divisão por zero, page fault)\n\n'
          'O processador guarda o contexto, executa a ISR, e depois retorna.',
      'assembly': 'Assembly é uma linguagem de baixo nível, próxima do código máquina.\n\n'
          'Vantagens:\n'
          '\u2022 Controlo total sobre o hardware\n'
          '\u2022 Otimização máxima de desempenho\n'
          '\u2022 Essencial para drivers e boot loaders\n\n'
          'Cada arquitetura (ARM, x86, RISC-V) tem o seu próprio set de instruções.',
      'barramento': 'Um barramento (bus) é um conjunto de linhas de comunicação partilhadas.\n\n'
          'Tipos:\n'
          '\u2022 Dados — Transporta dados (bidirecional)\n'
          '\u2022 Endereços — Identifica destino (unidirecional)\n'
          '\u2022 Controlo — Sinais de sincronização (R/W, clock)\n\n'
          'Largura do barramento = quantidade de bits transferidos em paralelo.',
      'registos': 'Registos são a memória mais rápida do processador.\n\n'
          'Tipos comuns:\n'
          '\u2022 PC (Program Counter) — Endereço da próxima instrução\n'
          '\u2022 SP (Stack Pointer) — Topo da pilha\n'
          '\u2022 ACC (Accumulator) — Resultado de operações\n'
          '\u2022 IR (Instruction Register) — Instrução atual\n\n'
          'Quantos mais registos, menos acessos à memória são necessários.',
      'dma': 'DMA (Direct Memory Access) permite que periféricos acedam diretamente '
          'à memória sem passar pelo processador.\n\n'
          'Processo:\n'
          '1. CPU configura o controlador DMA\n'
          '2. DMA transfere dados autonomamente\n'
          '3. DMA interrompe a CPU quando termina\n\n'
          'Vantagem: liberta o processador para outras tarefas.',
    };

    // Procura keyword nas explicações mock
    for (final entry in explanations.entries) {
      if (query.contains(entry.key)) {
        _messages.add(_ChatMessage(role: _MessageRole.assistant, text: entry.value));
        return;
      }
    }

    // Resposta genérica contextualizada
    final genericResponses = [
      'Boa pergunta sobre $courseName!\n\n'
          'Este é um tópico interessante que se relaciona com vários conceitos '
          'fundamentais da disciplina.\n\n'
          'Dica: tenta decompor a pergunta em partes mais pequenas e pesquisa cada conceito individualmente. '
          'Também podes pedir-me para gerar exercícios sobre este tema!',
      'No contexto de $courseName, este assunto é bastante relevante.\n\n'
          'Alguns passos para estudar melhor:\n'
          '\u2022 Revê os slides da aula sobre este tema\n'
          '\u2022 Pratica com exercícios (posso gerar!)\n'
          '\u2022 Tenta explicar o conceito a um colega\n\n'
          'Queres que te gere um exercício para testar o teu conhecimento?',
      'Vamos explorar este tema de $courseName!\n\n'
          'Para entender bem, recomendo:\n'
          '1. Identifica os conceitos-chave\n'
          '2. Relaciona com o que já sabes\n'
          '3. Pratica com exemplos concretos\n\n'
          'Pede-me um exercício ou pergunta algo mais específico!',
    ];
    _messages.add(_ChatMessage(
      role: _MessageRole.assistant,
      text: genericResponses[Random().nextInt(genericResponses.length)],
    ));
  }

  // ── Sugestões rápidas ──────────────────────────────────────────────────────

  void _sendQuickAction(String text) {
    _inputController.text = text;
    _sendMessage();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Explorar', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.surfaceSecondary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.textSecondary),
            onPressed: () => setState(() {
              _messages.clear();
              _messages.add(_ChatMessage(
                role: _MessageRole.assistant,
                text: 'Conversa reiniciada. Em que posso ajudar?',
              ));
            }),
            tooltip: 'Limpar conversa',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCourseSelector(),
          Expanded(child: _buildMessageList()),
          if (_messages.length <= 2) _buildQuickActions(),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── Seletor de disciplina ──────────────────────────────────────────────────

  Widget _buildCourseSelector() {
    return Container(
      color: AppTheme.surfaceSecondary,
      child: SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          children: [
            _buildCourseChip(label: 'Geral', courseId: null),
            ...mockCourses.map((c) => _buildCourseChip(
                  label: c.shortName,
                  courseId: c.id,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseChip({required String label, required String? courseId}) {
    final isSelected = _selectedCourseId == courseId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedCourseId = courseId),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.brandAccent.withValues(alpha: 0.2)
                : AppTheme.backgroundPrimary,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppTheme.brandAccent : Colors.grey.shade800,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.brandAccent : AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  // ── Lista de mensagens ─────────────────────────────────────────────────────

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isTyping) {
          return _buildTypingIndicator();
        }
        final msg = _messages[index];
        if (msg.role == _MessageRole.user) {
          return _UserBubble(text: msg.text ?? '');
        }
        if (msg.contentType == _AssistantContentType.exercise && msg.exercise != null) {
          return _ExerciseBubble(exercise: msg.exercise!);
        }
        return _AssistantBubble(text: msg.text ?? '');
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 80),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceSecondary,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DotAnimation(),
          ],
        ),
      ),
    );
  }

  // ── Sugestões rápidas ──────────────────────────────────────────────────────

  Widget _buildQuickActions() {
    final course = _selectedCourse;
    final label = course?.shortName ?? '';
    final actions = [
      'Gera um exercício${label.isNotEmpty ? ' de $label' : ''}',
      'Explica-me a matéria${label.isNotEmpty ? ' de $label' : ''}',
      'Treino rápido${label.isNotEmpty ? ' sobre $label' : ''}',
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: actions.map((a) => ActionChip(
          label: Text(a, style: const TextStyle(fontSize: 12)),
          backgroundColor: AppTheme.surfaceSecondary,
          side: BorderSide(color: AppTheme.brandAccent.withValues(alpha: 0.3)),
          labelStyle: const TextStyle(color: AppTheme.brandAccent),
          onPressed: () => _sendQuickAction(a),
        )).toList(),
      ),
    );
  }

  // ── Barra de input ─────────────────────────────────────────────────────────

  Widget _buildInputBar() {
    return SafeArea(
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
                controller: _inputController,
                focusNode: _inputFocus,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Escreve a tua pergunta...',
                  hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  filled: true,
                  fillColor: AppTheme.backgroundPrimary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
                textInputAction: TextInputAction.send,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.brandAccent,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bolhas de mensagem ──────────────────────────────────────────────────────

class _UserBubble extends StatelessWidget {
  final String text;
  const _UserBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 60),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: AppTheme.brandAccent,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
        ),
      ),
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  final String text;
  const _AssistantBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 60),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceSecondary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(right: 10, top: 2),
              child: Icon(Icons.auto_awesome, color: AppTheme.brandAccent, size: 18),
            ),
            Flexible(
              child: Text(
                text,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bolha de exercício interativo ──────────────────────────────────────────

class _ExerciseBubble extends StatefulWidget {
  final MockExercise exercise;
  const _ExerciseBubble({required this.exercise});

  @override
  State<_ExerciseBubble> createState() => _ExerciseBubbleState();
}

class _ExerciseBubbleState extends State<_ExerciseBubble> {
  int? _selectedOption;
  bool _answered = false;
  bool _showExplanation = false;

  bool get _isCorrect {
    final e = widget.exercise;
    switch (e.type) {
      case ExerciseType.multipleChoice:
      case ExerciseType.trueFalse:
        return _selectedOption == e.correctIndex;
    }
  }

  bool get _canConfirm {
    final e = widget.exercise;
    switch (e.type) {
      case ExerciseType.multipleChoice:
      case ExerciseType.trueFalse:
        return _selectedOption != null;
    }
  }

  String get _typeLabel {
    switch (widget.exercise.type) {
      case ExerciseType.multipleChoice:
        return 'Escolha Múltipla';
      case ExerciseType.trueFalse:
        return 'Verdadeiro / Falso';
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceSecondary,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.brandAccent.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.brandAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    exercise.courseName,
                    style: const TextStyle(
                      color: AppTheme.brandAccent, fontSize: 11, fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _typeLabel,
                    style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Pergunta
            Text(
              exercise.question,
              style: const TextStyle(
                color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500, height: 1.4,
              ),
            ),
            const SizedBox(height: 12),

            // Opções ou input
            if (exercise.type == ExerciseType.multipleChoice ||
                exercise.type == ExerciseType.trueFalse)
              ..._buildOptions(exercise),

            // Botão confirmar
            if (!_answered && _canConfirm) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: () => setState(() => _answered = true),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Confirmar', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],

            // Feedback
            if (_answered) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isCorrect
                      ? AppTheme.successState.withValues(alpha: 0.1)
                      : AppTheme.errorState.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: _isCorrect ? AppTheme.successState : AppTheme.errorState,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isCorrect
                            ? 'Correto! +25 XP'
                            : 'Incorreto \u2014 Resposta: ${exercise.solution}',
                        style: TextStyle(
                          color: _isCorrect ? AppTheme.successState : AppTheme.errorState,
                          fontSize: 12, fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Ver explicação
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => setState(() => _showExplanation = !_showExplanation),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showExplanation ? Icons.visibility_off_rounded : Icons.school_rounded,
                      size: 14, color: AppTheme.brandAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showExplanation ? 'Esconder' : 'Ver explicação',
                      style: const TextStyle(color: AppTheme.brandAccent, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              if (_showExplanation && exercise.explanation.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.brandAccent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.brandAccent.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    exercise.explanation,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, height: 1.5),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOptions(MockExercise exercise) {
    return List.generate(exercise.options.length, (i) {
      final isSelected = _selectedOption == i;
      final isCorrect = i == exercise.correctIndex;

      Color borderColor;
      Color textColor;
      if (_answered) {
        if (isCorrect) {
          borderColor = AppTheme.successState;
          textColor = AppTheme.successState;
        } else if (isSelected && !isCorrect) {
          borderColor = AppTheme.errorState;
          textColor = AppTheme.errorState;
        } else {
          borderColor = Colors.grey.shade800;
          textColor = AppTheme.textSecondary;
        }
      } else {
        borderColor = isSelected ? AppTheme.brandAccent : Colors.grey.shade800;
        textColor = isSelected ? AppTheme.brandAccent : AppTheme.textPrimary;
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: GestureDetector(
          onTap: _answered ? null : () => setState(() => _selectedOption = i),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _answered && isCorrect
                  ? AppTheme.successState.withValues(alpha: 0.1)
                  : _answered && isSelected && !isCorrect
                      ? AppTheme.errorState.withValues(alpha: 0.1)
                      : null,
              border: Border.all(color: borderColor, width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Text(
                  exercise.type == ExerciseType.trueFalse
                      ? (i == 0 ? 'V' : 'F')
                      : String.fromCharCode(65 + i),
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    exercise.options[i],
                    style: TextStyle(color: textColor, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// ─── Animação de "a escrever..." ─────────────────────────────────────────────

class _DotAnimation extends StatefulWidget {
  const _DotAnimation();

  @override
  State<_DotAnimation> createState() => _DotAnimationState();
}

class _DotAnimationState extends State<_DotAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final offset = (_controller.value * 3 - i).clamp(0.0, 1.0);
            final opacity = (1 - (offset - 0.5).abs() * 2).clamp(0.3, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.textSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
