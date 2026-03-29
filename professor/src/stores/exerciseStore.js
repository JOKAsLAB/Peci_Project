import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const useExerciseStore = defineStore('exercises', () => {
  const exercises = ref([
    // ── SD — Sistemas de Numeração e Códigos ─────────────────────────────────
    { id: 1, title: 'Converte 1101₂ para decimal.', module: 'Sistemas de Numeração e Códigos', discipline: 'SD', difficulty: 'Fácil', type: 'multipleChoice', options: ['11', '13', '15', '12'], correct: 1, solution: '13', explanation: '1101₂ = 1×2³+1×2²+0×2¹+1×2⁰ = 8+4+0+1 = 13.', published: true, createdAt: '2026-03-01' },
    { id: 2, title: 'Qual é a representação em BCD do número 47?', module: 'Sistemas de Numeração e Códigos', discipline: 'SD', difficulty: 'Fácil', type: 'multipleChoice', options: ['0100 0111', '0100 1001', '0011 0111', '0110 0111'], correct: 0, solution: '0100 0111', explanation: 'Em BCD, 4=0100, 7=0111 → 0100 0111.', published: true, createdAt: '2026-03-01' },
    { id: 3, title: 'O complemento para 2 de 0110 (4 bits) é:', module: 'Sistemas de Numeração e Códigos', discipline: 'SD', difficulty: 'Médio', type: 'multipleChoice', options: ['1001', '1010', '0101', '1110'], correct: 1, solution: '1010', explanation: 'Complemento para 1: 1001, +1 = 1010.', published: true, createdAt: '2026-03-01' },
    { id: 4, title: 'O código Gray garante que valores consecutivos diferem apenas em 1 bit.', module: 'Sistemas de Numeração e Códigos', discipline: 'SD', difficulty: 'Fácil', type: 'trueFalse', options: ['Verdadeiro', 'Falso'], correct: 0, solution: 'Verdadeiro', explanation: 'O código Gray é projetado com essa propriedade.', published: true, createdAt: '2026-03-01' },
    { id: 5, title: 'Qual o resultado da operação binária 1011 + 0110?', module: 'Sistemas de Numeração e Códigos', discipline: 'SD', difficulty: 'Fácil', type: 'multipleChoice', options: ['10001', '10010', '10101', '10000'], correct: 0, solution: '10001', explanation: '1011 (11) + 0110 (6) = 10001 (17).', published: true, createdAt: '2026-03-02' },
    { id: 6, title: 'Converte 255₁₀ para hexadecimal.', module: 'Sistemas de Numeração e Códigos', discipline: 'SD', difficulty: 'Fácil', type: 'multipleChoice', options: ['FE', 'FF', '1FF', 'EF'], correct: 1, solution: 'FF', explanation: '255 = 15×16+15 = FF₁₆.', published: true, createdAt: '2026-03-02' },
    { id: 7, title: 'O complemento para 1 de um número obtém-se invertendo todos os bits.', module: 'Sistemas de Numeração e Códigos', discipline: 'SD', difficulty: 'Fácil', type: 'trueFalse', options: ['Verdadeiro', 'Falso'], correct: 0, solution: 'Verdadeiro', explanation: 'O complemento para 1 inverte todos os bits do número.', published: true, createdAt: '2026-03-02' },
    { id: 8, title: 'Quantos bits são necessários para representar 256 valores distintos?', module: 'Sistemas de Numeração e Códigos', discipline: 'SD', difficulty: 'Médio', type: 'multipleChoice', options: ['7', '8', '9', '10'], correct: 1, solution: '8', explanation: '2⁸ = 256. São necessários 8 bits.', published: true, createdAt: '2026-03-02' },

    // ── SD — Álgebra de Boole e Simplificação ────────────────────────────────
    { id: 9, title: 'Segundo o teorema de De Morgan, NOT(A·B) é igual a:', module: 'Álgebra de Boole e Simplificação', discipline: 'SD', difficulty: 'Médio', type: 'multipleChoice', options: ['NOT(A)·NOT(B)', 'NOT(A)+NOT(B)', 'A+B', 'A·B'], correct: 1, solution: 'NOT(A)+NOT(B)', explanation: 'De Morgan: NOT(A·B) = NOT(A)+NOT(B).', published: true, createdAt: '2026-03-02' },
    { id: 10, title: 'A expressão AB + AB\' simplifica para A.', module: 'Álgebra de Boole e Simplificação', discipline: 'SD', difficulty: 'Médio', type: 'trueFalse', options: ['Verdadeiro', 'Falso'], correct: 0, solution: 'Verdadeiro', explanation: 'AB+AB\' = A(B+B\') = A·1 = A.', published: true, createdAt: '2026-03-02' },
    { id: 11, title: 'Qual é o resultado de simplificar F = A\'BC + ABC?', module: 'Álgebra de Boole e Simplificação', discipline: 'SD', difficulty: 'Difícil', type: 'multipleChoice', options: ['BC', 'AB', 'AC', 'A\'B'], correct: 0, solution: 'BC', explanation: 'A\'BC+ABC = BC(A\'+A) = BC.', published: true, createdAt: '2026-03-03' },
    { id: 12, title: 'A\'B + AB = B.', module: 'Álgebra de Boole e Simplificação', discipline: 'SD', difficulty: 'Médio', type: 'trueFalse', options: ['Verdadeiro', 'Falso'], correct: 0, solution: 'Verdadeiro', explanation: 'B(A\'+A) = B·1 = B.', published: true, createdAt: '2026-03-03' },
    { id: 13, title: 'O mapa de Karnaugh para 4 variáveis tem quantas células?', module: 'Álgebra de Boole e Simplificação', discipline: 'SD', difficulty: 'Fácil', type: 'multipleChoice', options: ['8', '12', '16', '32'], correct: 2, solution: '16', explanation: '2⁴ = 16 combinações possíveis.', published: true, createdAt: '2026-03-03' },
    { id: 14, title: 'NOT(NOT(A)) = A é a lei da dupla negação.', module: 'Álgebra de Boole e Simplificação', discipline: 'SD', difficulty: 'Fácil', type: 'trueFalse', options: ['Verdadeiro', 'Falso'], correct: 0, solution: 'Verdadeiro', explanation: 'A dupla negação cancela-se: NOT(NOT(A)) = A.', published: true, createdAt: '2026-03-03' },

    // ── SD — Circuitos Combinatórios ─────────────────────────────────────────
    { id: 15, title: 'Um MUX 4:1 precisa de quantas linhas de seleção?', module: 'Circuitos Combinatórios', discipline: 'SD', difficulty: 'Fácil', type: 'multipleChoice', options: ['1', '2', '3', '4'], correct: 1, solution: '2', explanation: 'log₂(4) = 2 linhas de seleção.', published: true, createdAt: '2026-03-03' },
    { id: 16, title: 'Um descodificador converte um código binário para ativar uma de N saídas.', module: 'Circuitos Combinatórios', discipline: 'SD', difficulty: 'Fácil', type: 'trueFalse', options: ['Verdadeiro', 'Falso'], correct: 0, solution: 'Verdadeiro', explanation: 'Decoder: n bits → 2ⁿ saídas, apenas uma ativa.', published: true, createdAt: '2026-03-03' },
    { id: 17, title: 'Qual componente seleciona uma de várias entradas com base em linhas de seleção?', module: 'Circuitos Combinatórios', discipline: 'SD', difficulty: 'Fácil', type: 'multipleChoice', options: ['Descodificador', 'Multiplexador', 'Somador', 'Comparador'], correct: 1, solution: 'Multiplexador', explanation: 'O MUX seleciona uma entrada baseado nas linhas de seleção.', published: true, createdAt: '2026-03-04' },
    { id: 18, title: 'Um somador completo (full adder) tem 3 entradas: A, B e Carry-in.', module: 'Circuitos Combinatórios', discipline: 'SD', difficulty: 'Médio', type: 'trueFalse', options: ['Verdadeiro', 'Falso'], correct: 0, solution: 'Verdadeiro', explanation: 'O full adder aceita A, B e Cin para produzir Sum e Cout.', published: true, createdAt: '2026-03-04' },
    { id: 19, title: 'Um MUX 8:1 precisa de quantas linhas de seleção?', module: 'Circuitos Combinatórios', discipline: 'SD', difficulty: 'Médio', type: 'multipleChoice', options: ['2', '3', '4', '8'], correct: 1, solution: '3', explanation: 'log₂(8) = 3 linhas de seleção.', published: true, createdAt: '2026-03-04' },

    // ── SD — Circuitos Sequenciais ───────────────────────────────────────────
    { id: 20, title: 'Identifica o comportamento do Flip-Flop JK quando J=1 e K=1.', module: 'Circuitos Sequenciais', discipline: 'SD', difficulty: 'Médio', type: 'multipleChoice', options: ['Mantém estado', 'Reset (0)', 'Set (1)', 'Toggle (Inverte)'], correct: 3, solution: 'Toggle', explanation: 'J=1, K=1 → o FF-JK faz toggle (inverte Q).', published: true, createdAt: '2026-03-04' },
    { id: 21, title: 'Um flip-flop D armazena o valor da entrada na transição do clock.', module: 'Circuitos Sequenciais', discipline: 'SD', difficulty: 'Fácil', type: 'trueFalse', options: ['Verdadeiro', 'Falso'], correct: 0, solution: 'Verdadeiro', explanation: 'O FF D captura D na edge do clock.', published: true, createdAt: '2026-03-04' },
    { id: 22, title: 'O flip-flop T com T=1 funciona como:', module: 'Circuitos Sequenciais', discipline: 'SD', difficulty: 'Médio', type: 'multipleChoice', options: ['Mantém o estado', 'Reset', 'Toggle', 'Set'], correct: 2, solution: 'Toggle', explanation: 'T=1 faz com que o FF T inverta o estado a cada pulso de clock.', published: true, createdAt: '2026-03-04' },
    { id: 23, title: 'Um registo de deslocamento (shift register) move bits uma posição a cada pulso de clock.', module: 'Circuitos Sequenciais', discipline: 'SD', difficulty: 'Médio', type: 'trueFalse', options: ['Verdadeiro', 'Falso'], correct: 0, solution: 'Verdadeiro', explanation: 'Shift registers deslocam bits sequencialmente.', published: true, createdAt: '2026-03-04' },
    { id: 24, title: 'Um contador assíncrono usa um único sinal de clock para todos os flip-flops.', module: 'Circuitos Sequenciais', discipline: 'SD', difficulty: 'Difícil', type: 'trueFalse', options: ['Verdadeiro', 'Falso'], correct: 1, solution: 'Falso', explanation: 'Num contador assíncrono (ripple), cada FF recebe o clock do FF anterior.', published: true, createdAt: '2026-03-05' },

    // ── SD — Máquinas de Estado ──────────────────────────────────────────────
    { id: 25, title: 'Num modelo de Moore, a saída depende de:', module: 'Máquinas de Estado', discipline: 'SD', difficulty: 'Médio', type: 'multipleChoice', options: ['Entradas e estado atual', 'Apenas do estado atual', 'Apenas das entradas', 'Estado seguinte'], correct: 1, solution: 'Apenas do estado atual', explanation: 'Moore: saída = f(estado).', published: true, createdAt: '2026-03-05' },
    { id: 26, title: 'No modelo de Mealy, a saída pode mudar sem transição de estado.', module: 'Máquinas de Estado', discipline: 'SD', difficulty: 'Difícil', type: 'trueFalse', options: ['Verdadeiro', 'Falso'], correct: 0, solution: 'Verdadeiro', explanation: 'Mealy: saída = f(estado, entradas), pode mudar se as entradas mudarem.', published: true, createdAt: '2026-03-05' },
    { id: 27, title: 'Uma máquina de Moore tipicamente precisa de mais estados que uma de Mealy equivalente.', module: 'Máquinas de Estado', discipline: 'SD', difficulty: 'Difícil', type: 'trueFalse', options: ['Verdadeiro', 'Falso'], correct: 0, solution: 'Verdadeiro', explanation: 'A máquina de Moore precisa de mais estados porque a saída está ligada ao estado.', published: true, createdAt: '2026-03-05' },

    // ── AC — Datapaths MIPS ──────────────────────────────────────────────────
    { id: 28, title: 'Qual o registo em MIPS que contém sempre o valor zero?', module: 'Datapaths MIPS', discipline: 'AC', difficulty: 'Fácil', type: 'multipleChoice', options: ['$t0', '$zero ($0)', '$ra', '$sp'], correct: 1, solution: '$zero ($0)', explanation: '$0 está hardwired a zero.', published: true, createdAt: '2026-03-03' },
    { id: 29, title: 'Na fase de Write-Back, o resultado da ALU é escrito no registo destino.', module: 'Datapaths MIPS', discipline: 'AC', difficulty: 'Fácil', type: 'trueFalse', options: ['Verdadeiro', 'Falso'], correct: 0, solution: 'Verdadeiro', explanation: 'Write-Back escreve resultado no banco de registos.', published: true, createdAt: '2026-03-03' },
    { id: 30, title: 'Em MIPS, qual instrução carrega um valor da memória para um registo?', module: 'Datapaths MIPS', discipline: 'AC', difficulty: 'Fácil', type: 'multipleChoice', options: ['sw', 'lw', 'add', 'beq'], correct: 1, solution: 'lw', explanation: 'lw (load word) carrega 32 bits da memória.', published: true, createdAt: '2026-03-03' },
    { id: 31, title: 'Qual o papel do Program Counter (PC)?', module: 'Datapaths MIPS', discipline: 'AC', difficulty: 'Fácil', type: 'multipleChoice', options: ['Armazenar dados temporários', 'Apontar para a próxima instrução', 'Realizar operações aritméticas', 'Controlar o acesso à memória'], correct: 1, solution: 'Apontar para a próxima instrução', explanation: 'O PC contém o endereço da próxima instrução.', published: true, createdAt: '2026-03-03' },
    { id: 32, title: 'A ALU em MIPS pode realizar operações aritméticas e lógicas.', module: 'Datapaths MIPS', discipline: 'AC', difficulty: 'Fácil', type: 'trueFalse', options: ['Verdadeiro', 'Falso'], correct: 0, solution: 'Verdadeiro', explanation: 'A ALU executa add, sub, AND, OR, slt, etc.', published: true, createdAt: '2026-03-04' },
    { id: 33, title: 'O banco de registos MIPS tem quantos registos?', module: 'Datapaths MIPS', discipline: 'AC', difficulty: 'Fácil', type: 'multipleChoice', options: ['8', '16', '32', '64'], correct: 2, solution: '32', explanation: 'MIPS tem 32 registos de 32 bits cada.', published: true, createdAt: '2026-03-04' },

    // ── AC — Conjunto de Instruções ──────────────────────────────────────────
    { id: 34, title: 'A instrução "addi $t0, $t1, 5" é do tipo:', module: 'Conjunto de Instruções', discipline: 'AC', difficulty: 'Médio', type: 'multipleChoice', options: ['R', 'I', 'J', 'Pseudo'], correct: 1, solution: 'I', explanation: 'addi usa valor imediato, logo é tipo I.', published: true, createdAt: '2026-03-04' },
    { id: 35, title: 'Instruções tipo R usam 3 registos (rs, rt, rd).', module: 'Conjunto de Instruções', discipline: 'AC', difficulty: 'Médio', type: 'trueFalse', options: ['Verdadeiro', 'Falso'], correct: 0, solution: 'Verdadeiro', explanation: 'Tipo R: opcode rs rt rd shamt funct.', published: true, createdAt: '2026-03-04' },
    { id: 36, title: 'Qual instrução é usada para saltos incondicionais em MIPS?', module: 'Conjunto de Instruções', discipline: 'AC', difficulty: 'Médio', type: 'multipleChoice', options: ['beq', 'j', 'bne', 'addi'], correct: 1, solution: 'j', explanation: 'j (jump) é a instrução de salto incondicional tipo J.', published: true, createdAt: '2026-03-04' },
    { id: 37, title: 'A instrução beq compara dois registos e salta se forem iguais.', module: 'Conjunto de Instruções', discipline: 'AC', difficulty: 'Fácil', type: 'trueFalse', options: ['Verdadeiro', 'Falso'], correct: 0, solution: 'Verdadeiro', explanation: 'beq = branch if equal.', published: true, createdAt: '2026-03-04' },

    // ── AC — Pipeline ────────────────────────────────────────────────────────
    { id: 38, title: 'O pipeline clássico MIPS tem 5 estágios.', module: 'Pipeline', discipline: 'AC', difficulty: 'Fácil', type: 'trueFalse', options: ['Verdadeiro', 'Falso'], correct: 0, solution: 'Verdadeiro', explanation: 'IF, ID, EX, MEM, WB — 5 estágios.', published: true, createdAt: '2026-03-04' },
    { id: 39, title: 'Um data hazard pode ser resolvido por:', module: 'Pipeline', discipline: 'AC', difficulty: 'Difícil', type: 'multipleChoice', options: ['Forwarding', 'Branch prediction', 'Reordenação do programa', 'Todas as anteriores'], correct: 0, solution: 'Forwarding', explanation: 'Data hazards resolvem-se com forwarding (bypassing).', published: true, createdAt: '2026-03-05' },
    { id: 40, title: 'Quantos estágios tem o pipeline clássico MIPS?', module: 'Pipeline', discipline: 'AC', difficulty: 'Fácil', type: 'multipleChoice', options: ['3', '4', '5', '6'], correct: 2, solution: '5', explanation: 'IF, ID, EX, MEM, WB.', published: true, createdAt: '2026-03-05' },
    { id: 41, title: 'Um stall (bolha) no pipeline degrada a performance.', module: 'Pipeline', discipline: 'AC', difficulty: 'Médio', type: 'trueFalse', options: ['Verdadeiro', 'Falso'], correct: 0, solution: 'Verdadeiro', explanation: 'Stalls introduzem ciclos mortos, reduzindo o throughput.', published: true, createdAt: '2026-03-05' },
    { id: 42, title: 'O branch prediction tenta prever o resultado de instruções de salto condicional.', module: 'Pipeline', discipline: 'AC', difficulty: 'Médio', type: 'trueFalse', options: ['Verdadeiro', 'Falso'], correct: 0, solution: 'Verdadeiro', explanation: 'Branch prediction minimiza stalls por control hazards.', published: true, createdAt: '2026-03-05' },

    // ── AC — Hierarquia de Memória ───────────────────────────────────────────
    { id: 43, title: 'Em cache de mapeamento direto, cada bloco pode ir para:', module: 'Hierarquia de Memória', discipline: 'AC', difficulty: 'Médio', type: 'multipleChoice', options: ['Qualquer posição', 'Apenas uma posição', 'Um conjunto limitado', 'Depende do tamanho'], correct: 1, solution: 'Apenas uma posição', explanation: 'Mapeamento direto: bloco → exatamente uma linha de cache.', published: true, createdAt: '2026-03-05' },
    { id: 44, title: 'Cache totalmente associativa permite que qualquer bloco vá para qualquer linha.', module: 'Hierarquia de Memória', discipline: 'AC', difficulty: 'Médio', type: 'trueFalse', options: ['Verdadeiro', 'Falso'], correct: 0, solution: 'Verdadeiro', explanation: 'Fully associative: sem restrição de posição.', published: true, createdAt: '2026-03-05' },
    { id: 45, title: 'Um cache miss significa que o dado não está na cache e precisa ser lido da memória.', module: 'Hierarquia de Memória', discipline: 'AC', difficulty: 'Fácil', type: 'trueFalse', options: ['Verdadeiro', 'Falso'], correct: 0, solution: 'Verdadeiro', explanation: 'Miss → acesso à memória principal (mais lento).', published: true, createdAt: '2026-03-05' },
    { id: 46, title: 'A política write-back escreve na memória principal apenas quando a linha é substituída.', module: 'Hierarquia de Memória', discipline: 'AC', difficulty: 'Difícil', type: 'trueFalse', options: ['Verdadeiro', 'Falso'], correct: 0, solution: 'Verdadeiro', explanation: 'Write-back: atualiza a memória só na eviction, ao contrário de write-through.', published: true, createdAt: '2026-03-06' },

    // ── SE — Periféricos e Temporizadores ────────────────────────────────────
    { id: 47, title: 'Um prescaler de 64 com clock de 16MHz produz frequência de:', module: 'Periféricos e Temporizadores', discipline: 'SE', difficulty: 'Médio', type: 'multipleChoice', options: ['250kHz', '1MHz', '4MHz', '64MHz'], correct: 0, solution: '250kHz', explanation: '16MHz / 64 = 250kHz.', published: true, createdAt: '2026-03-03' },
    { id: 48, title: 'Um watchdog timer serve para reiniciar o sistema em caso de falha.', module: 'Periféricos e Temporizadores', discipline: 'SE', difficulty: 'Fácil', type: 'trueFalse', options: ['Verdadeiro', 'Falso'], correct: 0, solution: 'Verdadeiro', explanation: 'Watchdog: se não for "alimentado", faz reset.', published: true, createdAt: '2026-03-03' },
    { id: 49, title: 'O que é um watchdog timer?', module: 'Periféricos e Temporizadores', discipline: 'SE', difficulty: 'Médio', type: 'multipleChoice', options: ['Temporizador de execução', 'Mecanismo de reset automático', 'Periférico série', 'Registo de controlo'], correct: 1, solution: 'Mecanismo de reset automático', explanation: 'O watchdog reinicia o sistema se o software bloquear.', published: false, createdAt: '2026-03-04' },
    { id: 50, title: 'O modo PWM de um timer permite gerar sinais com duty cycle variável.', module: 'Periféricos e Temporizadores', discipline: 'SE', difficulty: 'Médio', type: 'trueFalse', options: ['Verdadeiro', 'Falso'], correct: 0, solution: 'Verdadeiro', explanation: 'PWM: Pulse Width Modulation, controla o duty cycle.', published: true, createdAt: '2026-03-04' },

    // ── SE — Interrupções ────────────────────────────────────────────────────
    { id: 51, title: 'Uma ISR (Interrupt Service Routine) é executada quando ocorre uma interrupção.', module: 'Interrupções', discipline: 'SE', difficulty: 'Fácil', type: 'trueFalse', options: ['Verdadeiro', 'Falso'], correct: 0, solution: 'Verdadeiro', explanation: 'A ISR é a rotina associada a uma interrupção específica.', published: true, createdAt: '2026-03-04' },
    { id: 52, title: 'O vetor de interrupções contém:', module: 'Interrupções', discipline: 'SE', difficulty: 'Médio', type: 'multipleChoice', options: ['Dados do periférico', 'Endereços das ISRs', 'Registos do CPU', 'Flags de estado'], correct: 1, solution: 'Endereços das ISRs', explanation: 'O vetor de interrupções mapeia cada IRQ para o endereço da sua ISR.', published: true, createdAt: '2026-03-04' },
    { id: 53, title: 'Interrupções com maior prioridade podem interromper ISRs de menor prioridade.', module: 'Interrupções', discipline: 'SE', difficulty: 'Difícil', type: 'trueFalse', options: ['Verdadeiro', 'Falso'], correct: 0, solution: 'Verdadeiro', explanation: 'Nested interrupts permitem preemption por prioridade.', published: true, createdAt: '2026-03-05' },
    { id: 54, title: 'Desativar interrupções globalmente é útil para proteger secções críticas.', module: 'Interrupções', discipline: 'SE', difficulty: 'Médio', type: 'trueFalse', options: ['Verdadeiro', 'Falso'], correct: 0, solution: 'Verdadeiro', explanation: 'Desativar IRQs evita race conditions em código crítico.', published: true, createdAt: '2026-03-05' },

    // ── SE — Comunicação Série ───────────────────────────────────────────────
    { id: 55, title: 'UART é um protocolo de comunicação série assíncrono.', module: 'Comunicação Série', discipline: 'SE', difficulty: 'Fácil', type: 'trueFalse', options: ['Verdadeiro', 'Falso'], correct: 0, solution: 'Verdadeiro', explanation: 'UART não usa sinal de clock partilhado.', published: true, createdAt: '2026-03-05' },
    { id: 56, title: 'Qual protocolo usa linhas MOSI, MISO, SCLK e SS?', module: 'Comunicação Série', discipline: 'SE', difficulty: 'Médio', type: 'multipleChoice', options: ['UART', 'I2C', 'SPI', 'CAN'], correct: 2, solution: 'SPI', explanation: 'SPI usa MOSI, MISO, SCLK e SS (chip select).', published: true, createdAt: '2026-03-05' },
    { id: 57, title: 'I2C usa apenas 2 linhas: SDA (dados) e SCL (clock).', module: 'Comunicação Série', discipline: 'SE', difficulty: 'Fácil', type: 'trueFalse', options: ['Verdadeiro', 'Falso'], correct: 0, solution: 'Verdadeiro', explanation: 'I2C: barramento de 2 fios (SDA + SCL).', published: true, createdAt: '2026-03-05' },
    { id: 58, title: 'Qual a principal vantagem do SPI sobre I2C?', module: 'Comunicação Série', discipline: 'SE', difficulty: 'Difícil', type: 'multipleChoice', options: ['Menos fios', 'Mais dispositivos', 'Maior velocidade', 'Menor consumo'], correct: 2, solution: 'Maior velocidade', explanation: 'SPI é full-duplex e suporta frequências mais elevadas que I2C.', published: true, createdAt: '2026-03-06' },
  ])

  // Estado Transacional
  const isLoading = ref(false)
  const error = ref(null)

  const publishedExercises = computed(() => exercises.value.filter(e => e.published))
  const draftExercises = computed(() => exercises.value.filter(e => !e.published))

  const disciplines = computed(() => [...new Set(exercises.value.map(e => e.discipline))])
  const modules = computed(() => [...new Set(exercises.value.map(e => e.module))])
  const modulesByDiscipline = computed(() => {
    const map = {}
    for (const ex of exercises.value) {
      if (!map[ex.discipline]) map[ex.discipline] = new Set()
      map[ex.discipline].add(ex.module)
    }
    return Object.fromEntries(Object.entries(map).map(([k, v]) => [k, [...v]]))
  })

  const byDiscipline = computed(() => {
    const map = {}
    for (const ex of exercises.value) {
      if (!map[ex.discipline]) map[ex.discipline] = []
      map[ex.discipline].push(ex)
    }
    return map
  })

  async function addExercise(exercise) {
    isLoading.value = true; error.value = null
    try {
      await new Promise(resolve => setTimeout(resolve, 400))
      exercises.value.push({
        ...exercise,
        id: Date.now(),
        createdAt: new Date().toISOString().split('T')[0]
      })
    } catch (e) {
      error.value = 'Falha ao gravar exercício no servidor.'
    } finally {
      isLoading.value = false
    }
  }

  async function removeExercise(id) {
    isLoading.value = true; error.value = null
    try {
      await new Promise(resolve => setTimeout(resolve, 300))
      exercises.value = exercises.value.filter(e => e.id !== id)
    } catch (e) {
      error.value = 'Erro ao remover exercício.'
    } finally {
      isLoading.value = false
    }
  }

  async function togglePublished(id) {
    isLoading.value = true; error.value = null
    try {
      await new Promise(resolve => setTimeout(resolve, 300))
      const ex = exercises.value.find(e => e.id === id)
      if (ex) ex.published = !ex.published
    } catch (e) {
      error.value = 'Erro ao alterar estado de publicação.'
    } finally {
      isLoading.value = false
    }
  }

  async function updateExercise(id, data) {
    isLoading.value = true; error.value = null
    try {
      await new Promise(resolve => setTimeout(resolve, 400))
      const idx = exercises.value.findIndex(e => e.id === id)
      if (idx !== -1) {
        exercises.value[idx] = { ...exercises.value[idx], ...data }
      }
    } catch (e) {
      error.value = 'Falha ao atualizar dados do exercício.'
    } finally {
      isLoading.value = false
    }
  }

  return {
    exercises, isLoading, error, publishedExercises, draftExercises,
    disciplines, modules, modulesByDiscipline, byDiscipline,
    addExercise, removeExercise, togglePublished, updateExercise
  }
})