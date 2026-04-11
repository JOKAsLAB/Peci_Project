<template>
  <div class="space-y-8">
    <!-- Sem Disciplinas Atribuídas -->
    <div v-if="!authStore.hasCourseUnits" class="space-y-8">
      <div>
        <p class="text-brand font-bold text-sm uppercase tracking-widest mb-1">
          Acesso Restrito
        </p>
        <h3 class="text-3xl font-bold">Nenhuma Disciplina Atribuída</h3>
        <p class="text-text-secondary mt-1">
          Ainda não tem unidades curriculares associadas à sua conta para editar
          conteúdo.
        </p>
      </div>

      <div class="bg-surface rounded-card border border-white/5 p-8">
        <div class="max-w-lg">
          <div class="flex items-center gap-4 mb-6">
            <div
              class="w-12 h-12 rounded-full bg-warning/10 flex items-center justify-center"
            >
              <i class="pi pi-exclamation-circle text-warning text-xl"></i>
            </div>
            <div>
              <p class="font-bold">Solicitar Acesso a Disciplinas</p>
              <p class="text-text-secondary text-sm">
                Contacte o administrador da plataforma para atribuir uma ou mais
                unidades curriculares.
              </p>
            </div>
          </div>

          <router-link
            to="/professor/requests"
            class="inline-flex items-center gap-2 px-6 py-3 bg-brand text-white rounded-btn hover:bg-brand/80 transition-all font-semibold"
          >
            <i class="pi pi-envelope"></i>
            Enviar Pedido ao Admin
          </router-link>
        </div>
      </div>
    </div>

    <!-- Conteúdo Original -->
    <template v-else>
      <div class="space-y-8">
        <div class="flex justify-between items-end">
          <div>
            <p
              class="text-brand font-bold text-sm uppercase tracking-widest mb-1"
            >
              Ferramentas IA
            </p>
            <h3 class="text-3xl font-bold">Criar Perguntas com LLM</h3>
            <p class="text-text-secondary mt-1">
              Selecione documentos indexados, escreva o prompt pedagógico e gere
              um rascunho de perguntas para revisão.
            </p>
          </div>
          <button
            @click="submitPrompt"
            :disabled="questionLabStore.isLoading || !form.prompt.trim()"
            class="bg-brand text-white px-6 py-3 rounded-btn font-bold hover:brightness-110 transition-all flex items-center gap-2 disabled:opacity-40 disabled:cursor-not-allowed"
          >
            <i
              v-if="questionLabStore.isLoading"
              class="pi pi-spin pi-spinner"
            ></i>
            <i v-else class="pi pi-send"></i>
            {{
              questionLabStore.isLoading
                ? 'A gerar inferência...'
                : 'Enviar para o LLM'
            }}
          </button>
        </div>

        <div
          v-if="questionLabStore.error"
          class="bg-error/10 border border-error/30 text-error px-4 py-3 rounded-card text-sm"
        >
          <i class="pi pi-exclamation-triangle mr-2"></i>
          {{ questionLabStore.error }}
        </div>

        <div class="grid grid-cols-12 gap-6">
          <aside
            class="col-span-4 space-y-5"
            :class="{
              'opacity-50 pointer-events-none': questionLabStore.isLoading,
            }"
          >
            <section class="bg-surface p-6 rounded-card border border-white/5">
              <h4 class="font-bold mb-4">Contexto da Geração</h4>

              <div class="space-y-4">
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

                <div>
                  <label
                    class="text-xs font-bold text-text-secondary uppercase tracking-widest"
                    >Dificuldade</label
                  >
                  <div class="flex gap-2 mt-2">
                    <button
                      v-for="difficulty in ['Fácil', 'Médio', 'Difícil']"
                      :key="difficulty"
                      @click="form.difficulty = difficulty"
                      :class="
                        form.difficulty === difficulty
                          ? 'bg-brand text-white'
                          : 'bg-background border border-white/10 text-text-secondary'
                      "
                      class="px-4 py-2 rounded-chip text-xs font-bold transition-all"
                    >
                      {{ difficulty }}
                    </button>
                  </div>
                </div>
              </div>
            </section>

            <section class="bg-surface p-6 rounded-card border border-white/5">
              <div class="flex items-center justify-between mb-4">
                <h4 class="font-bold">Documentação Selecionada</h4>
                <span class="text-xs text-text-secondary">
                  {{ form.documentIds.length }} ficheiro(s)
                </span>
              </div>

              <div class="space-y-2 max-h-72 overflow-y-auto pr-1">
                <label
                  v-for="doc in disciplineDocuments"
                  :key="doc.id"
                  class="flex items-start gap-3 p-3 rounded-btn border transition-all cursor-pointer"
                  :class="
                    form.documentIds.includes(doc.id)
                      ? 'border-brand bg-brand/5'
                      : 'border-white/10 bg-background hover:border-white/20'
                  "
                >
                  <input
                    type="checkbox"
                    :value="doc.id"
                    v-model="form.documentIds"
                    class="mt-1 accent-brand"
                  />
                  <div class="min-w-0">
                    <p class="text-sm font-semibold truncate">{{ doc.name }}</p>
                    <p class="text-xs text-text-secondary">
                      {{ doc.chapter }} ·
                      {{ doc.updatedAt }}
                    </p>
                  </div>
                </label>
              </div>

              <p
                v-if="disciplineDocuments.length === 0"
                class="text-sm text-text-secondary"
              >
                Sem documentos indexados para esta disciplina.
              </p>
            </section>
          </aside>

          <section class="col-span-8 space-y-5">
            <article
              class="bg-surface p-6 rounded-card border border-white/5"
              :class="{
                'opacity-50 pointer-events-none': questionLabStore.isLoading,
              }"
            >
              <h4 class="font-bold mb-4">Prompt para o LLM</h4>
              <textarea
                v-model="form.prompt"
                rows="8"
                placeholder="Ex: Cria 5 perguntas de escolha múltipla sobre hazards de controlo em pipeline MIPS. Inclui distratores plausíveis e explicação curta para cada resposta."
                class="w-full bg-background p-4 rounded-btn border border-white/10 outline-none focus:border-brand text-sm resize-none"
              ></textarea>
            </article>

            <article
              class="bg-surface p-6 rounded-card border border-white/5 relative"
            >
              <div
                v-if="questionLabStore.isLoading"
                class="absolute inset-0 bg-black/40 backdrop-blur-sm z-20 flex items-center justify-center"
              ></div>

              <div class="flex items-center justify-between mb-4">
                <h4 class="font-bold">Rascunhos Gerados</h4>
                <span class="text-xs text-text-secondary">
                  {{ questionLabStore.generatedDrafts.length }} item(ns)
                </span>
              </div>

              <div class="space-y-3">
                <div
                  v-for="draft in questionLabStore.generatedDrafts"
                  :key="draft.id"
                  class="bg-background border border-white/10 rounded-btn p-4"
                  :class="{ 'pointer-events-none': questionLabStore.isLoading }"
                >
                  <div class="flex items-center justify-between gap-3 mb-2">
                    <p class="font-semibold text-sm">{{ draft.title }}</p>
                    <span
                      class="text-[10px] uppercase tracking-widest px-2 py-1 rounded-chip font-bold"
                      :class="
                        draft.status === 'ready'
                          ? 'bg-success/10 text-success border border-success/20'
                          : 'bg-warning/10 text-warning border border-warning/20'
                      "
                    >
                      {{ draft.status === 'ready' ? 'Pronto' : 'Rascunho' }}
                    </span>
                  </div>
                  <p class="text-xs text-text-secondary mb-3">
                    {{ draft.discipline }} · {{ draft.typeLabel }} ·
                    {{ draft.difficulty }} · {{ draft.createdAt }}
                  </p>

                  <div class="flex gap-2">
                    <button
                      v-if="draft.status === 'draft'"
                      @click="markReady(draft.id)"
                      class="text-xs bg-success/10 border border-success/30 text-success px-3 py-1.5 rounded-chip font-bold hover:bg-success/20 transition-all"
                    >
                      Marcar como Pronto
                    </button>
                    <button
                      @click="removeDraft(draft.id)"
                      class="text-xs bg-error/10 border border-error/30 text-error px-3 py-1.5 rounded-chip font-bold hover:bg-error/20 transition-all"
                    >
                      Remover
                    </button>
                  </div>
                </div>

                <div
                  v-if="questionLabStore.generatedDrafts.length === 0"
                  class="border border-dashed border-white/10 rounded-btn p-8 text-center text-text-secondary text-sm"
                >
                  Ainda não existem rascunhos. Envie um prompt para gerar o
                  primeiro bloco de perguntas via LLM.
                </div>
              </div>
            </article>
          </section>
        </div>
      </div>
    </template>
  </div>
