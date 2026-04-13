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

    <!-- Conteúdo Principal -->
    <template v-else>
      <div class="flex justify-between items-end">
        <div>
          <p
            class="text-brand font-bold text-sm uppercase tracking-widest mb-1"
          >
            Repositório
          </p>
          <h3 class="text-3xl font-bold">Documentos da UC</h3>
          <p class="text-text-secondary mt-1">
            Carregue PDFs, slides e apontamentos das suas unidades curriculares.
          </p>
        </div>
        <button
          @click="showUpload = true"
          :disabled="questionLabStore.isLoading"
          class="bg-brand text-white px-6 py-3 rounded-btn font-bold hover:brightness-110 transition-all flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <i class="pi pi-upload"></i> Carregar Documento
        </button>
      </div>

      <div
        v-if="questionLabStore.error"
        class="bg-error/10 border border-error/30 text-error px-4 py-3 rounded-card text-sm"
      >
        <i class="pi pi-exclamation-triangle mr-2"></i
        >{{ questionLabStore.error }}
      </div>

      <!-- Estatísticas -->
      <div class="grid grid-cols-4 gap-6">
        <div class="bg-surface p-6 rounded-card border border-white/5">
          <p class="text-text-secondary text-sm">Total Documentos</p>
          <p class="text-3xl font-bold mt-2">
            {{ questionLabStore.availableDocuments.length }}
          </p>
        </div>
        <div class="bg-surface p-6 rounded-card border border-white/5">
          <p class="text-text-secondary text-sm">Disponíveis</p>
          <p class="text-3xl font-bold mt-2 text-success">
            {{
              questionLabStore.availableDocuments.filter(
                (d) => d.status === 'indexed',
              ).length
            }}
          </p>
        </div>
        <div class="bg-surface p-6 rounded-card border border-white/5">
          <p class="text-text-secondary text-sm">A Processar</p>
          <p class="text-3xl font-bold mt-2 text-warning">
            {{
              questionLabStore.availableDocuments.filter(
                (d) => d.status === 'processing',
              ).length
            }}
          </p>
        </div>
        <div class="bg-surface p-6 rounded-card border border-white/5">
          <p class="text-text-secondary text-sm">Disciplinas</p>
          <p class="text-3xl font-bold mt-2 text-brand">
            {{
              new Set(
                questionLabStore.availableDocuments.map((d) => d.discipline),
              ).size
            }}
          </p>
        </div>
      </div>

      <!-- Filtros por disciplina -->
      <div class="flex items-center gap-3 flex-wrap">
        <button
          @click="disciplineFilter = ''"
          :class="
            !disciplineFilter
              ? 'bg-brand text-white'
              : 'bg-surface text-text-secondary border border-white/10'
          "
          class="px-5 py-2 rounded-chip text-sm font-bold transition-all"
        >
          Todos
        </button>
        <button
          v-for="uc in authStore.user?.course_units || []"
          :key="uc.id"
          @click="disciplineFilter = uc.id"
          :class="
            disciplineFilter === uc.id
              ? 'bg-brand text-white'
              : 'bg-surface text-text-secondary border border-white/10'
          "
          class="px-5 py-2 rounded-chip text-sm font-bold transition-all"
        >
          {{ uc.name }}
        </button>
      </div>

      <!-- Lista de documentos -->
      <div class="space-y-3 relative">
        <div
          v-if="questionLabStore.isLoading"
          class="absolute inset-0 bg-background/50 backdrop-blur-sm z-20 flex items-start justify-center pt-20"
        >
          <i class="pi pi-spinner pi-spin text-brand text-3xl"></i>
        </div>

        <div
          v-for="doc in filteredDocuments"
          :key="doc.id_material"
          class="bg-surface rounded-card border border-white/5 p-6 flex items-center gap-6 group hover:border-brand/30 transition-all"
          :class="{
            'opacity-50 pointer-events-none': questionLabStore.isLoading,
          }"
        >
          <!-- Ícone -->
          <div
            class="w-14 h-14 rounded-btn flex items-center justify-center shrink-0"
            :class="
              doc.fileType === 'pdf'
                ? 'bg-red-500/10'
                : doc.fileType === 'pptx'
                  ? 'bg-orange-500/10'
                  : 'bg-blue-500/10'
            "
          >
            <i
              class="text-2xl"
              :class="
                doc.fileType === 'pdf'
                  ? 'pi pi-file-pdf text-red-400'
                  : doc.fileType === 'pptx'
                    ? 'pi pi-file text-orange-400'
                    : 'pi pi-file-word text-blue-400'
              "
            ></i>
          </div>

          <!-- Info -->
          <div class="flex-1 min-w-0">
            <p class="font-bold text-sm truncate">{{ doc.name }}</p>
            <div
              class="flex items-center gap-3 mt-1 text-text-secondary text-xs flex-wrap"
            >
              <span
                class="bg-brand/10 text-brand px-2 py-0.5 rounded-chip font-bold"
                >{{ doc.discipline }}</span
              >
              <span>·</span>
              <span>{{ doc.uploadedAt }}</span>
              <span>·</span>
              <!-- Quem carregou -->
              <span
                :class="
                  doc.is_mine ? 'text-brand font-bold' : 'text-text-secondary'
                "
              >
                <i class="pi pi-user mr-1 text-[10px]"></i>
                {{ doc.is_mine ? 'Por si' : `Por ${doc.uploaded_by_name}` }}
              </span>
            </div>
          </div>

          <!-- Status -->
          <div class="flex items-center gap-2 shrink-0">
            <div
              class="w-2 h-2 rounded-full"
              :class="
                doc.status === 'indexed'
                  ? 'bg-success'
                  : doc.status === 'processing'
                    ? 'bg-warning animate-pulse'
                    : 'bg-error'
              "
            ></div>
            <span
              class="text-xs whitespace-nowrap"
              :class="
                doc.status === 'indexed'
                  ? 'text-success'
                  : doc.status === 'processing'
                    ? 'text-warning'
                    : 'text-error'
              "
            >
              {{
                doc.status === 'indexed'
                  ? 'Disponível'
                  : doc.status === 'processing'
                    ? 'A processar...'
                    : 'Erro'
              }}
            </span>
          </div>

          <!-- Ações — só o dono pode reindexar/remover -->
          <div
            v-if="doc.is_mine"
            class="flex gap-3 opacity-0 group-hover:opacity-100 transition-opacity shrink-0"
          >
            <button
              @click="handleReindex(doc.id_material)"
              class="text-text-secondary hover:text-brand transition-colors"
              title="Re-indexar"
            >
              <i class="pi pi-refresh"></i>
            </button>
            <button
              @click="handleRemove(doc.id_material)"
              class="text-text-secondary hover:text-error transition-colors"
              title="Remover"
            >
              <i class="pi pi-trash"></i>
            </button>
          </div>
        </div>

        <div
          v-if="filteredDocuments.length === 0"
          class="bg-surface rounded-card border border-white/5 border-dashed p-12 text-center"
        >
          <i class="pi pi-file-pdf text-4xl text-brand/30 mb-4 block"></i>
          <p class="text-text-secondary">
            Nenhum documento encontrado. Carregue PDFs ou slides das suas UC.
          </p>
        </div>
      </div>

      <!-- Modal Upload -->
      <Teleport to="body">
        <div
          v-if="showUpload"
          class="fixed inset-0 z-50 flex items-center justify-center"
        >
          <div
            class="absolute inset-0 bg-black/60 backdrop-blur-sm"
            @click="!questionLabStore.isLoading && (showUpload = false)"
          ></div>
          <div
            class="relative bg-surface border border-white/10 rounded-card w-full max-w-lg p-8 shadow-2xl z-10"
            :class="{
              'opacity-75 pointer-events-none': questionLabStore.isLoading,
            }"
          >
            <div class="flex justify-between items-center mb-6">
              <h4 class="text-xl font-bold">Carregar Documento</h4>
              <button
                @click="showUpload = false"
                :disabled="questionLabStore.isLoading"
                class="text-text-secondary hover:text-white disabled:opacity-50"
              >
                <i class="pi pi-times"></i>
              </button>
            </div>

            <div class="space-y-4">
              <div>
                <label
                  class="text-xs font-bold text-text-secondary uppercase tracking-widest"
                  >Disciplina</label
                >
                <select
                  v-model="uploadForm.discipline"
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
                  >Ficheiro</label
                >
                <input
                  ref="fileInput"
                  type="file"
                  accept=".pdf,.pptx,.docx"
                  @change="handleFileSelected"
                  class="hidden"
                />
                <div
                  class="mt-2 border-2 border-dashed border-white/10 rounded-btn p-8 text-center hover:border-brand/50 transition-all cursor-pointer"
                  @click="openFileSelector"
                >
                  <i
                    class="pi pi-cloud-upload text-3xl text-brand/50 mb-3 block"
                  ></i>
                  <p class="text-text-secondary text-sm">
                    <span v-if="!uploadForm.fileName"
                      >Clique para selecionar ou arraste um ficheiro</span
                    >
                    <span v-else class="text-brand font-bold">{{
                      uploadForm.fileName
                    }}</span>
                  </p>
                  <p class="text-text-secondary text-xs mt-1">
                    PDF, PPTX, DOCX
                  </p>
                </div>
              </div>
            </div>

            <div class="flex justify-end gap-3 mt-8">
              <button
                @click="showUpload = false"
                :disabled="questionLabStore.isLoading"
                class="px-6 py-3 rounded-btn text-text-secondary hover:text-white border border-white/10 text-sm font-bold transition-all disabled:opacity-50"
              >
                Cancelar
              </button>
              <button
                @click="handleUpload"
                :disabled="!uploadForm.fileName || questionLabStore.isLoading"
                class="bg-brand px-6 py-3 rounded-btn text-white font-bold hover:brightness-110 transition-all text-sm disabled:opacity-30 disabled:cursor-not-allowed flex items-center gap-2"
              >
                <i
                  v-if="questionLabStore.isLoading"
                  class="pi pi-spinner pi-spin"
                ></i>
                {{
                  questionLabStore.isLoading
                    ? 'A Carregar...'
                    : 'Carregar Documento'
                }}
              </button>
            </div>
          </div>
        </div>
      </Teleport>
    </template>
  </div>
