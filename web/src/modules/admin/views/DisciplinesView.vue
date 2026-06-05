<template>
  <div class="space-y-8">
    <div class="page-header">
      <div>
        <h3 class="text-3xl font-bold">Disciplinas</h3>
      </div>
      <button @click="openCreate" class="bg-brand text-white px-6 py-3 rounded-btn font-bold hover:brightness-110 transition-all flex items-center gap-2">
        <i class="pi pi-plus"></i> Criar Disciplina
      </button>
    </div>

    <div
      v-if="store.error"
      class="bg-error/10 border border-error/30 text-error px-4 py-3 rounded-card text-sm"
    >
      <i class="pi pi-exclamation-triangle mr-2"></i> {{ store.error }}
    </div>

    <div class="grid grid-cols-2 sm:grid-cols-4 gap-3 sm:gap-6">
      <div class="bg-surface p-4 sm:p-6 rounded-card border border-white/5">
        <p class="text-text-secondary text-xs sm:text-sm">Total UCs</p>
        <p class="text-2xl sm:text-3xl font-bold mt-2">{{ store.disciplines.length }}</p>
      </div>
      <div class="bg-surface p-4 sm:p-6 rounded-card border border-white/5">
        <p class="text-text-secondary text-xs sm:text-sm">UCs Ativas</p>
        <p class="text-2xl sm:text-3xl font-bold mt-2 text-brand">{{ store.activeDisciplines.length }}</p>
      </div>
      <div class="bg-surface p-4 sm:p-6 rounded-card border border-white/5">
        <p class="text-text-secondary text-xs sm:text-sm">Alunos Inscritos</p>
        <p class="text-2xl sm:text-3xl font-bold mt-2 text-success">{{ store.totalStudents }}</p>
      </div>
      <div class="bg-surface p-4 sm:p-6 rounded-card border border-white/5">
        <p class="text-text-secondary text-xs sm:text-sm">UCs Inativas</p>
        <p class="text-2xl sm:text-3xl font-bold mt-2 text-error">{{ store.inactiveDisciplines.length }}</p>
      </div>
    </div>

    <!-- Cards mobile -->
    <div class="sm:hidden space-y-3">
      <div v-for="d in store.disciplines" :key="d.id" class="bg-surface rounded-card border border-white/5 p-4">
        <div class="flex items-start justify-between gap-3">
          <div class="min-w-0">
            <span class="font-mono text-brand text-xs block">{{ d.code }}</span>
            <p class="font-bold text-sm">{{ d.acronym }} — {{ d.name }}</p>
          </div>
          <div class="flex gap-2 shrink-0">
            <button
              @click="openEdit(d)"
              class="w-9 h-9 flex items-center justify-center rounded-btn border border-white/10 text-text-secondary hover:text-white hover:border-brand/50 transition-all"
            ><i class="pi pi-pencil text-xs"></i></button>
            <button
              @click="removeDiscipline(d.id)"
              class="w-9 h-9 flex items-center justify-center rounded-btn border border-white/10 text-text-secondary hover:text-error hover:border-error/50 transition-all"
            ><i class="pi pi-trash text-xs"></i></button>
          </div>
        </div>
        <div class="flex flex-wrap gap-2 mt-3 items-center">
          <span class="bg-gray-800 px-2 py-0.5 rounded-full text-xs">{{ d.semester }}</span>
          <div
            @click="store.supportsStatus ? store.toggleStatus(d.id) : null"
            :class="store.supportsStatus ? 'cursor-pointer' : 'cursor-not-allowed opacity-70'"
            class="inline-flex items-center gap-1.5"
          >
            <div class="w-1.5 h-1.5 rounded-full" :class="d.active ? 'bg-success' : 'bg-error'"></div>
            <span class="text-xs" :class="d.active ? 'text-success' : 'text-error'">{{ d.active ? 'Ativa' : 'Inativa' }}</span>
          </div>
        </div>
        <div class="flex flex-wrap gap-1 mt-2">
          <span v-for="prof in d.professors" :key="prof" class="bg-gray-800 px-2 py-0.5 rounded-full text-xs text-text-secondary">{{ prof }}</span>
          <span v-if="!d.professors || d.professors.length === 0" class="text-xs text-text-secondary/70">Sem docentes</span>
        </div>
      </div>
    </div>

    <!-- Tabela desktop -->
    <div class="hidden sm:block bg-surface rounded-card border border-white/5 overflow-hidden">
      <div class="overflow-x-auto">
      <table class="w-full text-left min-w-[700px]">
        <thead class="bg-black/20 text-text-secondary uppercase text-[10px] tracking-widest">
          <tr>
            <th class="px-8 py-5 font-semibold">Código / Acrónimo</th>
            <th class="px-8 py-5 font-semibold">Designação</th>
            <th class="px-8 py-5 font-semibold text-center">Semestre</th>
            <th class="px-8 py-5 font-semibold text-center">Docente</th>
            <th class="px-8 py-5 font-semibold">Estado</th>
            <th class="px-8 py-5 font-semibold text-right">Operações</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-white/5">
          <tr v-for="d in store.disciplines" :key="d.id" class="hover:bg-white/2 transition-colors group">
            <td class="px-8 py-5">
              <span class="block font-mono text-brand text-xs">{{ d.code }}</span>
              <span class="font-bold">{{ d.acronym }}</span>
            </td>
            <td class="px-8 py-5 font-medium">{{ d.name }}</td>
            <td class="px-8 py-5 text-center">
              <span class="bg-gray-800 px-3 py-1 rounded-full text-xs">{{ d.semester }}</span>
            </td>
            <td class="px-8 py-5 text-center text-text-secondary text-sm">
              <div class="flex flex-wrap gap-1 justify-center">
                <span v-for="prof in d.professors" :key="prof" class="bg-gray-800 px-2 py-0.5 rounded-full text-xs">{{ prof }}</span>
                <span v-if="!d.professors || d.professors.length === 0" class="text-xs text-text-secondary/70">Sem docentes</span>
              </div>
            </td>
            <td class="px-8 py-5">
              <div
                @click="store.supportsStatus ? store.toggleStatus(d.id) : null"
                :class="store.supportsStatus ? 'cursor-pointer' : 'cursor-not-allowed opacity-70'"
                class="flex items-center gap-2"
              >
                <div class="w-2 h-2 rounded-full" :class="d.active ? 'bg-success' : 'bg-error'"></div>
                <span class="text-xs">{{ d.active ? 'Ativa' : 'Inativa' }}</span>
              </div>
            </td>
            <td class="px-8 py-5 text-right">
              <div class="flex justify-end gap-4 opacity-0 group-hover:opacity-100 transition-opacity">
                <button @click="openEdit(d)" class="text-text-secondary hover:text-white"><i class="pi pi-pencil"></i></button>
                <button @click="removeDiscipline(d.id)" class="text-text-secondary hover:text-error"><i class="pi pi-trash"></i></button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
      </div>
    </div>

    <!-- Modal Criar / Editar -->
    <Teleport to="body">
      <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center p-4">
        <div class="absolute inset-0 bg-black/60 backdrop-blur-sm" @click="showModal = false"></div>
        <div class="relative bg-surface border border-white/10 rounded-card w-full max-w-lg p-4 sm:p-8 shadow-2xl z-10">
          <div class="flex justify-between items-center mb-6">
            <h4 class="text-xl font-bold">{{ editingId ? 'Editar Disciplina' : 'Criar Disciplina' }}</h4>
            <button @click="showModal = false" class="text-text-secondary hover:text-white"><i class="pi pi-times"></i></button>
          </div>

          <div class="space-y-4">
            <div>
              <label class="text-xs font-bold text-text-secondary uppercase tracking-widest">Código UC</label>
              <input v-model="form.code" type="text" placeholder="Ex: 41000"
                     class="w-full bg-background mt-2 p-3 rounded-btn border border-white/10 outline-none focus:border-brand text-sm" />
            </div>
            <div>
              <label class="text-xs font-bold text-text-secondary uppercase tracking-widest">Nome Completo</label>
              <input v-model="form.name" type="text" placeholder="Ex: Sistemas Digitais"
                     class="w-full bg-background mt-2 p-3 rounded-btn border border-white/10 outline-none focus:border-brand text-sm" />
            </div>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label class="text-xs font-bold text-text-secondary uppercase tracking-widest">Semestre</label>
                <select v-model="form.semester" class="w-full bg-background mt-2 p-3 rounded-btn border border-white/10 outline-none focus:border-brand text-sm">
                  <option value="S1">S1 — 1º Semestre</option>
                  <option value="S2">S2 — 2º Semestre</option>
                </select>
              </div>
              <div>
                <label class="text-xs font-bold text-text-secondary uppercase tracking-widest">Ano Letivo</label>
                <input v-model="form.year" type="text" placeholder="2025/2026"
                       class="w-full bg-background mt-2 p-3 rounded-btn border border-white/10 outline-none focus:border-brand text-sm" />
              </div>
            </div>
            <div class="relative">
              <label class="text-xs font-bold text-text-secondary uppercase tracking-widest">Docentes</label>
              <input v-model="profSearch" type="text" placeholder="Procurar docente por nome, email ou NMec..."
                     autocomplete="off"
                     @input="onProfSearch" @focus="onProfSearch"
                     class="w-full bg-background mt-2 p-3 rounded-btn border border-white/10 outline-none focus:border-brand text-sm" />
              <!-- Professor suggestions dropdown -->
              <div v-if="profSuggestions.length > 0" class="absolute left-0 right-0 top-full mt-1 bg-background border border-white/10 rounded-btn shadow-xl z-20 max-h-40 overflow-y-auto">
                <div v-for="p in profSuggestions" :key="p.id"
                     @click="addProfessor(p)"
                     class="px-3 py-2 hover:bg-brand/10 cursor-pointer flex items-center justify-between text-sm transition-colors">
                  <div>
                    <span class="font-medium text-text-primary">{{ p.name }}</span>
                    <span class="text-text-secondary text-xs ml-2">{{ p.email }}</span>
                  </div>
                </div>
              </div>
              <!-- Selected professors tags -->
              <div v-if="selectedProfessors.length > 0" class="flex flex-wrap gap-2 mt-2">
                <span v-for="prof in selectedProfessors" :key="prof.id"
                      class="bg-brand/20 text-brand text-xs px-3 py-1 rounded-full flex items-center gap-1">
                  {{ prof.name }}
                  <button @click="removeProfessor(prof.id)" class="hover:text-white ml-1"><i class="pi pi-times text-[10px]"></i></button>
                </span>
              </div>
              <p class="text-text-secondary text-xs mt-1">Pesquise e selecione os docentes para esta UC.</p>
            </div>
          </div>

          <div class="flex justify-end gap-3 mt-8">
            <button @click="showModal = false" class="px-6 py-3 rounded-btn text-text-secondary hover:text-white border border-white/10 text-sm font-bold transition-all">
              Cancelar
            </button>
            <button @click="save" class="bg-brand px-6 py-3 rounded-btn text-white font-bold hover:brightness-110 transition-all text-sm">
              {{ editingId ? 'Guardar Alterações' : 'Criar Disciplina' }}
            </button>
          </div>
        </div>
      </div>
    </Teleport>

    <ActionDialog
      :visible="showConfirmDialog"
      :title="confirmDialog.title"
      :message="confirmDialog.message"
      :confirm-text="confirmDialog.confirmText"
      variant="danger"
      @update:visible="showConfirmDialog = $event"
      @confirm="runConfirmedAction"
    />
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useDisciplineStore } from '../stores/disciplineStore'
import { useUserStore } from '../stores/userStore'
import ActionDialog from '../../../components/ActionDialog.vue'

