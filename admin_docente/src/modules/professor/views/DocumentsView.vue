<template>
  <div class="space-y-8">
    <div class="flex justify-between items-end">
      <div>
        <p class="text-brand font-bold text-sm uppercase tracking-widest mb-1">Repositório</p>
        <h3 class="text-3xl font-bold">Documentos da UC</h3>
        <p class="text-text-secondary mt-1">Carregue PDFs, slides e apontamentos das suas unidades curriculares.</p>
      </div>
      <button @click="showUpload = true"
              :disabled="questionLabStore.isLoading"
              class="bg-brand text-white px-6 py-3 rounded-btn font-bold hover:brightness-110 transition-all flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed">
        <i class="pi pi-upload"></i> Carregar Documento
      </button>
    </div>

    <div v-if="questionLabStore.error" class="bg-error/10 border border-error/30 text-error px-4 py-3 rounded-card text-sm">
      <i class="pi pi-exclamation-triangle mr-2"></i> {{ questionLabStore.error }}
    </div>

    <div class="grid grid-cols-4 gap-6">
      <div class="bg-surface p-6 rounded-card border border-white/5">
        <p class="text-text-secondary text-sm">Total Documentos</p>
        <p class="text-3xl font-bold mt-2">{{ questionLabStore.availableDocuments.length }}</p>
      </div>
      <div class="bg-surface p-6 rounded-card border border-white/5">
        <p class="text-text-secondary text-sm">Disponíveis</p>
        <p class="text-3xl font-bold mt-2 text-success">{{ questionLabStore.availableDocuments.filter(d => d.status === 'indexed').length }}</p>
      </div>
      <div class="bg-surface p-6 rounded-card border border-white/5">
        <p class="text-text-secondary text-sm">A Processar</p>
        <p class="text-3xl font-bold mt-2 text-warning">{{ questionLabStore.availableDocuments.filter(d => d.status === 'processing').length }}</p>
      </div>
      <div class="bg-surface p-6 rounded-card border border-white/5">
        <p class="text-text-secondary text-sm">Disciplinas</p>
        <p class="text-3xl font-bold mt-2 text-brand">{{ new Set(questionLabStore.availableDocuments.map(d => d.discipline)).size }}</p>
      </div>
    </div>

    <div class="flex items-center gap-3">
      <button v-for="f in ['Todos', 'SD', 'AC', 'SE']" :key="f"
              @click="disciplineFilter = f === 'Todos' ? '' : f"
              :class="(f === 'Todos' && !disciplineFilter) || disciplineFilter === f ? 'bg-brand text-white' : 'bg-surface text-text-secondary border border-white/10'"
              class="px-5 py-2 rounded-chip text-sm font-bold transition-all">
        {{ f }}
      </button>
    </div>

    <div class="space-y-3 relative">
      <div v-if="questionLabStore.isLoading" class="absolute inset-0 bg-background/50 backdrop-blur-sm z-20 flex items-start justify-center pt-20">
        <i class="pi pi-spinner pi-spin text-brand text-3xl"></i>
      </div>

      <div v-for="doc in filteredDocuments" :key="doc.id"
           class="bg-surface rounded-card border border-white/5 p-6 flex items-center gap-6 group hover:border-brand/30 transition-all"
           :class="{'opacity-50 pointer-events-none': questionLabStore.isLoading}">
        <div class="w-14 h-14 rounded-btn flex items-center justify-center shrink-0"
             :class="doc.fileType === 'pdf' ? 'bg-red-500/10' : doc.fileType === 'pptx' ? 'bg-orange-500/10' : 'bg-blue-500/10'">
          <i class="text-2xl"
             :class="doc.fileType === 'pdf' ? 'pi pi-file-pdf text-red-400' : doc.fileType === 'pptx' ? 'pi pi-file text-orange-400' : 'pi pi-file-word text-blue-400'"></i>
        </div>

        <div class="flex-1 min-w-0">
          <p class="font-bold text-sm truncate">{{ doc.name }}</p>
          <div class="flex items-center gap-3 mt-1 text-text-secondary text-xs">
            <span class="bg-brand/10 text-brand px-2 py-0.5 rounded-chip font-bold">{{ doc.discipline }}</span>
            <span>{{ doc.chapter }}</span>
            <span>·</span>
            <span>{{ doc.size }}</span>
            <span>·</span>
            <span>{{ doc.uploadedAt }}</span>
          </div>
        </div>

        <div class="flex items-center gap-2">
          <div class="w-2 h-2 rounded-full"
               :class="doc.status === 'indexed' ? 'bg-success' : doc.status === 'processing' ? 'bg-warning animate-pulse' : 'bg-error'"></div>
          <span class="text-xs" :class="doc.status === 'indexed' ? 'text-success' : doc.status === 'processing' ? 'text-warning' : 'text-error'">
            {{ doc.status === 'indexed' ? 'Disponível' : doc.status === 'processing' ? 'A processar...' : 'Erro' }}
          </span>
        </div>

        <div class="flex gap-3 opacity-0 group-hover:opacity-100 transition-opacity">
          <button @click="handleReindex(doc.id)" class="text-text-secondary hover:text-brand" title="Re-indexar">
            <i class="pi pi-refresh"></i>
          </button>
          <button @click="handleRemove(doc.id)" class="text-text-secondary hover:text-error" title="Remover">
            <i class="pi pi-trash"></i>
          </button>
        </div>
      </div>

      <div v-if="filteredDocuments.length === 0" class="bg-surface rounded-card border border-white/5 border-dashed p-12 text-center">
        <i class="pi pi-file-pdf text-4xl text-brand/30 mb-4 block"></i>
        <p class="text-text-secondary">Nenhum documento encontrado. Carregue PDFs ou slides das suas UC.</p>
      </div>
    </div>

    <Teleport to="body">
      <div v-if="showUpload" class="fixed inset-0 z-50 flex items-center justify-center">
        <div class="absolute inset-0 bg-black/60 backdrop-blur-sm" @click="!questionLabStore.isLoading && (showUpload = false)"></div>
        <div class="relative bg-surface border border-white/10 rounded-card w-full max-w-lg p-8 shadow-2xl z-10" :class="{'opacity-75 pointer-events-none': questionLabStore.isLoading}">
          <div class="flex justify-between items-center mb-6">
            <h4 class="text-xl font-bold">Carregar Documento</h4>
            <button @click="showUpload = false" :disabled="questionLabStore.isLoading" class="text-text-secondary hover:text-white disabled:opacity-50"><i class="pi pi-times"></i></button>
          </div>

          <div class="space-y-4">
            <div>
              <label class="text-xs font-bold text-text-secondary uppercase tracking-widest">Disciplina</label>
              <select v-model="uploadForm.discipline" class="w-full bg-background mt-2 p-3 rounded-btn border border-white/10 outline-none focus:border-brand text-sm">
                <option value="SD">Sistemas Digitais (SD)</option>
                <option value="AC">Arquitetura de Computadores (AC)</option>
                <option value="SE">Sistemas Embutidos (SE)</option>
              </select>
            </div>
            <div>
              <label class="text-xs font-bold text-text-secondary uppercase tracking-widest">Capítulo / Tópico</label>
              <input v-model="uploadForm.chapter" type="text" placeholder="Ex: Circuitos Sequenciais"
                     class="w-full bg-background mt-2 p-3 rounded-btn border border-white/10 outline-none focus:border-brand text-sm" />
            </div>
            <div>
              <label class="text-xs font-bold text-text-secondary uppercase tracking-widest">Ficheiro</label>
              <div class="mt-2 border-2 border-dashed border-white/10 rounded-btn p-8 text-center hover:border-brand/50 transition-all cursor-pointer"
                   @click="simulateUploadSelection">
                <i class="pi pi-cloud-upload text-3xl text-brand/50 mb-3 block"></i>
                <p class="text-text-secondary text-sm">
                  <span v-if="!uploadForm.fileName">Clique para selecionar ou arraste um ficheiro</span>
                  <span v-else class="text-brand font-bold">{{ uploadForm.fileName }}</span>
                </p>
                <p class="text-text-secondary text-xs mt-1">PDF, PPTX, DOCX (máx. 50MB)</p>
              </div>
            </div>
          </div>

          <div class="flex justify-end gap-3 mt-8">
            <button @click="showUpload = false" :disabled="questionLabStore.isLoading" class="px-6 py-3 rounded-btn text-text-secondary hover:text-white border border-white/10 text-sm font-bold transition-all disabled:opacity-50">
              Cancelar
            </button>
            <button @click="handleUpload" :disabled="!uploadForm.fileName || questionLabStore.isLoading"
                    class="bg-brand px-6 py-3 rounded-btn text-white font-bold hover:brightness-110 transition-all text-sm disabled:opacity-30 disabled:cursor-not-allowed flex items-center gap-2">
              <i v-if="questionLabStore.isLoading" class="pi pi-spinner pi-spin"></i>
              {{ questionLabStore.isLoading ? 'A Carregar...' : 'Carregar Documento' }}
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
import { ref, computed, reactive } from 'vue'
import { useQuestionLabStore } from '../stores/questionLabStore'

