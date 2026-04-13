<template>
  <div class="space-y-8">
    <!-- Sem Disciplinas -->
    <div v-if="!authStore.hasCourseUnits" class="space-y-8">
      <div>
        <p class="text-brand font-bold text-sm uppercase tracking-widest mb-1">
          Acesso Restrito
        </p>
        <h3 class="text-3xl font-bold">Nenhuma Disciplina Atribuída</h3>
        <p class="text-text-secondary mt-1">
          Ainda não tem unidades curriculares associadas à sua conta.
        </p>
      </div>
      <div class="bg-surface rounded-card border border-white/5 p-8 max-w-lg">
        <div class="flex items-center gap-4 mb-6">
          <div
            class="w-12 h-12 rounded-full bg-warning/10 flex items-center justify-center"
          >
            <i class="pi pi-exclamation-circle text-warning text-xl"></i>
          </div>
          <div>
            <p class="font-bold">Solicitar Acesso a Disciplinas</p>
            <p class="text-text-secondary text-sm">
              Contacte o administrador da plataforma.
            </p>
          </div>
        </div>
        <router-link
          to="/professor/requests"
          class="inline-flex items-center gap-2 px-6 py-3 bg-brand text-white rounded-btn hover:bg-brand/80 transition-all font-semibold"
        >
          <i class="pi pi-envelope"></i> Enviar Pedido ao Admin
        </router-link>
      </div>
    </div>

    <!-- Conteúdo Principal -->
    <template v-else>
      <div class="flex justify-between items-end">
        <div>
          <p
            class="text-brand font-bold text-sm uppercase tracking-widest mb-1"
          >
            Inteligência Artificial
          </p>
          <h3 class="text-3xl font-bold">Gerador de Perguntas com IA</h3>
          <p class="text-text-secondary mt-1">
            Selecione um ficheiro indexado, configure os parâmetros e escreva o
            prompt.
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

      <div
        v-if="generateError"
        class="bg-error/10 border border-error/30 text-error px-4 py-3 rounded-card text-sm flex items-center gap-2"
      >
        <i class="pi pi-exclamation-triangle"></i>{{ generateError }}
      </div>

      <div class="grid grid-cols-12 gap-6">
        <!-- Sidebar -->
        <aside
          class="col-span-4 space-y-5"
          :class="{ 'opacity-50 pointer-events-none': loading }"
        >
          <section
            class="bg-surface p-6 rounded-card border border-white/5 space-y-4"
          >
            <h4 class="font-bold">Contexto da Geração</h4>

            <!-- Disciplina -->
            <div>
              <label
                class="text-xs font-bold text-text-secondary uppercase tracking-widest"
                >Disciplina</label
              >
              <select
                v-model="form.discipline"
                class="w-full bg-background mt-2 p-3 rounded-btn border border-white/10 outline-none focus:border-brand text-sm"
              >
                <option
                  v-for="uc in authStore.user?.course_units || []"
                  :key="uc.id"
                  :value="uc.id"
                >
                  {{ uc.name }}
                </option>
              </select>
            </div>

            <!-- Ficheiro -->
            <div>
              <label
                class="text-xs font-bold text-text-secondary uppercase tracking-widest"
                >Ficheiro PDF</label
              >
              <select
                v-model="form.filename"
                class="w-full bg-background mt-2 p-3 rounded-btn border border-white/10 outline-none focus:border-brand text-sm"
                :disabled="filesForDiscipline.length === 0"
              >
                <option value="">-- Seleciona um ficheiro --</option>
                <option
                  v-for="doc in filesForDiscipline"
                  :key="doc.id_material"
                  :value="doc.id_material"
                >
                  {{ doc.name }}
                </option>
              </select>
              <p
                v-if="filesForDiscipline.length === 0 && form.discipline"
                class="text-xs text-warning mt-2 flex items-center gap-1"
              >
                <i class="pi pi-exclamation-triangle"></i> Nenhum ficheiro
                indexado. Carrega PDFs em "Documentos".
              </p>
            </div>

            <!-- Tópico -->
            <div>
              <label
                class="text-xs font-bold text-text-secondary uppercase tracking-widest"
                >Tópico</label
              >
              <select
                v-model="form.topic"
                class="w-full bg-background mt-2 p-3 rounded-btn border border-white/10 outline-none focus:border-brand text-sm"
                :disabled="topicsForDiscipline.length === 0"
              >
                <option value="">-- Seleciona um tópico --</option>
                <option v-for="t in topicsForDiscipline" :key="t" :value="t">
                  {{ t }}
                </option>
              </select>
            </div>

            <!-- Tipo de Pergunta -->
            <div>
              <label
                class="text-xs font-bold text-text-secondary uppercase tracking-widest"
                >Tipo de Pergunta</label
              >
              <div class="grid grid-cols-2 gap-2 mt-2">
                <button
                  v-for="type in questionTypes"
                  :key="type.value"
                  @click="form.type = type.value"
                  :class="
                    form.type === type.value
                      ? 'bg-brand text-white'
                      : 'bg-background border border-white/10 text-text-secondary'
                  "
                  class="px-3 py-2 rounded-chip text-xs font-bold transition-all"
                >
                  {{ type.label }}
                </button>
              </div>
            </div>

            <!-- Quantidade -->
            <div>
              <label
                class="text-xs font-bold text-text-secondary uppercase tracking-widest"
                >Quantidade</label
              >
              <input
                v-model.number="form.quantity"
                type="number"
                min="1"
                max="20"
                class="w-full bg-background mt-2 p-3 rounded-btn border border-white/10 outline-none focus:border-brand text-sm"
              />
            </div>

            <!-- Dificuldade -->
            <div>
              <label
                class="text-xs font-bold text-text-secondary uppercase tracking-widest"
                >Dificuldade</label
              >
              <div class="flex gap-2 mt-2">
                <button
                  v-for="d in ['Fácil', 'Médio', 'Difícil']"
                  :key="d"
                  @click="form.difficulty = d"
                  :class="
                    form.difficulty === d
                      ? 'bg-brand text-white'
                      : 'bg-background border border-white/10 text-text-secondary'
                  "
                  class="px-4 py-2 rounded-chip text-xs font-bold transition-all flex-1"
                >
                  {{ d }}
                </button>
              </div>
            </div>
          </section>

          <div
            v-if="generatedExercises.length > 0"
            class="bg-info/10 border border-info/30 p-4 rounded-btn text-sm text-text-secondary"
          >
            <i class="pi pi-info-circle text-info mr-2"></i>
            <strong
              >{{ generatedExercises.length }} exercício(s) em rascunho.</strong
            >
            Edita e clica "Publicar" para confirmar.
          </div>
        </aside>

        <!-- Área principal -->
        <section class="col-span-8 space-y-5">
          <!-- Prompt -->
          <article
            class="bg-surface p-6 rounded-card border border-white/5"
            :class="{ 'opacity-50 pointer-events-none': loading }"
          >
            <h4 class="font-bold mb-4">Prompt para a LLM</h4>
            <textarea
              v-model="form.prompt"
              rows="6"
              placeholder="Ex: Cria perguntas sobre hazards de controlo em pipeline MIPS..."
              class="w-full bg-background p-4 rounded-btn border border-white/10 outline-none focus:border-brand text-sm resize-none"
            ></textarea>
            <div class="flex justify-between items-center mt-4">
              <p class="text-xs text-text-secondary">
                O prompt será utilizado para encontrar contexto relevante no
                ficheiro selecionado.
              </p>
              <button
                @click="generate"
                :disabled="
                  loading ||
                  !form.discipline ||
                  !form.filename ||
                  !form.prompt.trim()
                "
                class="bg-brand px-6 py-3 rounded-btn font-bold flex items-center gap-2 hover:brightness-110 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <i v-if="loading" class="pi pi-spin pi-spinner"></i>
                <i v-else class="pi pi-send"></i>
                {{ loading ? 'A gerar perguntas...' : 'Enviar para o LLM' }}
              </button>
            </div>
          </article>

          <!-- Exercícios gerados -->
          <article
            class="bg-surface p-6 rounded-card border border-white/5 relative"
          >
            <div
              v-if="loading"
              class="absolute inset-0 bg-black/40 backdrop-blur-sm z-20 flex flex-col items-center justify-center gap-3 rounded-card"
            >
              <i class="pi pi-spin pi-spinner text-brand text-3xl"></i>
              <p class="text-sm text-text-secondary">A gerar perguntas...</p>
            </div>

            <div class="flex items-center justify-between mb-4">
              <h4 class="font-bold">Exercícios Gerados</h4>
              <span class="text-xs text-text-secondary"
                >{{ generatedExercises.length }} item(ns)</span
              >
            </div>

            <div
              v-if="generatedExercises.length === 0 && !loading"
              class="border border-dashed border-white/10 rounded-btn p-12 text-center text-text-secondary text-sm"
            >
              <i class="pi pi-bolt text-4xl text-brand/30 mb-4 block"></i>
              Ainda não existem exercícios. Seleciona um ficheiro, configura os
              parâmetros e envia o prompt.
            </div>

            <div class="space-y-4">
              <div
                v-for="(ex, index) in generatedExercises"
                :key="ex.id"
                class="bg-background border border-white/10 rounded-btn p-5 relative group"
              >
                <div
                  class="absolute right-4 top-4 flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity"
                >
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

                <div class="flex items-center gap-2 mb-3">
                  <span
                    class="bg-brand/10 text-brand text-[10px] font-bold uppercase tracking-widest px-3 py-1 rounded-chip"
                    >{{ ex.topic }}</span
                  >
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

                <textarea
                  v-model="ex.question"
                  rows="2"
                  class="bg-transparent text-base font-bold w-full border-b border-white/5 focus:border-brand outline-none pb-2 mb-4 resize-none"
                />

                <!-- Opções — funciona para ambos os tipos -->
                <div
                  v-if="ex.options && ex.options.length > 0"
                  class="grid grid-cols-2 gap-3"
                >
                  <div
                    v-for="(opt, oIdx) in ex.options"
                    :key="oIdx"
                    class="flex items-center gap-3 p-3 rounded-btn border transition-all cursor-pointer"
                    :class="
                      ex.correctIndex === oIdx
                        ? 'bg-success/10 border-success/30'
                        : 'bg-surface border-white/5 hover:border-white/10'
                    "
                    @click="ex.correctIndex = oIdx"
                  >
                    <div
                      class="w-5 h-5 rounded-full border-2 flex items-center justify-center shrink-0"
                      :class="
                        ex.correctIndex === oIdx
                          ? 'border-success bg-success'
                          : 'border-white/20'
                      "
                    >
                      <i
                        v-if="ex.correctIndex === oIdx"
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

                <div class="mt-4">
                  <label
                    class="text-xs font-bold text-brand uppercase tracking-widest"
                    >Explicação</label
                  >
                  <textarea
                    v-model="ex.explanation"
                    rows="2"
                    class="w-full bg-surface mt-1 p-3 rounded-btn border border-white/10 outline-none focus:border-brand text-sm resize-none"
                    placeholder="Explicação detalhada para o aluno..."
                  ></textarea>
                </div>

                <div class="flex justify-end mt-4">
                  <button
                    @click="publishOne(index)"
                    class="text-xs bg-success/10 border border-success/30 text-success px-4 py-2 rounded-chip font-bold hover:bg-success/20 transition-all"
                  >
                    <i class="pi pi-cloud-upload mr-1"></i> Publicar
                  </button>
                </div>
              </div>
            </div>
          </article>
        </section>
      </div>
    </template>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted, reactive } from 'vue';