</template>

<script setup>
import { computed, reactive, onMounted, watch } from 'vue';
import { useAuthStore } from '../../../stores/authStore';
import { useQuestionLabStore } from '../stores/questionLabStore';

const authStore = useAuthStore();
const questionLabStore = useQuestionLabStore();

onMounted(async () => {
  await questionLabStore.loadDocuments();
});

const questionTypes = [
  { value: 'multipleChoice', label: 'Escolha Múltipla' },
  { value: 'trueFalse', label: 'V/F' },
];

const form = reactive({
  discipline: null,
  type: 'multipleChoice',
  quantity: 5,
  difficulty: 'Médio',
  documentIds: [],
  prompt: '',
  objective: '',
  outputFormat: 'json',
});

// Inicializar disciplina com a primeira atribuída
watch(
  () => authStore.user?.course_units,
  (units) => {
    if (units?.length && form.discipline === null) {
      form.discipline = units[0].id;
    }
  },
  { immediate: true },
);

// Respeita estritamente o estado do Store atualizado com Documentos e Chunks (RAG)
const disciplineDocuments = computed(() =>
  questionLabStore.availableDocuments.filter(
    (d) => d.id_uc === form.discipline && d.status === 'indexed',
  ),
);

const typeLabelMap = {
  multipleChoice: 'Escolha Múltipla',
  trueFalse: 'V/F',
  written: 'Escrita',
  fillBlank: 'Completar',
};