</template>

<script setup>
import { ref, computed, reactive, onMounted, watch } from 'vue';
import { useAuthStore } from '../../../stores/authStore';
import { useQuestionLabStore } from '../stores/questionLabStore';
import { http } from '../../../services/http';

const authStore = useAuthStore();
const questionLabStore = useQuestionLabStore();

onMounted(async () => {
  await questionLabStore.loadDocuments();
});

const disciplineFilter = ref('');
const showUpload = ref(false);
const fileInput = ref(null);

const uploadForm = reactive({
  discipline: null,
  fileName: '',
  file: null,
});

const initDiscipline = () => {
  if (
    uploadForm.discipline === null &&
    authStore.user?.course_units?.length > 0
  ) {
    uploadForm.discipline = authStore.user.course_units[0].id;
  }
};

watch(
  () => authStore.user?.course_units,
  () => {
    initDiscipline();
  },
  { immediate: true },
);

const filteredDocuments = computed(() => {
  if (!disciplineFilter.value) return questionLabStore.availableDocuments;
  return questionLabStore.availableDocuments.filter(
    (d) => d.id_uc === disciplineFilter.value,
  );
});

const openFileSelector = () => {
  fileInput.value?.click();
};

const handleFileSelected = (event) => {
  const file = event.target.files?.[0];
  if (file) {
    uploadForm.file = file;
    uploadForm.fileName = file.name;
  }
};