import { useAuthStore } from '../../../stores/authStore';
import { useQuestionLabStore } from '../stores/questionLabStore';
import { http } from '../../../services/http';

const authStore = useAuthStore();
const questionLabStore = useQuestionLabStore();

onMounted(async () => {
  await questionLabStore.loadDocuments();
});

const TOPICS_UC = {
  40332: [
    'Introdução aos sistemas digitais',
    'Representação e codificação de informação',
    'Álgebra de Boole',
    'Lógica combinatória elementar',
    'Blocos combinatórios',
    'Circuitos aritméticos',
    'Sistemas sequenciais',
    'Estratégias de análise de circuitos sequenciais',
    'Blocos sequenciais fundamentais',
    'Síntese de máquinas de estado',
  ],
  40333: [
    'Introdução às FPGAs, ferramentas e kits de desenvolvimento',
    'Modelação em VHDL: Componentes combinatórios e aritméticos',
    'Modelação em VHDL: Circuitos sequenciais, registos e memórias',
    'Máquinas de Estados Finitos (FSM) em VHDL',
    'Testbenches e estratégias de depuração de circuitos',
    'Precauções de projeto: Reset, sincronização e restrições temporais',
  ],
  42545: [
    'Organização funcional e programação em assembly',
    'Tradução de linguagens de alto nível e assemblagem',
    'Aritmética de vírgula fixa e flutuante',
    'Estrutura interna do processador e etapas de execução',
    'Arquitecturas de processadores com pipeline',
  ],
  42548: [
    'Organização básica do sistema de entradas/saídas',
    'Dispositivos periféricos',
    'Organização de barramentos de dados',
    'Interfaces e barramentos paralelos e série',
    'Software para gestão de dispositivos de E/S',
    'Sistema de memória e análise de memória cache',
  ],
  42454: ['Clubes do Ronaldo', 'Vida do Ronaldo', 'Idade do Ronaldo'],
};

