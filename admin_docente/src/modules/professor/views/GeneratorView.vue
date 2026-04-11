<template>
  <div class="space-y-8">
    <div class="flex justify-between items-end">
      <div>
        <p class="text-brand font-bold text-sm uppercase tracking-widest mb-1">
          Inteligência Artificial
        </p>
        <h3 class="text-3xl font-bold">Laboratório de Conteúdo IA</h3>
        <p class="text-text-secondary mt-1">
          Gere exercícios com IA a partir dos PDFs da UC. Edite, refine e
          publique.
        </p>
      </div>
      <button
        @click="publishAll"
        :disabled="generatedExercises.length === 0"
        class="bg-success text-black px-6 py-3 rounded-btn font-bold hover:brightness-110 transition-all flex items-center gap-2 disabled:opacity-30 disabled:cursor-not-allowed"
      >
        <i class="pi pi-cloud-upload"></i> Publicar Todos
      </button>
    </div>

    <!-- Painel de configuração -->
    <div class="grid grid-cols-12 gap-6">
      <!-- Sidebar de geração -->
      <div class="col-span-4 space-y-4">
        <!-- Sem disciplinas -->
        <div
          v-if="userDisciplines.length === 0"
          class="bg-surface p-6 rounded-card border border-white/5"
        >
          <div class="flex items-center gap-4 mb-4">
            <div class="w-12 h-12 rounded-full bg-warning/10 flex items-center justify-center">
              <i class="pi pi-lock text-warning text-lg"></i>
            </div>
            <div>
              <p class="font-bold">Sem Acesso a Disciplinas</p>
              <p class="text-text-secondary text-sm">Solicita acesso no painel de Pedidos.</p>
            </div>
          </div>
          <router-link to="/professor/requests" class="inline-flex items-center gap-2 px-4 py-2 bg-brand text-white rounded-btn text-sm font-bold hover:brightness-110">
            <i class="pi pi-envelope"></i> Solicitar Acesso
          </router-link>
        </div>

        <template v-else>
          <label class="text-xs font-bold text-brand uppercase tracking-widest"
            >Disciplina</label
          >
          <select
            v-model="selectedDiscipline"
            class="w-full bg-background mt-2 p-3 rounded-btn border border-white/10 outline-none focus:border-brand text-sm"
          >
            <option v-for="uc in userDisciplines" :key="uc.id" :value="uc.id">
              {{ uc.name }}
            </option>
          </select>

          <label
            class="text-xs font-bold text-brand uppercase tracking-widest mt-4 block"
            >Capítulo / Tópico</label
          >
          <select
            v-model="selectedChapter"
            class="w-full bg-background mt-2 p-3 rounded-btn border border-white/10 outline-none focus:border-brand text-sm"
          >
            <option value="">-- Seleciona um tópico --</option>
            <option v-for="ch in chaptersForDiscipline" :key="ch" :value="ch">
              {{ ch }}
            </option>
          </select>
          <p
            v-if="chaptersForDiscipline.length === 0"
            class="text-xs text-text-secondary mt-2"
          >
            Nenhum tópico disponível. Indexa documentos primeiro.
          </p>

          <label
            class="text-xs font-bold text-text-secondary uppercase tracking-widest mt-4 block"
            >Dificuldade</label
          >
          <div class="flex gap-2 mt-2">
            <button
              v-for="d in ['Fácil', 'Médio', 'Difícil']"
              :key="d"
              @click="selectedDifficulty = d"
              :class="
                selectedDifficulty === d
                  ? 'bg-brand text-white'
                  : 'bg-background text-text-secondary border border-white/10'
              "
              class="px-4 py-2 rounded-chip text-xs font-bold transition-all"
            >
              {{ d }}
            </button>
          </div>

          <label
            class="text-xs font-bold text-text-secondary uppercase tracking-widest mt-4 block"
            >Tipo de Exercício</label
          >
          <div class="flex flex-wrap gap-2 mt-2">
            <button
              v-for="t in exerciseTypes"
              :key="t.value"
              @click="selectedType = t.value"
              :class="
                selectedType === t.value
                  ? 'bg-brand text-white'
                  : 'bg-background text-text-secondary border border-white/10'
              "
              class="px-4 py-2 rounded-chip text-xs font-bold transition-all"
            >
              {{ t.label }}
            </button>
          </div>

          <label
            class="text-xs font-bold text-text-secondary uppercase tracking-widest mt-4 block"
            >Quantidade</label
          >
          <input
            v-model.number="quantity"
            type="number"
            min="1"
            max="20"
            class="w-full bg-background mt-2 p-3 rounded-btn border border-white/10 outline-none focus:border-brand text-sm"
          />
        </div>

        <div class="bg-surface p-6 rounded-card border border-white/5">
          <label class="text-xs font-bold text-brand uppercase tracking-widest"
            >Instruções para a IA</label
          >
          <textarea
            v-model="customPrompt"
            rows="4"
            placeholder="Ex: Foca em diagramas de tempo. Evita perguntas sobre conversão hexadecimal..."
            class="w-full bg-background mt-2 p-4 rounded-btn border border-white/10 outline-none focus:border-brand text-sm resize-none"
          ></textarea>
        </div>

        <button
          @click="generate"
          :disabled="loading || !selectedDiscipline"
          class="w-full bg-brand py-4 rounded-btn font-bold flex items-center justify-center gap-2 hover:brightness-110 transition-all disabled:opacity-50"
        >
          <i v-if="loading" class="pi pi-spin pi-spinner"></i>
          <i v-else class="pi pi-bolt"></i>
          {{ loading ? 'A processar RAG...' : 'Gerar Exercícios' }}
        </button>
        </template>
      </div>

      <!-- Exercícios gerados -->
      <div class="col-span-8 space-y-4">
        <div
          v-if="generatedExercises.length === 0 && !loading"
          class="bg-surface rounded-card border border-white/5 border-dashed p-12 text-center"
        >
          <i class="pi pi-bolt text-4xl text-brand/30 mb-4 block"></i>
          <p class="text-text-secondary">
            Configure os parâmetros e clique em
            <strong class="text-brand">Gerar Exercícios</strong> para começar.
          </p>
          <p class="text-text-secondary text-xs mt-2">
            O motor RAG irá usar os PDFs ingeridos para criar exercícios
            contextualizados.
          </p>
        </div>

        <div
          v-for="(ex, index) in generatedExercises"
          :key="ex.id"
          class="bg-surface p-6 rounded-card border border-white/5 relative group"
        >
          <!-- Ações hover -->
          <div
            class="absolute right-4 top-4 flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity"
          >
            <button
              @click="regenerateOne(index)"
              class="text-text-secondary hover:text-brand"
              title="Regenerar esta pergunta"
            >
              <i class="pi pi-refresh"></i>
            </button>
            <button
              @click="publishOne(index)"
              class="text-text-secondary hover:text-success"
              title="Publicar"
            >
              <i class="pi pi-cloud-upload"></i>
            </button>
            <button
              @click="removeGenerated(index)"
              class="text-text-secondary hover:text-error"
              title="Remover"
            >
              <i class="pi pi-trash"></i>
            </button>
          </div>

          <!-- Badge -->
          <div class="flex items-center gap-2 mb-3">
            <span
              class="bg-brand/10 text-brand text-[10px] font-bold uppercase tracking-widest px-3 py-1 rounded-chip"
            >
              {{ ex.discipline }} — {{ ex.chapter }}
            </span>
            <span
              class="text-[10px] font-bold uppercase tracking-widest px-3 py-1 rounded-chip"
              :class="
                ex.difficulty === 'Fácil'
                  ? 'bg-success/10 text-success'
                  : ex.difficulty === 'Médio'
                    ? 'bg-warning/10 text-warning'
                    : 'bg-error/10 text-error'
              "
            >
              {{ ex.difficulty }}
            </span>
            <span
              class="text-[10px] font-bold uppercase tracking-widest px-3 py-1 rounded-chip"
              :class="typeClass(ex.type)"
            >
              {{ typeLabel(ex.type) }}
            </span>
          </div>

          <!-- Título editável -->
          <input
            v-model="ex.title"
            class="bg-transparent text-lg font-bold w-full border-b border-white/5 focus:border-brand outline-none pb-2 mb-4"
          />

          <!-- Opções editáveis (para MC e V/F) -->
          <div
            v-if="ex.type === 'multipleChoice' || ex.type === 'trueFalse'"
            class="grid grid-cols-2 gap-3"
          >
            <div
              v-for="(opt, oIdx) in ex.options"
              :key="oIdx"
              class="flex items-center gap-3 p-3 rounded-btn border transition-all cursor-pointer"
              :class="
                oIdx === ex.correct
                  ? 'bg-success/10 border-success/30'
                  : 'bg-background border-white/5 hover:border-white/10'
              "
              @click="ex.correct = oIdx"
            >
              <div
                class="w-5 h-5 rounded-full border-2 flex items-center justify-center shrink-0"
                :class="
                  oIdx === ex.correct
                    ? 'border-success bg-success'
                    : 'border-white/20'
                "
              >
                <i
                  v-if="oIdx === ex.correct"
                  class="pi pi-check text-[10px] text-black"
                ></i>
              </div>
              <input
                v-model="ex.options[oIdx]"
                class="bg-transparent text-sm w-full outline-none"
                @click.stop
              />
            </div>
          </div>

          <!-- Resposta correta (para escrita e fill blank) -->
          <div
            v-if="ex.type === 'written' || ex.type === 'fillBlank'"
            class="mb-3"
          >
            <label
              class="text-xs font-bold text-success uppercase tracking-widest"
              >Resposta Correta</label
            >
            <input
              v-model="ex.correctAnswer"
              class="w-full bg-background mt-1 p-3 rounded-btn border border-success/30 outline-none focus:border-success text-sm"
            />
          </div>

          <!-- Solução e explicação -->
          <div class="mt-4 space-y-3">
            <div>
              <label
                class="text-xs font-bold text-brand uppercase tracking-widest"
                >Solução</label
              >
              <input
                v-model="ex.solution"
                class="w-full bg-background mt-1 p-3 rounded-btn border border-white/10 outline-none focus:border-brand text-sm"
                placeholder="Resposta correta resumida..."
              />
            </div>
            <div>
              <label
                class="text-xs font-bold text-brand uppercase tracking-widest"
                >Explicação</label
              >
              <textarea
                v-model="ex.explanation"
                rows="2"
                class="w-full bg-background mt-1 p-3 rounded-btn border border-white/10 outline-none focus:border-brand text-sm resize-none"
                placeholder="Explicação detalhada para o aluno..."
              ></textarea>
            </div>
          </div>

          <!-- Campo de instrução para regenerar individual -->
          <div v-if="ex.showRefine" class="mt-4 flex gap-2">
            <input
              v-model="ex.refinePrompt"
              placeholder="Instruções de refinamento... Ex: 'Torna mais difícil' ou 'Reformula sem tabelas de verdade'"
              class="flex-1 bg-background p-3 rounded-btn border border-white/10 outline-none focus:border-brand text-sm"
            />
            <button
              @click="regenerateOne(index)"
              class="bg-brand px-4 rounded-btn text-sm font-bold"
            >
              <i class="pi pi-refresh"></i>
            </button>
          </div>
          <button
            @click="ex.showRefine = !ex.showRefine"
            class="text-text-secondary text-xs mt-3 hover:text-brand transition-colors flex items-center gap-1"
          >
            <i class="pi pi-pencil text-[10px]"></i>
            {{ ex.showRefine ? 'Esconder refinamento' : 'Refinar com IA' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</div>
</template>

<script setup>
import { ref, computed, watch } from 'vue';
import { useAuthStore } from '../../../stores/authStore';
import { useExerciseStore } from '../stores/exerciseStore';
import { useQuestionLabStore } from '../stores/questionLabStore';
import { http } from '../../../services/http';

const authStore = useAuthStore();
const exerciseStore = useExerciseStore();
const questionLabStore = useQuestionLabStore();

// Disciplinas que o professor tem atribuídas
const userDisciplines = computed(() => authStore.user?.course_units || []);

const selectedDiscipline = ref(null);
const selectedChapter = ref('');
const selectedDifficulty = ref('Médio');
const selectedType = ref('multipleChoice');
const quantity = ref(5);
const customPrompt = ref('');
const loading = ref(false);
const generatedExercises = ref([]);

// Inicializar disciplina selecionada ao mount
watch(
  userDisciplines,
  (newDisciplines) => {
    if (newDisciplines.length > 0 && !selectedDiscipline.value) {
      selectedDiscipline.value = newDisciplines[0].id;
    }
  },
  { immediate: true },
);

const exerciseTypes = [
  { value: 'multipleChoice', label: 'Escolha Múltipla' },
  { value: 'trueFalse', label: 'V/F' },
];

const typeLabels = { multipleChoice: 'Escolha Múltipla', trueFalse: 'V/F' };
const typeLabel = (type) => typeLabels[type] || 'Escolha Múltipla';
const typeClass = (type) =>
  ({
    multipleChoice: 'bg-brand/10 text-brand',
    trueFalse: 'bg-purple-500/10 text-purple-400',
  })[type] || 'bg-brand/10 text-brand';

// Tópicos dinamicamente da BD para a disciplina selecionada
const chaptersForDiscipline = computed(() => {
  if (!selectedDiscipline.value) return [];

  const topics = new Set();

  // Obter tópicos dos exercícios existentes
  exerciseStore.exercises
    .filter((ex) => ex.id_uc === selectedDiscipline.value)
    .forEach((ex) => {
      if (ex.topic_name) topics.add(ex.topic_name);
    });

  // Se não há exercícios, obter dos documentos
  if (topics.size === 0) {
    questionLabStore.availableDocuments
      .filter((doc) => doc.id_uc === selectedDiscipline.value && doc.chapter)
      .forEach((doc) => topics.add(doc.chapter));
  }

  return Array.from(topics).sort();
});

// Ao mudar disciplina, resetar capítulo
watch(selectedDiscipline, () => {
  selectedChapter.value = '';
  if (chaptersForDiscipline.value.length > 0) {
    selectedChapter.value = chaptersForDiscipline.value[0];
  }
});

// Gerar exercícios usando API real
const generate = async () => {
  if (!selectedDiscipline.value || loading.value) return;

  loading.value = true;
  generatedExercises.value = [];

  try {
    const { data: result } = await http.post(
      '/api/v1/professors/generate-questions',
      {
        id_uc: selectedDiscipline.value,
        filename: selectedChapter.value || 'geral',
        topic: selectedChapter.value || 'Geral',
        n_perguntas: quantity.value,
        difficulty: selectedDifficulty.value.toLowerCase(),
        question_type:
          selectedType.value === 'multipleChoice' ? 'Escolha Múltipla' : 'V/F',
      },
    );

    // Exercícios já foram salvos na BD pelo backend
    // Apenas mostrar para edição antes de "publicar"
    if (result.questions && Array.isArray(result.questions)) {
      generatedExercises.value = result.questions.map((q) => ({
        id: q.id_exercise,
        title: q.question || q.title,
        type: selectedType.value,
        options: q.options || [],
        correct: q.correct !== undefined ? q.correct : null,
        solution: q.solution || '',
        explanation: q.explanation || '',
        difficulty: selectedDifficulty.value,
        chapter: selectedChapter.value,
      }));
    }
  } catch (error) {
    console.error('Erro ao gerar exercícios:', error);
  } finally {
    loading.value = false;
  }
};

const removeGenerated = (index) => {
  generatedExercises.value.splice(index, 1);
};

const publishOne = (index) => {
  // Exercício já está na BD, apenas remover da lista local
  generatedExercises.value.splice(index, 1);
};

const publishAll = () => {
  // Exercícios já foram publicados ao serem gerados via API
  generatedExercises.value = [];
};
</script>