const questionLabStore = useQuestionLabStore()
const disciplineFilter = ref('')
const showUpload = ref(false)

const uploadForm = reactive({
  discipline: 'SD',
  chapter: '',
  fileName: ''
})

const filteredDocuments = computed(() => {
  if (!disciplineFilter.value) return questionLabStore.availableDocuments
  return questionLabStore.availableDocuments.filter(d => d.discipline === disciplineFilter.value)
})

const simulateUploadSelection = () => {
  const mockFiles = ['Resumo_MaquinasEstado.pdf', 'Exercicios_Cache.pdf', 'Slides_Interrupcoes.pptx']
  uploadForm.fileName = mockFiles[Math.floor(Math.random() * mockFiles.length)]
}

async function handleUpload() {
  if (!uploadForm.fileName || questionLabStore.isLoading) return

  const newDoc = {
    name: uploadForm.fileName,
    discipline: uploadForm.discipline,
    chapter: uploadForm.chapter || 'Geral',
    fileType: uploadForm.fileName.split('.').pop(),
    size: (Math.random() * 10 + 1).toFixed(1) + ' MB'
  }

  // Invoca a mutação assíncrona na Store Global
  await questionLabStore.uploadDocument(newDoc)

  if (!questionLabStore.error) {
    uploadForm.fileName = ''
    uploadForm.chapter = ''
    showUpload.value = false
  }
}

async function handleReindex(docId) {
  if (questionLabStore.isLoading) return
  await questionLabStore.reindexDocument(docId)
}

async function handleRemove(docId) {
  if (questionLabStore.isLoading) return
  if (!confirm('Tem a certeza que deseja remover este documento e o seu índice associado?')) return
  await questionLabStore.removeDocument(docId)
}
</script>