import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const usePathStore = defineStore('paths', () => {
  // Caminho base de aprendizagem por disciplina
  // Cada disciplina tem módulos (capítulos) com exercícios
  const paths = ref([
    {
      id: 'path-sd',
      disciplineCode: 'SD',
      disciplineName: 'Sistemas Digitais',
      published: true,
      lastModified: '2026-03-05',
      modules: [
        {
          id: 'sd-m1',
          title: 'Sistemas de Numeração e Códigos',
          description: 'Conversão entre bases numéricas, código BCD, Gray e complementos.',
          order: 1,
          xpReward: 50,
          status: 'published',
          exercises: [
            { id: 'sd-m1-e1', type: 'multipleChoice', title: 'Converte 1101₂ para decimal.', options: ['11', '13', '15', '12'], correct: 1, difficulty: 'Fácil', solution: '13', explanation: '1101₂ = 1×2³ + 1×2² + 0×2¹ + 1×2⁰ = 8 + 4 + 0 + 1 = 13.' },
            { id: 'sd-m1-e2', type: 'multipleChoice', title: 'Qual é a representação em BCD do número 47?', options: ['0100 0111', '0100 1001', '0011 0111', '0110 0111'], correct: 0, difficulty: 'Fácil', solution: '0100 0111', explanation: 'Em BCD, cada dígito decimal é representado por 4 bits: 4 = 0100, 7 = 0111 → 0100 0111.' },
            { id: 'sd-m1-e3', type: 'multipleChoice', title: 'O complemento para 2 de 0110 (4 bits) é:', options: ['1001', '1010', '0101', '1110'], correct: 1, difficulty: 'Médio', solution: '1010', explanation: 'Complemento para 1 de 0110 é 1001, somando 1 obtemos 1010.' },
            { id: 'sd-m1-e4', type: 'trueFalse', title: 'O código Gray garante que valores consecutivos diferem apenas em 1 bit.', options: ['Verdadeiro', 'Falso'], correct: 0, difficulty: 'Fácil', solution: 'Verdadeiro', explanation: 'O código Gray é projetado com essa propriedade — valores adjacentes diferem em apenas 1 bit.' },
          ]
        },
        {
          id: 'sd-m2',
          title: 'Álgebra de Boole e Simplificação',
          description: 'Teoremas de De Morgan, mapas de Karnaugh e simplificação de expressões.',
          order: 2,
          xpReward: 75,
          status: 'published',
          exercises: [
            { id: 'sd-m2-e1', type: 'multipleChoice', title: 'Segundo o teorema de De Morgan, NOT(A·B) é igual a:', options: ['NOT(A) · NOT(B)', 'NOT(A) + NOT(B)', 'A + B', 'A · B'], correct: 1, difficulty: 'Fácil', solution: 'NOT(A) + NOT(B)', explanation: 'O teorema de De Morgan afirma que NOT(A·B) = NOT(A) + NOT(B).' },
            { id: 'sd-m2-e2', type: 'trueFalse', title: 'A expressão AB + AB\' simplifica para A.', options: ['Verdadeiro', 'Falso'], correct: 0, difficulty: 'Médio', solution: 'Verdadeiro', explanation: 'AB + AB\' = A(B + B\') = A·1 = A.' },
            { id: 'sd-m2-e3', type: 'multipleChoice', title: 'Qual é a expressão simplificada de F = AB + AB\' usando álgebra de Boole?', options: ['A', 'B', 'AB', '0'], correct: 0, difficulty: 'Médio', solution: 'A', explanation: 'AB + AB\' = A(B + B\') = A·1 = A.' },
          ]
        },
        {
          id: 'sd-m3',
          title: 'Circuitos Combinatórios',
          description: 'Multiplexadores, descodificadores, somadores e comparadores.',
          order: 3,
          xpReward: 100,
          status: 'published',
          exercises: [
            { id: 'sd-m3-e1', type: 'multipleChoice', title: 'Um MUX 4:1 precisa de quantas linhas de seleção?', options: ['1', '2', '3', '4'], correct: 1, difficulty: 'Fácil', solution: '2', explanation: 'Um MUX 4:1 tem 4 entradas, logo precisa de log₂(4) = 2 linhas de seleção.' },
            { id: 'sd-m3-e2', type: 'multipleChoice', title: 'O componente que converte um código binário para ativar uma de N saídas chama-se:', options: ['Multiplexador', 'Descodificador', 'Somador', 'Comparador'], correct: 1, difficulty: 'Médio', solution: 'Descodificador', explanation: 'Um descodificador (decoder) converte uma entrada binária de n bits numa única saída ativa de entre 2ⁿ possíveis.' },
          ]
        },
        {
          id: 'sd-m4',
          title: 'Circuitos Sequenciais',
          description: 'Flip-flops (SR, JK, D, T), registos de deslocamento e contadores.',
          order: 4,
          xpReward: 100,
          status: 'published',
          exercises: [
            { id: 'sd-m4-e1', type: 'multipleChoice', title: 'Identifica a tabela de verdade do Flip-Flop JK quando J=1 e K=1.', options: ['Mantém estado', 'Reset (0)', 'Set (1)', 'Toggle (Inverte)'], correct: 3, difficulty: 'Médio', solution: 'Toggle (Inverte)', explanation: 'Quando J=1 e K=1, o FF-JK faz toggle, invertendo o estado atual.' },
            { id: 'sd-m4-e2', type: 'trueFalse', title: 'Um flip-flop D armazena o valor da entrada na transição do clock.', options: ['Verdadeiro', 'Falso'], correct: 0, difficulty: 'Fácil', solution: 'Verdadeiro', explanation: 'O flip-flop D captura o valor da entrada D na transição (edge) do sinal de clock.' },
          ]
        },
        {
          id: 'sd-m5',
          title: 'Máquinas de Estado',
          description: 'Modelos de Moore e Mealy, diagramas de transição e implementação.',
          order: 5,
          xpReward: 125,
          status: 'draft',
          exercises: [
            { id: 'sd-m5-e1', type: 'multipleChoice', title: 'Num modelo de Moore, a saída depende de:', options: ['Entradas e estado atual', 'Apenas do estado atual', 'Apenas das entradas', 'Estado seguinte'], correct: 1, difficulty: 'Médio', solution: 'Apenas do estado atual', explanation: 'No modelo de Moore, a saída é função apenas do estado atual.' },
          ]
        }
      ]
    },
    {
      id: 'path-ac',
      disciplineCode: 'AC',
      disciplineName: 'Arquitetura de Computadores',
      published: true,
      lastModified: '2026-03-04',
      modules: [
        {
          id: 'ac-m1',
          title: 'Datapaths MIPS',
          description: 'Componentes do datapath, ALU, registos e memória.',
          order: 1,
          xpReward: 75,
          status: 'published',
          exercises: [
            { id: 'ac-m1-e1', type: 'multipleChoice', title: 'Qual o registo em MIPS que contém sempre o valor zero?', options: ['$t0', '$zero ($0)', '$ra', '$sp'], correct: 1, difficulty: 'Fácil', solution: '$zero ($0)', explanation: 'O registo $0 está hardwired a zero em MIPS.' },
            { id: 'ac-m1-e2', type: 'trueFalse', title: 'Na fase de Write-Back, o resultado da ALU é escrito no registo destino.', options: ['Verdadeiro', 'Falso'], correct: 0, difficulty: 'Médio', solution: 'Verdadeiro', explanation: 'A fase de Write-Back é onde o resultado da ALU é escrito de volta no banco de registos.' },
          ]
        },
        {
          id: 'ac-m2',
          title: 'Conjunto de Instruções',
          description: 'Tipos de instrução (R, I, J), endereçamento e codificação.',
          order: 2,
          xpReward: 75,
          status: 'published',
          exercises: [
            { id: 'ac-m2-e1', type: 'multipleChoice', title: 'A instrução "addi $t0, $t1, 5" é do tipo:', options: ['R', 'I', 'J', 'Pseudo'], correct: 1, difficulty: 'Fácil', solution: 'I', explanation: 'A instrução addi usa um valor imediato, logo é do tipo I (Immediate).' },
          ]
        },
        {
          id: 'ac-m3',
          title: 'Pipeline',
          description: 'Pipeline de 5 estágios, hazards e forwarding.',
          order: 3,
          xpReward: 100,
          status: 'published',
          exercises: [
            { id: 'ac-m3-e1', type: 'multipleChoice', title: 'Quantos estágios tem o pipeline clássico MIPS?', options: ['3', '4', '5', '6'], correct: 2, difficulty: 'Fácil', solution: '5', explanation: 'IF, ID, EX, MEM e WB — 5 estágios.' },
            { id: 'ac-m3-e2', type: 'multipleChoice', title: 'Um data hazard pode ser resolvido por:', options: ['Forwarding', 'Branch prediction', 'Reordenação do programa', 'Todas as anteriores'], correct: 0, difficulty: 'Médio', solution: 'Forwarding', explanation: 'Data hazards são resolvidos principalmente por forwarding (bypassing).' },
          ]
        },
        {
          id: 'ac-m4',
          title: 'Hierarquia de Memória',
          description: 'Cache (mapeamento direto, associativo), miss/hit, write policies.',
          order: 4,
          xpReward: 100,
          status: 'draft',
          exercises: [
            { id: 'ac-m4-e1', type: 'multipleChoice', title: 'Em cache de mapeamento direto, cada bloco de memória pode ir para:', options: ['Qualquer posição', 'Apenas uma posição', 'Um conjunto limitado', 'Depende do tamanho'], correct: 1, difficulty: 'Médio', solution: 'Apenas uma posição', explanation: 'No mapeamento direto, cada bloco é mapeado para exatamente uma linha de cache.' },
          ]
        }
      ]
    },
    {
      id: 'path-se',
      disciplineCode: 'SE',
      disciplineName: 'Sistemas Embutidos',
      published: false,
      lastModified: '2026-03-02',
      modules: [
        {
          id: 'se-m1',
          title: 'Periféricos e Temporizadores',
          description: 'Configuração de timers, prescalers e modos de operação.',
          order: 1,
          xpReward: 75,
          status: 'published',
          exercises: [
            { id: 'se-m1-e1', type: 'multipleChoice', title: 'Um prescaler de 64 com clock de 16MHz produz frequência de:', options: ['250kHz', '1MHz', '4MHz', '64MHz'], correct: 0, difficulty: 'Médio', solution: '250kHz', explanation: '16MHz ÷ 64 = 250kHz.' },
            { id: 'se-m1-e2', type: 'trueFalse', title: 'Um watchdog timer serve para reiniciar o sistema em caso de falha.', options: ['Verdadeiro', 'Falso'], correct: 0, difficulty: 'Fácil', solution: 'Verdadeiro', explanation: 'O watchdog timer efetua um reset do sistema se não for "alimentado" periodicamente.' },
          ]
        },
        {
          id: 'se-m2',
          title: 'Interrupções',
          description: 'Vetor de interrupções, prioridade e rotinas ISR.',
          order: 2,
          xpReward: 75,
          status: 'draft',
          exercises: []
        },
        {
          id: 'se-m3',
          title: 'Comunicação Série',
          description: 'UART, SPI e I2C — configuração e protocolos.',
          order: 3,
          xpReward: 100,
          status: 'draft',
          exercises: []
        }
      ]
    }
  ])

  const publishedPaths = computed(() => paths.value.filter(p => p.published))

  const totalModules = computed(() => paths.value.reduce((sum, p) => sum + p.modules.length, 0))

  const totalExercisesInPaths = computed(() =>
    paths.value.reduce((sum, p) => sum + p.modules.reduce((ms, m) => ms + m.exercises.length, 0), 0)
  )

  function getPath(disciplineCode) {
    return paths.value.find(p => p.disciplineCode === disciplineCode)
  }

  function addModule(pathId, module) {
    const path = paths.value.find(p => p.id === pathId)
    if (path) {
      const order = path.modules.length + 1
      path.modules.push({ ...module, order, exercises: module.exercises || [], status: 'draft' })
      path.lastModified = new Date().toISOString().split('T')[0]
    }
  }

  function updateModule(pathId, moduleId, data) {
    const path = paths.value.find(p => p.id === pathId)
    if (!path) return
    const idx = path.modules.findIndex(m => m.id === moduleId)
    if (idx !== -1) {
      path.modules[idx] = { ...path.modules[idx], ...data }
      path.lastModified = new Date().toISOString().split('T')[0]
    }
  }

  function removeModule(pathId, moduleId) {
    const path = paths.value.find(p => p.id === pathId)
    if (path) {
      path.modules = path.modules.filter(m => m.id !== moduleId)
      path.modules.forEach((m, i) => m.order = i + 1)
      path.lastModified = new Date().toISOString().split('T')[0]
    }
  }

  function moveModuleUp(pathId, moduleId) {
    const path = paths.value.find(p => p.id === pathId)
    if (!path) return
    const idx = path.modules.findIndex(m => m.id === moduleId)
    if (idx > 0) {
      const temp = path.modules[idx]
      path.modules[idx] = path.modules[idx - 1]
      path.modules[idx - 1] = temp
      path.modules.forEach((m, i) => m.order = i + 1)
    }
  }

  function moveModuleDown(pathId, moduleId) {
    const path = paths.value.find(p => p.id === pathId)
    if (!path) return
    const idx = path.modules.findIndex(m => m.id === moduleId)
    if (idx < path.modules.length - 1) {
      const temp = path.modules[idx]
      path.modules[idx] = path.modules[idx + 1]
      path.modules[idx + 1] = temp
      path.modules.forEach((m, i) => m.order = i + 1)
    }
  }

  function addExerciseToModule(pathId, moduleId, exercise) {
    const path = paths.value.find(p => p.id === pathId)
    if (!path) return
    const mod = path.modules.find(m => m.id === moduleId)
    if (mod) {
      mod.exercises.push(exercise)
      path.lastModified = new Date().toISOString().split('T')[0]
    }
  }

  function removeExerciseFromModule(pathId, moduleId, exerciseId) {
    const path = paths.value.find(p => p.id === pathId)
    if (!path) return
    const mod = path.modules.find(m => m.id === moduleId)
    if (mod) {
      mod.exercises = mod.exercises.filter(e => e.id !== exerciseId)
      path.lastModified = new Date().toISOString().split('T')[0]
    }
  }

  function updateExerciseInModule(pathId, moduleId, exerciseId, data) {
    const path = paths.value.find(p => p.id === pathId)
    if (!path) return
    const mod = path.modules.find(m => m.id === moduleId)
    if (!mod) return
    const idx = mod.exercises.findIndex(e => e.id === exerciseId)
    if (idx !== -1) mod.exercises[idx] = { ...mod.exercises[idx], ...data }
  }

  function togglePathPublished(pathId) {
    const path = paths.value.find(p => p.id === pathId)
    if (path) path.published = !path.published
  }

  function toggleModuleStatus(pathId, moduleId) {
    const path = paths.value.find(p => p.id === pathId)
    if (!path) return
    const mod = path.modules.find(m => m.id === moduleId)
    if (mod) mod.status = mod.status === 'published' ? 'draft' : 'published'
  }

  return {
    paths, publishedPaths, totalModules, totalExercisesInPaths,
    getPath, addModule, updateModule, removeModule,
    moveModuleUp, moveModuleDown,
    addExerciseToModule, removeExerciseFromModule, updateExerciseInModule,
    togglePathPublished, toggleModuleStatus
  }
})