const store = useDisciplineStore()
const userStore = useUserStore()

const showConfirmDialog = ref(false)
const confirmDialog = reactive({ title: '', message: '', confirmText: 'Confirmar' })
const confirmedAction = ref(null)

function ask(title, message, confirmText, action) {
  confirmDialog.title = title
  confirmDialog.message = message
  confirmDialog.confirmText = confirmText
  confirmedAction.value = action
  showConfirmDialog.value = true
}

async function runConfirmedAction() {
  await confirmedAction.value?.()
  showConfirmDialog.value = false
  confirmedAction.value = null
}

const showModal = ref(false)
const editingId = ref(null)
const form = reactive({ code: '', name: '', semester: 'S1', year: '2025/2026' })
const profSearch = ref('')
const profSuggestions = ref([])
const selectedProfessors = ref([])

function onProfSearch() {
  const q = profSearch.value.trim().toLowerCase()
  if (!q) { profSuggestions.value = []; return }
  const selectedProfessorIds = new Set(selectedProfessors.value.map((p) => p.id))
  profSuggestions.value = userStore.professors
    .filter((p) => !selectedProfessorIds.has(p.id))
    .filter(p => p.name.toLowerCase().includes(q) || p.email.toLowerCase().includes(q))
    .slice(0, 5)
}