async function handleUpload() {
  if (
    !uploadForm.file ||
    !uploadForm.fileName ||
    !uploadForm.discipline ||
    questionLabStore.isLoading
  )
    return;

  const id_uc = uploadForm.discipline;
  questionLabStore.isLoading = true;
  questionLabStore.error = null;

  try {
    const formData = new FormData();
    formData.append('file', uploadForm.file);

    await http.post(
      `/api/v1/professors/index-material?id_uc=${id_uc}`,
      formData,
    );

    await questionLabStore.loadDocuments(true);

    uploadForm.fileName = '';
    uploadForm.file = null;
    showUpload.value = false;
  } catch (error) {
    let errorMsg = `Erro ao carregar documento: ${error.message}`;
    if (error.response?.status === 404) errorMsg = 'Rota não encontrada (404).';
    else if (error.response?.status === 403)
      errorMsg = 'Não tens acesso a esta disciplina.';
    else if (error.response?.status === 400)
      errorMsg = `Erro de validação: ${error.response?.data?.detail || 'tipo de ficheiro inválido?'}`;
    else if (error.response?.data?.detail)
      errorMsg = `Erro: ${error.response.data.detail}`;
    questionLabStore.error = errorMsg;
  } finally {
    questionLabStore.isLoading = false;
  }
}

async function handleReindex(docId) {
  if (questionLabStore.isLoading) return;
  await questionLabStore.reindexDocument(docId);
}

async function handleRemove(docId) {
  if (questionLabStore.isLoading) return;
  if (!confirm('Tem a certeza que deseja remover este documento?')) return;
  await questionLabStore.removeDocument(docId);
}
</script>