const form = reactive({
  discipline: null,
  filename: '',
  topic: '',
  type: 'Escolha Múltipla',
  quantity: 5,
  difficulty: 'Médio',
  prompt: '',
});

const loading = ref(false);
const generateError = ref(null);
const generatedExercises = ref([]);

const questionTypes = [
  { value: 'Escolha Múltipla', label: 'Escolha Múltipla' },
  { value: 'True/False', label: 'V/F' },
];

const typeLabels = {
  'Escolha Múltipla': 'Escolha Múltipla',
  'True/False': 'V/F',
};
const typeLabel = (type) => typeLabels[type] || 'Escolha Múltipla';
const typeClass = (type) =>
  ({
    'Escolha Múltipla': 'bg-brand/10 text-brand',
    'True/False': 'bg-purple-500/10 text-purple-400',
  })[type] || 'bg-brand/10 text-brand';

watch(
  () => authStore.user?.course_units,
  (units) => {
    if (units?.length && form.discipline === null) {
      form.discipline = units[0].id;
    }
  },
  { immediate: true },
);

const topicsForDiscipline = computed(() => {
  if (!form.discipline) return [];
  return TOPICS_UC[form.discipline] || [];
});

const filesForDiscipline = computed(() => {
  if (!form.discipline) return [];
  return questionLabStore.availableDocuments.filter(
    (doc) =>
      Number(doc.id_uc) === Number(form.discipline) && doc.status === 'indexed',
  );
});