function addProfessor(p) {
  if (!selectedProfessors.value.some((existing) => existing.id === p.id)) {
    selectedProfessors.value.push({
      id: p.id,
      name: p.name,
      email: p.email,
    })
  }
  profSearch.value = ''
  profSuggestions.value = []
}

function removeProfessor(professorId) {
  selectedProfessors.value = selectedProfessors.value.filter((prof) => prof.id !== professorId)
}

function resetForm() {
  form.code = ''; form.name = ''; form.semester = 'S1'; form.year = '2025/2026'
  profSearch.value = ''; profSuggestions.value = []; selectedProfessors.value = []
}

function openCreate() {
  editingId.value = null
  resetForm()
  showModal.value = true
}

function openEdit(d) {
  editingId.value = d.id
  form.code = d.code; form.name = d.name; form.semester = d.semester; form.year = d.year || '2025/2026'
  selectedProfessors.value = (d.professorItems || []).map((professor) => {
    const match = userStore.professors.find((candidate) => candidate.id === professor.id)
    if (match) {
      return {
        id: match.id,
        name: match.name,
        email: match.email,
      }
    }

    return {
      id: professor.id,
      name: professor.name,
      email: professor.email,
    }
  })
  profSearch.value = ''; profSuggestions.value = []
  showModal.value = true
}

async function save() {
  const data = {
    code: form.code,
    name: form.name,
    semester: form.semester,
    year: form.year,
    professorIds: selectedProfessors.value.map((professor) => professor.id),
    students: 0,
    active: true,
  }
  if (editingId.value) {
    await store.updateDiscipline(editingId.value, data)
  } else {
    await store.addDiscipline(data)
  }

  if (!store.error) {
    showModal.value = false
  }
}

function removeDiscipline(id) {
  ask(
    'Remover disciplina',
    'Tens a certeza? Esta ação é irreversível e remove todos os tópicos, exercícios e materiais associados.',
    'Remover',
    () => store.removeDiscipline(id),
  )
}

onMounted(async () => {
  await Promise.all([
    store.loadDisciplines(),
    userStore.loadUsers(),
  ])
})
</script>