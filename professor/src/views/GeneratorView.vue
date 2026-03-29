<template>
  <div class="space-y-8">
    <div class="flex justify-between items-end">
      <div>
        <p class="text-brand font-bold text-sm uppercase tracking-widest mb-1">Inteligência Artificial</p>
        <h3 class="text-3xl font-bold">Laboratório de Conteúdo IA</h3>
        <p class="text-text-secondary mt-1">Gere exercícios com IA a partir dos PDFs da UC. Edite, refine e publique.</p>
      </div>
      <button @click="publishAll" :disabled="generatedExercises.length === 0"
              class="bg-success text-black px-6 py-3 rounded-btn font-bold hover:brightness-110 transition-all flex items-center gap-2 disabled:opacity-30 disabled:cursor-not-allowed">
        <i class="pi pi-cloud-upload"></i> Publicar Todos
      </button>
    </div>

    <!-- Painel de configuração -->
    <div class="grid grid-cols-12 gap-6">
      <!-- Sidebar de geração -->
      <div class="col-span-4 space-y-4">
        <div class="bg-surface p-6 rounded-card border border-white/5">
          <label class="text-xs font-bold text-brand uppercase tracking-widest">Disciplina</label>
          <select v-model="selectedDiscipline" class="w-full bg-background mt-2 p-3 rounded-btn border border-white/10 outline-none focus:border-brand text-sm">
            <option value="SD">Sistemas Digitais (SD)</option>
            <option value="AC">Arquitetura de Computadores (AC)</option>
            <option value="SE">Sistemas Embutidos (SE)</option>
          </select>

          <label class="text-xs font-bold text-brand uppercase tracking-widest mt-4 block">Capítulo / Tópico</label>
          <select v-model="selectedChapter" class="w-full bg-background mt-2 p-3 rounded-btn border border-white/10 outline-none focus:border-brand text-sm">
            <option v-for="ch in chaptersForDiscipline" :key="ch" :value="ch">{{ ch }}</option>
          </select>

          <label class="text-xs font-bold text-text-secondary uppercase tracking-widest mt-4 block">Dificuldade</label>
          <div class="flex gap-2 mt-2">
            <button v-for="d in ['Fácil', 'Médio', 'Difícil']" :key="d"
                    @click="selectedDifficulty = d"
                    :class="selectedDifficulty === d ? 'bg-brand text-white' : 'bg-background text-text-secondary border border-white/10'"
                    class="px-4 py-2 rounded-chip text-xs font-bold transition-all">
              {{ d }}
            </button>
          </div>

          <label class="text-xs font-bold text-text-secondary uppercase tracking-widest mt-4 block">Tipo de Exercício</label>
          <div class="flex flex-wrap gap-2 mt-2">
            <button v-for="t in exerciseTypes" :key="t.value"
                    @click="selectedType = t.value"
                    :class="selectedType === t.value ? 'bg-brand text-white' : 'bg-background text-text-secondary border border-white/10'"
                    class="px-4 py-2 rounded-chip text-xs font-bold transition-all">
              {{ t.label }}
            </button>
          </div>

          <label class="text-xs font-bold text-text-secondary uppercase tracking-widest mt-4 block">Quantidade</label>
          <input v-model.number="quantity" type="number" min="1" max="20"
                 class="w-full bg-background mt-2 p-3 rounded-btn border border-white/10 outline-none focus:border-brand text-sm" />
        </div>

        <div class="bg-surface p-6 rounded-card border border-white/5">
          <label class="text-xs font-bold text-brand uppercase tracking-widest">Instruções para a IA</label>
          <textarea v-model="customPrompt" rows="4" placeholder="Ex: Foca em diagramas de tempo. Evita perguntas sobre conversão hexadecimal..."
                    class="w-full bg-background mt-2 p-4 rounded-btn border border-white/10 outline-none focus:border-brand text-sm resize-none"></textarea>
        </div>

        <button @click="generate" :disabled="loading"
                class="w-full bg-brand py-4 rounded-btn font-bold flex items-center justify-center gap-2 hover:brightness-110 transition-all disabled:opacity-50">
          <i v-if="loading" class="pi pi-spin pi-spinner"></i>
          <i v-else class="pi pi-bolt"></i>
          {{ loading ? 'A processar RAG...' : 'Gerar Exercícios' }}
        </button>
      </div>

      <!-- Exercícios gerados -->
      <div class="col-span-8 space-y-4">
        <div v-if="generatedExercises.length === 0 && !loading" class="bg-surface rounded-card border border-white/5 border-dashed p-12 text-center">
          <i class="pi pi-bolt text-4xl text-brand/30 mb-4 block"></i>
          <p class="text-text-secondary">Configure os parâmetros e clique em <strong class="text-brand">Gerar Exercícios</strong> para começar.</p>
          <p class="text-text-secondary text-xs mt-2">O motor RAG irá usar os PDFs ingeridos para criar exercícios contextualizados.</p>
        </div>

        <div v-for="(ex, index) in generatedExercises" :key="ex.id" class="bg-surface p-6 rounded-card border border-white/5 relative group">
          <!-- Ações hover -->
          <div class="absolute right-4 top-4 flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
            <button @click="regenerateOne(index)" class="text-text-secondary hover:text-brand" title="Regenerar esta pergunta">
              <i class="pi pi-refresh"></i>
            </button>
            <button @click="publishOne(index)" class="text-text-secondary hover:text-success" title="Publicar">
              <i class="pi pi-cloud-upload"></i>
            </button>
            <button @click="removeGenerated(index)" class="text-text-secondary hover:text-error" title="Remover">
              <i class="pi pi-trash"></i>
            </button>
          </div>

          <!-- Badge -->
          <div class="flex items-center gap-2 mb-3">
            <span class="bg-brand/10 text-brand text-[10px] font-bold uppercase tracking-widest px-3 py-1 rounded-chip">
              {{ ex.discipline }} — {{ ex.chapter }}
            </span>
            <span class="text-[10px] font-bold uppercase tracking-widest px-3 py-1 rounded-chip"
                  :class="ex.difficulty === 'Fácil' ? 'bg-success/10 text-success' : ex.difficulty === 'Médio' ? 'bg-warning/10 text-warning' : 'bg-error/10 text-error'">
              {{ ex.difficulty }}
            </span>
            <span class="text-[10px] font-bold uppercase tracking-widest px-3 py-1 rounded-chip"
                  :class="typeClass(ex.type)">
              {{ typeLabel(ex.type) }}
            </span>
          </div>

          <!-- Título editável -->
          <input v-model="ex.title" class="bg-transparent text-lg font-bold w-full border-b border-white/5 focus:border-brand outline-none pb-2 mb-4" />
          
          <!-- Opções editáveis (para MC e V/F) -->
          <div v-if="ex.type === 'multipleChoice' || ex.type === 'trueFalse'" class="grid grid-cols-2 gap-3">
            <div v-for="(opt, oIdx) in ex.options" :key="oIdx"
                 class="flex items-center gap-3 p-3 rounded-btn border transition-all cursor-pointer"
                 :class="oIdx === ex.correct ? 'bg-success/10 border-success/30' : 'bg-background border-white/5 hover:border-white/10'"
                 @click="ex.correct = oIdx">
              <div class="w-5 h-5 rounded-full border-2 flex items-center justify-center shrink-0"
                   :class="oIdx === ex.correct ? 'border-success bg-success' : 'border-white/20'">
                <i v-if="oIdx === ex.correct" class="pi pi-check text-[10px] text-black"></i>
              </div>
              <input v-model="ex.options[oIdx]" class="bg-transparent text-sm w-full outline-none" @click.stop />
            </div>
          </div>

          <!-- Resposta correta (para escrita e fill blank) -->
          <div v-if="ex.type === 'written' || ex.type === 'fillBlank'" class="mb-3">
            <label class="text-xs font-bold text-success uppercase tracking-widest">Resposta Correta</label>
            <input v-model="ex.correctAnswer" class="w-full bg-background mt-1 p-3 rounded-btn border border-success/30 outline-none focus:border-success text-sm" />
          </div>

          <!-- Solução e explicação -->
          <div class="mt-4 space-y-3">
            <div>
              <label class="text-xs font-bold text-brand uppercase tracking-widest">Solução</label>
              <input v-model="ex.solution" class="w-full bg-background mt-1 p-3 rounded-btn border border-white/10 outline-none focus:border-brand text-sm" placeholder="Resposta correta resumida..." />
            </div>
            <div>
              <label class="text-xs font-bold text-brand uppercase tracking-widest">Explicação</label>
              <textarea v-model="ex.explanation" rows="2" class="w-full bg-background mt-1 p-3 rounded-btn border border-white/10 outline-none focus:border-brand text-sm resize-none" placeholder="Explicação detalhada para o aluno..."></textarea>
            </div>
          </div>

          <!-- Campo de instrução para regenerar individual -->
          <div v-if="ex.showRefine" class="mt-4 flex gap-2">
            <input v-model="ex.refinePrompt" placeholder="Instruções de refinamento... Ex: 'Torna mais difícil' ou 'Reformula sem tabelas de verdade'"
                   class="flex-1 bg-background p-3 rounded-btn border border-white/10 outline-none focus:border-brand text-sm" />
            <button @click="regenerateOne(index)" class="bg-brand px-4 rounded-btn text-sm font-bold">
              <i class="pi pi-refresh"></i>
            </button>
          </div>
          <button @click="ex.showRefine = !ex.showRefine" class="text-text-secondary text-xs mt-3 hover:text-brand transition-colors flex items-center gap-1">
            <i class="pi pi-pencil text-[10px]"></i>
            {{ ex.showRefine ? 'Esconder refinamento' : 'Refinar com IA' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useExerciseStore } from '../stores/exerciseStore'

const exerciseStore = useExerciseStore()

const selectedDiscipline = ref('SD')
const selectedChapter = ref('Circuitos Sequenciais')
const selectedDifficulty = ref('Médio')
const selectedType = ref('multipleChoice')
const quantity = ref(3)
const customPrompt = ref('')
const loading = ref(false)
const generatedExercises = ref([])

const exerciseTypes = [
  { value: 'multipleChoice', label: 'Escolha Múltipla' },
  { value: 'trueFalse', label: 'V/F' },
  { value: 'written', label: 'Escrita' },
  { value: 'fillBlank', label: 'Completar' },
]

const typeLabels = { multipleChoice: 'Escolha Múltipla', trueFalse: 'V/F', written: 'Escrita', fillBlank: 'Completar' }
const typeLabel = (type) => typeLabels[type] || 'Escolha Múltipla'
const typeClass = (type) => ({
  multipleChoice: 'bg-brand/10 text-brand',
  trueFalse: 'bg-purple-500/10 text-purple-400',
  written: 'bg-blue-500/10 text-blue-400',
  fillBlank: 'bg-orange-500/10 text-orange-400',
}[type] || 'bg-brand/10 text-brand')

const chapterMap = {
  SD: ['Sistemas de Numeração e Códigos', 'Álgebra de Boole e Simplificação', 'Circuitos Combinatórios', 'Circuitos Sequenciais', 'Máquinas de Estado'],
  AC: ['Datapaths MIPS', 'Conjunto de Instruções', 'Pipeline', 'Hierarquia de Memória', 'Entrada/Saída'],
  SE: ['Periféricos e Temporizadores', 'Interrupções', 'Comunicação Série', 'GPIO e ADC', 'RTOS Básico']
}

const chaptersForDiscipline = computed(() => chapterMap[selectedDiscipline.value] || [])

// Mock de exercícios gerados pela IA — agora com tipo, solução e explicação
const mockGenerated = {
  multipleChoice: [
    { title: 'Identifica a tabela de verdade do Flip-Flop JK quando J=1 e K=1.', options: ['Mantém estado', 'Reset (0)', 'Set (1)', 'Toggle (Inverte)'], correct: 3, solution: 'Toggle (Inverte)', explanation: 'Quando J=K=1, o FF-JK inverte o seu estado atual.' },
    { title: 'Qual a saída de um contador síncrono de 3 bits após 5 pulsos de clock?', options: ['101', '110', '100', '011'], correct: 0, solution: '101', explanation: 'Contando de 000, após 5 pulsos: 001, 010, 011, 100, 101.' },
    { title: 'Qual a função do sinal Clear (CLR) num flip-flop?', options: ['Forçar Q=1', 'Forçar Q=0', 'Inverter Q', 'Desativar o clock'], correct: 1, solution: 'Forçar Q=0', explanation: 'Clear (CLR) força assíncronamente a saída Q para 0.' },
  ],
  trueFalse: [
    { title: 'Um flip-flop D armazena o valor da entrada na transição do clock.', options: ['Verdadeiro', 'Falso'], correct: 0, solution: 'Verdadeiro', explanation: 'O FF-D captura D na edge do clock.' },
    { title: 'Um MUX 8:1 precisa de 4 linhas de seleção.', options: ['Verdadeiro', 'Falso'], correct: 1, solution: 'Falso', explanation: 'Log₂(8) = 3 linhas de seleção.' },
    { title: 'O modelo de Mealy depende apenas do estado atual.', options: ['Verdadeiro', 'Falso'], correct: 1, solution: 'Falso', explanation: 'Mealy depende do estado E das entradas; Moore depende apenas do estado.' },
  ],
  written: [
    { title: 'Escreve a expressão simplificada de F = AB + AB\'.', options: [], correct: null, correctAnswer: 'A', solution: 'A', explanation: 'AB + AB\' = A(B+B\') = A·1 = A.' },
    { title: 'Indica o nome do circuito que seleciona uma de várias entradas.', options: [], correct: null, correctAnswer: 'multiplexador', solution: 'Multiplexador', explanation: 'O MUX seleciona uma entrada com base nas linhas de seleção.' },
  ],
  fillBlank: [
    { title: 'O pipeline clássico MIPS tem ___ estágios.', options: [], correct: null, correctAnswer: '5', solution: '5', explanation: 'IF, ID, EX, MEM, WB.' },
    { title: 'O complemento para 2 inverte os bits e soma ___.', options: [], correct: null, correctAnswer: '1', solution: '1', explanation: 'Complemento para 2 = inverter bits + 1.' },
  ],
}

const generate = () => {
  loading.value = true
  setTimeout(() => {
    const pool = mockGenerated[selectedType.value] || mockGenerated.multipleChoice
    const count = Math.min(quantity.value, pool.length)
    for (let i = 0; i < count; i++) {
      const mock = pool[i % pool.length]
      generatedExercises.value.push({
        id: Date.now() + i,
        title: mock.title,
        type: selectedType.value,
        options: mock.options ? [...mock.options] : [],
        correct: mock.correct,
        correctAnswer: mock.correctAnswer || null,
        solution: mock.solution || '',
        explanation: mock.explanation || '',
        discipline: selectedDiscipline.value,
        chapter: selectedChapter.value,
        difficulty: selectedDifficulty.value,
        showRefine: false,
        refinePrompt: ''
      })
    }
    loading.value = false
  }, 2000)
}

const regenerateOne = (index) => {
  const ex = generatedExercises.value[index]
  const pool = mockGenerated[ex.type] || mockGenerated.multipleChoice
  const newMock = pool[Math.floor(Math.random() * pool.length)]
  ex.title = newMock.title
  ex.options = newMock.options ? [...newMock.options] : []
  ex.correct = newMock.correct
  ex.correctAnswer = newMock.correctAnswer || null
  ex.solution = newMock.solution || ''
  ex.explanation = newMock.explanation || ''
  ex.showRefine = false
  ex.refinePrompt = ''
}

const removeGenerated = (index) => {
  generatedExercises.value.splice(index, 1)
}

const publishOne = (index) => {
  const ex = generatedExercises.value[index]
  exerciseStore.addExercise({
    title: ex.title,
    chapter: ex.chapter,
    discipline: ex.discipline,
    difficulty: ex.difficulty,
    type: ex.type,
    options: ex.options,
    correct: ex.correct,
    correctAnswer: ex.correctAnswer,
    solution: ex.solution,
    explanation: ex.explanation,
    published: true
  })
  generatedExercises.value.splice(index, 1)
}

const publishAll = () => {
  for (const ex of generatedExercises.value) {
    exerciseStore.addExercise({
      title: ex.title,
      chapter: ex.chapter,
      discipline: ex.discipline,
      difficulty: ex.difficulty,
      type: ex.type,
      options: ex.options,
      correct: ex.correct,
      correctAnswer: ex.correctAnswer,
      solution: ex.solution,
      explanation: ex.explanation,
      published: true
    })
  }
  generatedExercises.value = []
}
</script>