watch(
  () => form.discipline,
  () => {
    form.filename = '';
    form.topic = '';
    generateError.value = null;
  },
);

function correctLetterToIndex(correct, options) {
  if (!correct || !options) return 0;
  if (typeof correct === 'number') return correct;
  const letter = correct
    .toString()
    .trim()
    .toUpperCase()
    .replace(/[^A-D]/, '');
  const idx = ['A', 'B', 'C', 'D'].indexOf(letter);
  return idx !== -1 ? idx : 0;
}

async function generate() {
  if (
    !form.discipline ||
    !form.filename ||
    !form.prompt.trim() ||
    loading.value
  )
    return;

  loading.value = true;
  generateError.value = null;
  generatedExercises.value = [];

  try {
    const { data: result } = await http.post(
      '/api/v1/professors/generate-questions',
      {
        id_uc: form.discipline,
        filename: form.filename,
        topic: form.topic ? `${form.topic} — ${form.prompt}` : form.prompt,
        n_perguntas: form.quantity,
        difficulty:
          form.difficulty === 'Fácil'
            ? 'easy'
            : form.difficulty === 'Médio'
              ? 'medium'
              : 'hard',
        question_type: form.type,
      },
    );

    if (result.questions && Array.isArray(result.questions)) {
      generatedExercises.value = result.questions.map((q) => {
        // Limpar prefixo "A) " das opções
        const rawOptions = q.solution?.options || [];
        const options = rawOptions.map((o) => o.replace(/^[A-D]\)\s*/, ''));
        const correctRaw = q.solution?.correct ?? q.correct;
        return {
          id: q.id_exercise,
          question: q.question || '',
          type: form.type,
          options,
          correctIndex: correctLetterToIndex(correctRaw, options),
          explanation: q.explanation || '',
          difficulty: form.difficulty,
          topic: q.topic_name || form.topic || form.prompt.slice(0, 40),
          published: q.published || false,
        };
      });
    }

    if (generatedExercises.value.length === 0) {
      generateError.value =
        'Não foram geradas perguntas. Tenta com um prompt diferente ou verifica se o ficheiro tem conteúdo relevante.';
    }
  } catch (error) {
    console.error('Erro ao gerar exercícios:', error);
    generateError.value =
      error.response?.data?.detail ||
      'Erro ao gerar exercícios. Tenta novamente.';
  } finally {
    loading.value = false;
  }
}

function removeGenerated(index) {
  generatedExercises.value.splice(index, 1);
}

async function publishOne(index) {
  const exercise = generatedExercises.value[index];
  if (!exercise) return;
  try {
    await http.patch(`/api/v1/professors/exercises/${exercise.id}`, {
      published: true,
    });
    generatedExercises.value.splice(index, 1);
  } catch (error) {
    console.error('Erro ao publicar exercício:', error);
    alert(
      'Erro ao publicar: ' + (error.response?.data?.detail || error.message),
    );
  }
}

async function publishAll() {
  if (generatedExercises.value.length === 0) return;
  try {
    await Promise.all(
      generatedExercises.value.map((ex) =>
        http.patch(`/api/v1/professors/exercises/${ex.id}`, {
          published: true,
        }),
      ),
    );
    generatedExercises.value = [];
  } catch (error) {
    console.error('Erro ao publicar exercícios:', error);
    alert('Erro ao publicar alguns exercícios.');
  }
}
</script>