const payloadPreview = computed(() => {
  const selectedDocs = questionLabStore.availableDocuments
    .filter((d) => form.documentIds.includes(d.id))
    .map((d) => ({ id: d.id, name: d.name, chapter: d.chapter }));

  return JSON.stringify(
    {
      discipline: form.discipline,
      questionType: form.type,
      quantity: form.quantity,
      difficulty: form.difficulty,
      objective: form.objective,
      outputFormat: form.outputFormat,
      documents: selectedDocs,
      prompt: form.prompt,
    },
    null,
    2,
  );
});

// Métodos transacionais ligados à Store Global (Promises)
async function submitPrompt() {
  if (!form.prompt.trim() || questionLabStore.isLoading) return;

  await questionLabStore.generateQuestions({
    title: `Lote de ${form.quantity} pergunta(s) · ${form.discipline}`,
    discipline: form.discipline,
    type: form.type,
    typeLabel: typeLabelMap[form.type],
    difficulty: form.difficulty,
    documentIds: [...form.documentIds],
    prompt: form.prompt,
    payload: payloadPreview.value,
  });

  if (!questionLabStore.error) {
    form.prompt = ''; // Opcional: Limpar prompt após submissão bem sucedida.
  }
}

async function markReady(id) {
  if (questionLabStore.isLoading) return;
  await questionLabStore.markDraftReady(id);
}

async function removeDraft(id) {
  if (questionLabStore.isLoading) return;
  if (!confirm('Deseja eliminar este rascunho de IA permanentemente?')) return;
  await questionLabStore.removeDraft(id);
}

function copyPayload() {
  navigator.clipboard.writeText(payloadPreview.value);
}
</script>
