<template>
  <div class="space-y-8">
    <!-- No course units -->
    <div v-if="!authStore.hasCourseUnits" class="space-y-8">
      <div>
        <h3 class="text-3xl font-bold">Nenhuma Disciplina Atribuída</h3>
        <p class="text-text-secondary mt-1">Necessita de disciplinas para criar quizzes.</p>
      </div>
    </div>

    <!-- Active Session Overlay -->
    <template v-else-if="quizStore.activeSession">
      <div>
        <button @click="handleCloseSession" class="flex items-center gap-2 text-text-secondary hover:text-white transition mb-4 text-sm">
          <i class="pi pi-arrow-left"></i> Voltar aos Quizzes
        </button>
        <h3 class="text-3xl font-bold">{{ quizStore.activeSession.quiz_title }}</h3>
      </div>

      <!-- Lobby Phase -->
      <div v-if="quizStore.activeSession.phase === 'lobby'" class="grid grid-cols-1 sm:grid-cols-2 gap-6">
        <!-- Room Code -->
        <div class="bg-surface rounded-card border border-white/5 p-8 flex flex-col items-center justify-center gap-4">
          <p class="text-text-secondary text-sm uppercase tracking-widest">Código da Sala</p>
          <p class="text-6xl font-black tracking-widest text-brand font-mono">{{ quizStore.activeSession.room_code }}</p>
          <button @click="copyCode" class="flex items-center gap-2 text-sm text-text-secondary hover:text-white transition">
            <i class="pi pi-copy"></i> {{ copied ? 'Copiado!' : 'Copiar código' }}
          </button>
          <p class="text-text-secondary text-xs mt-2">Alunos entram com este código na app</p>
        </div>

        <!-- Participants -->
        <div class="bg-surface rounded-card border border-white/5 p-6 flex flex-col gap-4">
          <div class="flex items-center justify-between">
            <h4 class="font-bold flex items-center gap-2">
              <i class="pi pi-users text-brand"></i>
              Participantes
            </h4>
            <span class="text-brand font-bold text-xl">{{ quizStore.participants.length }}</span>
          </div>

          <div class="flex-1 overflow-y-auto space-y-2 max-h-48">
            <div v-if="quizStore.participants.length === 0" class="text-text-secondary text-sm py-4 text-center">
              <i class="pi pi-spin pi-spinner block text-2xl mb-2"></i>
              À espera de alunos...
            </div>
            <div v-for="p in quizStore.participants" :key="p.student_id"
              class="flex items-center gap-3 bg-background px-4 py-2.5 rounded-btn border border-white/5">
              <div class="w-7 h-7 rounded-full bg-brand/20 flex items-center justify-center text-brand text-xs font-bold">
                {{ p.student_name[0].toUpperCase() }}
              </div>
              <span class="text-sm font-medium">{{ p.student_name }}</span>
            </div>
          </div>

          <button @click="quizStore.startSession()"
            :disabled="quizStore.participants.length === 0"
            class="w-full py-3 bg-brand text-white rounded-btn font-semibold hover:bg-brand/80 transition disabled:opacity-40 disabled:cursor-not-allowed flex items-center justify-center gap-2">
            <i class="pi pi-play"></i>
            Iniciar Quiz
          </button>
        </div>
      </div>

      <!-- Active Phase -->
      <div v-else-if="quizStore.activeSession.phase === 'active'" class="grid grid-cols-1 sm:grid-cols-2 gap-6">
        <!-- Current Question -->
        <div class="bg-surface rounded-card border border-white/5 p-6 space-y-4">
          <div class="flex items-center justify-between">
            <p class="text-text-secondary text-sm">Pergunta atual</p>
            <span class="text-brand font-bold text-sm">
              {{ (quizStore.currentQuestion?.index ?? 0) + 1 }} / {{ quizStore.currentQuestion?.total ?? '?' }}
            </span>
          </div>
          <p class="text-lg font-semibold leading-relaxed">{{ quizStore.currentQuestion?.question }}</p>
          <div class="space-y-2">
            <div v-for="(opt, i) in (quizStore.currentQuestion?.options ?? [])" :key="i"
              class="bg-background px-4 py-2.5 rounded-btn border border-white/5 text-sm">
              <span class="text-brand font-bold mr-2">
                {{ quizStore.currentQuestion?.exercise_type === 'True/False' ? (i === 0 ? 'V' : 'F') : String.fromCharCode(65 + i) }}
              </span>
              {{ opt.length >= 2 && opt[1] === ')' ? opt.slice(2).trim() : opt }}
            </div>
          </div>
        </div>

        <!-- Controls -->
        <div class="bg-surface rounded-card border border-white/5 p-6 flex flex-col gap-4">
          <h4 class="font-bold">Controlo do Quiz</h4>
          <div class="flex items-center justify-between bg-background px-4 py-3 rounded-btn border border-white/5">
            <span class="text-text-secondary text-sm">Participantes</span>
            <span class="font-bold text-brand">{{ quizStore.participants.length }}</span>
          </div>

          <div class="mt-auto space-y-3">
            <button @click="quizStore.nextQuestion()"
              class="w-full py-3 bg-brand text-white rounded-btn font-semibold hover:bg-brand/80 transition flex items-center justify-center gap-2">
              <i class="pi pi-step-forward"></i>
              Próxima Pergunta / Terminar
            </button>
            <button @click="confirmEnd = true"
              class="w-full py-3 bg-error/10 text-error rounded-btn font-semibold border border-error/30 hover:bg-error/20 transition flex items-center justify-center gap-2">
              <i class="pi pi-stop-circle"></i>
              Terminar Agora
            </button>
          </div>
        </div>
      </div>

      <!-- Finished Phase -->
      <div v-else-if="quizStore.activeSession.phase === 'finished'" class="space-y-6">
        <div class="bg-surface rounded-card border border-white/5 p-8">
          <h4 class="text-xl font-bold mb-6 flex items-center gap-3">
            <i class="pi pi-trophy text-warning text-2xl"></i> Classificação Final
          </h4>
          <div class="space-y-3">
            <div v-for="entry in quizStore.finalLeaderboard" :key="entry.rank"
              class="flex items-center gap-4 bg-background px-5 py-3 rounded-btn border border-white/5">
              <span :class="['text-xl font-black w-8 text-center', entry.rank === 1 ? 'text-warning' : entry.rank === 2 ? 'text-gray-300' : entry.rank === 3 ? 'text-amber-600' : 'text-text-secondary']">
                {{ entry.rank }}
              </span>
              <span class="flex-1 font-semibold">{{ entry.student_name }}</span>
              <span class="font-bold text-brand">{{ entry.score }} pts</span>
            </div>
            <div v-if="!quizStore.finalLeaderboard.length" class="text-text-secondary text-sm text-center py-4">
              Sem participantes.
            </div>
          </div>
          <button @click="quizStore.closeSession()" class="mt-6 px-6 py-3 bg-surface border border-white/10 rounded-btn hover:border-brand/50 transition text-sm font-semibold">
            Fechar Sessão
          </button>
        </div>
      </div>
    </template>

    <!-- Main Quiz List -->
    <template v-else>
      <div class="page-header">
        <div>
          <h3 class="text-2xl sm:text-3xl font-bold">Quizz ao Vivo</h3>
          <p class="text-text-secondary mt-1">Crie quizzes com exercícios publicados e lance sessões ao vivo.</p>
        </div>
        <button @click="showCreate = true"
          class="flex items-center gap-2 px-5 py-2.5 bg-brand text-white rounded-btn font-semibold hover:bg-brand/80 transition shrink-0">
          <i class="pi pi-plus"></i> Novo Quiz
        </button>
      </div>

      <div v-if="quizStore.error" class="bg-error/10 border border-error/30 text-error px-4 py-3 rounded-card text-sm">
        <i class="pi pi-exclamation-triangle mr-2"></i>{{ quizStore.error }}
      </div>

      <!-- Empty state -->
      <div v-if="!quizStore.isLoading && quizzes.length === 0"
        class="bg-surface rounded-card border border-white/5 p-12 text-center">
        <i class="pi pi-bolt text-4xl text-brand mb-4 block"></i>
        <p class="font-bold text-lg mb-1">Sem quizzes ainda</p>
        <p class="text-text-secondary text-sm mb-6">Crie o primeiro quiz para começar uma sessão ao vivo.</p>
        <button @click="showCreate = true" class="px-6 py-3 bg-brand text-white rounded-btn font-semibold hover:bg-brand/80 transition">
          Criar Quiz
        </button>
      </div>

      <!-- Quiz grid -->
      <div v-else class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        <div v-for="quiz in quizzes" :key="quiz.id_quiz"
          class="bg-surface rounded-card border border-white/5 p-5 flex flex-col gap-4 hover:border-brand/30 transition group">
          <div class="flex items-start justify-between gap-2">
            <div class="flex-1 min-w-0">
              <p class="font-bold truncate">{{ quiz.title }}</p>
              <p class="text-text-secondary text-xs mt-0.5">{{ ucName(quiz.id_uc) }}</p>
            </div>
            <button @click="deleteQuiz(quiz.id_quiz)" title="Apagar"
              class="text-text-secondary hover:text-error transition opacity-0 group-hover:opacity-100 shrink-0">
              <i class="pi pi-trash text-sm"></i>
            </button>
          </div>
          <div class="flex items-center gap-2 text-text-secondary text-xs">
            <i class="pi pi-list"></i>
            {{ quiz.exercise_count }} exercício{{ quiz.exercise_count !== 1 ? 's' : '' }}
          </div>
          <button @click="handleOpenSession(quiz)"
            class="mt-auto w-full py-2.5 bg-brand/10 text-brand border border-brand/30 rounded-btn font-semibold hover:bg-brand hover:text-white transition flex items-center justify-center gap-2 text-sm">
            <i class="pi pi-play-circle"></i> Abrir Sessão
          </button>
        </div>
      </div>
    </template>

    <!-- ── Create Quiz Dialog ─────────────────────────────────────────────── -->
    <div v-if="showCreate" class="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-6" @click.self="showCreate = false">
      <div class="bg-surface rounded-card border border-white/10 w-full max-w-md p-8 space-y-6">
        <div class="flex items-center justify-between">
          <h4 class="text-xl font-bold">Novo Quiz</h4>
          <button @click="showCreate = false" class="text-text-secondary hover:text-white transition">
            <i class="pi pi-times text-xl"></i>
          </button>
        </div>

        <div class="space-y-4">
          <div>
            <label class="text-sm text-text-secondary mb-1 block">Título *</label>
            <input v-model="form.title" placeholder="Ex: Quiz — Portas Lógicas"
              class="w-full bg-background border border-white/10 rounded-btn px-4 py-2.5 text-sm focus:border-brand/50 outline-none transition" />
          </div>

          <div>
            <label class="text-sm text-text-secondary mb-1 block">Disciplina *</label>
            <select v-model="form.id_uc" @change="onUcChange"
              class="w-full bg-background border border-white/10 rounded-btn px-4 py-2.5 text-sm focus:border-brand/50 outline-none transition">
              <option value="" disabled>Selecionar disciplina...</option>
              <option v-for="uc in courseUnits" :key="uc.id" :value="uc.id">{{ uc.name }}</option>
            </select>
          </div>

          <!-- Exercise picker trigger -->
          <div v-if="form.id_uc">
            <label class="text-sm text-text-secondary mb-1 block">Exercícios *</label>
            <button @click="showPicker = true"
              class="w-full flex items-center justify-between bg-background border border-white/10 hover:border-brand/40 rounded-btn px-4 py-3 text-sm transition">
              <span :class="form.exercise_ids.length ? 'text-white' : 'text-text-secondary'">
                {{ form.exercise_ids.length ? `${form.exercise_ids.length} exercício${form.exercise_ids.length !== 1 ? 's' : ''} selecionado${form.exercise_ids.length !== 1 ? 's' : ''}` : 'Selecionar exercícios...' }}
              </span>
              <i class="pi pi-external-link text-text-secondary"></i>
            </button>
          </div>
        </div>

        <div v-if="createError" class="bg-error/10 border border-error/30 text-error px-4 py-2 rounded-card text-sm">
          {{ createError }}
        </div>

        <div class="flex gap-3 pt-2">
          <button @click="showCreate = false" class="px-5 py-2.5 rounded-btn border border-white/10 hover:border-white/30 transition text-sm">
            Cancelar
          </button>
          <button @click="handleCreate" :disabled="!canCreate || quizStore.isLoading"
            class="flex-1 py-2.5 bg-brand text-white rounded-btn font-semibold hover:bg-brand/80 transition disabled:opacity-40 flex items-center justify-center gap-2 text-sm">
            <i class="pi pi-spin pi-spinner" v-if="quizStore.isLoading"></i>
            <i class="pi pi-check" v-else></i>
            Criar Quiz
          </button>
        </div>
      </div>
    </div>

    <!-- ── Exercise Picker Modal ───────────────────────────────────────────── -->
    <div v-if="showPicker" class="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center z-60 p-6">
      <div class="bg-surface rounded-card border border-white/10 w-full max-w-4xl flex flex-col" style="max-height: 90vh">

        <!-- Header -->
        <div class="flex items-center justify-between px-6 py-5 border-b border-white/8 shrink-0">
          <div>
            <h4 class="font-bold text-lg">Selecionar Exercícios</h4>
            <p class="text-text-secondary text-xs mt-0.5">{{ ucName(form.id_uc) }}</p>
          </div>
          <div class="flex items-center gap-4">
            <button v-if="visibleExercises.length > 0" @click="toggleSelectAll"
              class="text-sm text-text-secondary hover:text-brand transition font-medium">
              {{ allVisibleSelected ? 'Desselecionar todos' : 'Selecionar todos' }}
            </button>
            <span class="h-4 w-px bg-white/10"></span>
            <span class="text-brand text-sm font-semibold tabular-nums">
              {{ form.exercise_ids.length }} selecionado{{ form.exercise_ids.length !== 1 ? 's' : '' }}
            </span>
            <button @click="showPicker = false" class="text-text-secondary hover:text-white transition ml-2">
              <i class="pi pi-times text-xl"></i>
            </button>
          </div>
        </div>

        <!-- Dropdowns filter bar -->
        <div class="px-6 py-3 border-b border-white/8 shrink-0 flex items-center gap-3 flex-wrap">
          <!-- Topic dropdown -->
          <select v-model="filterTopic"
            class="bg-background border border-white/10 rounded-btn px-3 py-2 text-sm text-white focus:border-brand/50 outline-none transition min-w-[180px]">
            <option :value="null">Todos os tópicos</option>
            <option v-for="t in availableTopics" :key="t" :value="t">{{ t }}</option>
          </select>

          <!-- Difficulty dropdown -->
          <select v-model="filterDifficulty"
            class="bg-background border border-white/10 rounded-btn px-3 py-2 text-sm text-white focus:border-brand/50 outline-none transition">
            <option :value="null">Todas as dificuldades</option>
            <option value="Easy">Fácil</option>
            <option value="Medium">Médio</option>
            <option value="Hard">Difícil</option>
          </select>

          <!-- Type dropdown -->
          <select v-model="filterType"
            class="bg-background border border-white/10 rounded-btn px-3 py-2 text-sm text-white focus:border-brand/50 outline-none transition">
            <option :value="null">Todos os tipos</option>
            <option value="Multiple Choice">Escolha Múltipla</option>
            <option value="True/False">Verdadeiro / Falso</option>
          </select>

          <!-- Result count + clear -->
          <span class="text-text-secondary text-xs ml-auto">
            {{ visibleExercises.length }} exercício{{ visibleExercises.length !== 1 ? 's' : '' }}
          </span>
          <button v-if="filterTopic || filterDifficulty || filterType"
            @click="filterTopic = null; filterDifficulty = null; filterType = null"
            class="text-xs text-text-secondary hover:text-error transition flex items-center gap-1">
            <i class="pi pi-filter-slash"></i> Limpar filtros
          </button>
        </div>

        <!-- Exercise cards -->
        <div class="overflow-y-auto flex-1 p-5 space-y-3">
          <div v-if="visibleExercises.length === 0" class="text-text-secondary text-sm text-center py-16">
            Sem exercícios para estes filtros.
          </div>

          <label v-for="ex in visibleExercises" :key="ex.id"
            class="block bg-background rounded-card border cursor-pointer transition group"
            :class="form.exercise_ids.includes(ex.id)
              ? 'border-brand/50 ring-1 ring-brand/20'
              : 'border-white/5 hover:border-white/20'">
            <div class="p-5">
              <!-- Top row: checkbox + meta tags -->
              <div class="flex items-start gap-3">
                <div class="mt-0.5 shrink-0">
                  <input type="checkbox" :value="ex.id" v-model="form.exercise_ids" class="w-4 h-4 accent-brand" />
                </div>
                <div class="flex-1 min-w-0">
                  <!-- Tags row -->
                  <div class="flex items-center gap-2 mb-2.5 flex-wrap">
                    <span class="text-brand text-xs font-bold uppercase tracking-wide">{{ ex.topic_name }}</span>
                    <span :class="['text-xs font-semibold px-2 py-0.5 rounded-full', difficultyClass(ex.difficulty, true)]">
                      {{ difficultyLabel(ex.difficulty) }}
                    </span>
                    <span class="text-xs text-text-secondary px-2 py-0.5 rounded-full border border-white/10">
                      {{ ex.type === 'Multiple Choice' ? 'Escolha Múltipla' : 'V / F' }}
                    </span>
                  </div>

                  <!-- Question -->
                  <p class="text-white text-sm font-medium leading-relaxed mb-4">{{ ex.question }}</p>

                  <!-- Options grid -->
                  <div class="grid gap-2" :class="ex.type === 'True/False' ? 'grid-cols-2' : 'grid-cols-2'">
                    <div v-for="(opt, i) in resolvedOptions(ex)" :key="i"
                      :class="['flex items-start gap-2.5 rounded-btn border px-3 py-2.5 text-sm',
                        isCorrectOption(ex, i)
                          ? 'border-brand/40 bg-brand/10 text-brand'
                          : 'border-white/10 text-text-secondary']">
                      <!-- Letter label -->
                      <span :class="['w-5 h-5 rounded flex items-center justify-center text-xs font-bold shrink-0 mt-0.5',
                        isCorrectOption(ex, i) ? 'bg-brand/20 text-brand' : 'bg-white/8 text-text-secondary']">
                        {{ ex.type === 'True/False' ? (i === 0 ? 'V' : 'F') : String.fromCharCode(65 + i) }}
                      </span>
                      <!-- Option text (strip "A) " prefix) -->
                      <span class="leading-snug">{{ stripPrefix(opt) }}</span>
                      <!-- Correct checkmark -->
                      <i v-if="isCorrectOption(ex, i)" class="pi pi-check-circle text-brand ml-auto mt-0.5 text-xs shrink-0"></i>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </label>
        </div>

        <!-- Footer -->
        <div class="px-6 py-4 border-t border-white/8 shrink-0 flex items-center justify-between gap-3">
          <button @click="form.exercise_ids = []"
            class="px-4 py-2 rounded-btn border border-white/10 hover:border-error/40 hover:text-error text-text-secondary transition text-sm">
            Limpar seleção
          </button>
          <button @click="showPicker = false"
            :class="['px-8 py-2.5 rounded-btn font-semibold transition text-sm',
              form.exercise_ids.length
                ? 'bg-brand text-white hover:bg-brand/80'
                : 'bg-white/10 text-text-secondary cursor-not-allowed']">
            Confirmar{{ form.exercise_ids.length ? ` (${form.exercise_ids.length})` : '' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Confirm end dialog -->
    <div v-if="confirmEnd" class="fixed inset-0 bg-black/60 flex items-center justify-center z-50">
      <div class="bg-surface rounded-card border border-white/10 p-8 max-w-sm w-full space-y-4">
        <h4 class="font-bold text-lg">Terminar sessão?</h4>
        <p class="text-text-secondary text-sm">Todos os alunos verão a classificação final.</p>
        <div class="flex gap-3">
          <button @click="confirmEnd = false" class="flex-1 py-2.5 rounded-btn border border-white/10 hover:border-white/30 transition text-sm">Cancelar</button>
          <button @click="handleEnd" class="flex-1 py-2.5 bg-error text-white rounded-btn font-semibold hover:bg-error/80 transition text-sm">Terminar</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useAuthStore } from '../../../stores/authStore'
import { useExerciseStore } from '../stores/exerciseStore'
import { useQuizStore } from '../stores/quizStore'

const authStore = useAuthStore()
const exerciseStore = useExerciseStore()
const quizStore = useQuizStore()

const showCreate = ref(false)
const showPicker = ref(false)
const confirmEnd = ref(false)
const copied = ref(false)
const createError = ref(null)
const filterDifficulty = ref(null)
const filterType = ref(null)
const filterTopic = ref(null)

const form = ref({
  title: '',
  id_uc: '',
  exercise_ids: [],
})

const courseUnits = computed(() => authStore.user?.course_units || [])

const quizzes = computed(() => quizStore.quizzes)

const filteredExercises = computed(() =>
  exerciseStore.publishedExercises.filter((ex) => ex.id_uc === form.value.id_uc),
)

const availableTopics = computed(() =>
  [...new Set(filteredExercises.value.map((ex) => ex.topic_name).filter(Boolean))].sort(),
)

const visibleExercises = computed(() =>
  filteredExercises.value.filter((ex) => {
    if (filterTopic.value && ex.topic_name !== filterTopic.value) return false
    if (filterDifficulty.value && ex.difficulty !== filterDifficulty.value) return false
    if (filterType.value && ex.type !== filterType.value) return false
    return true
  }),
)

const allVisibleSelected = computed(() =>
  visibleExercises.value.length > 0 &&
  visibleExercises.value.every((ex) => form.value.exercise_ids.includes(ex.id)),
)

function toggleSelectAll() {
  if (allVisibleSelected.value) {
    const visibleIds = new Set(visibleExercises.value.map((ex) => ex.id))
    form.value.exercise_ids = form.value.exercise_ids.filter((id) => !visibleIds.has(id))
  } else {
    const existing = new Set(form.value.exercise_ids)
    visibleExercises.value.forEach((ex) => existing.add(ex.id))
    form.value.exercise_ids = [...existing]
  }
}

function difficultyLabel(d) {
  return { Easy: 'Fácil', Medium: 'Médio', Hard: 'Difícil' }[d] ?? d
}

function difficultyClass(d, active) {
  if (!active) return 'border-white/10 text-text-secondary'
  return {
    Easy: 'border-success/60 bg-success/10 text-success',
    Medium: 'border-warning/60 bg-warning/10 text-warning',
    Hard: 'border-error/60 bg-error/10 text-error',
  }[d] ?? 'border-brand/60 bg-brand/10 text-brand'
}

function stripPrefix(opt) {
  if (opt && opt.length >= 2 && opt[1] === ')') return opt.slice(2).trim()
  return opt ?? ''
}

function resolvedOptions(ex) {
  if (ex.options?.length) return ex.options
  if (ex.type === 'True/False') return ['A) Verdadeiro', 'B) Falso']
  return []
}

function isCorrectOption(ex, i) {
  const opts = resolvedOptions(ex)
  if (!opts.length || !ex.correct) return false
  const raw = opts[i]
  const key = raw?.length >= 2 && raw[1] === ')' ? raw[0] : raw
  return key === ex.correct
}

const canCreate = computed(() =>
  form.value.title.trim().length >= 2 &&
  form.value.id_uc !== '' &&
  form.value.exercise_ids.length >= 1,
)

function ucName(id) {
  return courseUnits.value.find((uc) => uc.id === id)?.name || `UC ${id}`
}

function onUcChange() {
  form.value.exercise_ids = []
  filterDifficulty.value = null
  filterType.value = null
  filterTopic.value = null
  showPicker.value = false
}

async function handleCreate() {
  createError.value = null
  try {
    await quizStore.createQuiz({
      title: form.value.title.trim(),
      id_uc: form.value.id_uc,
      exercise_ids: form.value.exercise_ids,
    })
    form.value = { title: '', id_uc: '', exercise_ids: [] }
    showCreate.value = false
  } catch (e) {
    createError.value = quizStore.error || 'Erro ao criar quiz.'
  }
}

async function handleOpenSession(quiz) {
  try {
    const session = await quizStore.openSession(quiz.id_quiz)
    quizStore.connectWs(session.id_session)
  } catch {
    // error shown via store
  }
}

function deleteQuiz(id) {
  quizStore.deleteQuiz(id)
}

function handleCloseSession() {
  quizStore.closeSession()
}

function handleEnd() {
  quizStore.endSession()
  confirmEnd.value = false
}

async function copyCode() {
  const code = quizStore.activeSession?.room_code
  if (!code) return
  try {
    await navigator.clipboard.writeText(code)
    copied.value = true
    setTimeout(() => (copied.value = false), 2000)
  } catch {}
}

onMounted(async () => {
  await Promise.all([
    quizStore.loadQuizzes(),
    exerciseStore.loadExercises(),
  ])
})
</script>
