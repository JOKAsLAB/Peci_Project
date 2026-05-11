<template>
  <div class="space-y-8">
    <!-- Header -->
    <div>
      <h3 class="text-2xl sm:text-3xl font-bold">Percursos</h3>
      <p class="text-text-secondary mt-1">Resolve os exercícios e ganha XP.</p>
    </div>

    <!-- Loading inicial -->
    <div v-if="pathStore.isLoading && !pathStore.hasLoaded" class="flex items-center justify-center py-20">
      <i class="pi pi-spinner pi-spin text-brand text-4xl"></i>
    </div>

    <!-- Empty -->
    <div v-else-if="pathStore.paths.length === 0" class="bg-surface rounded-card border border-white/5 p-12 text-center">
      <i class="pi pi-map text-4xl text-text-secondary/40 mb-4 block"></i>
      <p class="text-text-secondary">Nenhum percurso disponível de momento.</p>
    </div>

    <!-- Main -->
    <div v-else class="grid grid-cols-12 gap-4 sm:gap-6">

      <!-- ─── Left: path tabs + checkpoint list ──────────────────────────── -->
      <div class="col-span-12 lg:col-span-5">

        <!-- Path tabs -->
        <div class="flex gap-2 flex-wrap mb-4">
          <button
            v-for="path in pathStore.paths"
            :key="path.id_uc"
            @click="selectPath(path.id_uc)"
            :class="selectedPathId === path.id_uc
              ? 'bg-brand text-white'
              : 'bg-surface text-text-secondary border border-white/10 hover:border-brand/30'"
            class="px-4 py-2 rounded-chip text-sm font-bold transition-all flex items-center gap-2"
          >
            <span>{{ path.name }}</span>
            <span class="text-xs opacity-60">{{ path.total_topics }} tópicos</span>
          </button>
        </div>

        <!-- Loading path details -->
        <div v-if="loadingPath" class="flex justify-center py-12">
          <i class="pi pi-spinner pi-spin text-brand text-2xl"></i>
        </div>

        <!-- Checkpoint list -->
        <div v-else-if="currentCheckpoints.length" class="bg-surface rounded-card border border-white/5 p-3 sm:p-5">
          <p class="text-xs font-bold text-text-secondary uppercase tracking-widest mb-4">Tópicos</p>
          <div>
            <div v-for="(cp, idx) in currentCheckpoints" :key="cp.topic_name" class="relative">
              <!-- Connector line -->
              <div v-if="idx > 0" class="flex justify-center">
                <div class="w-0.5 h-6"
                  :class="cp.is_locked ? 'bg-white/10' : cp.is_completed ? 'bg-success/50' : 'bg-brand/50'"
                ></div>
              </div>

              <!-- Checkpoint card -->
              <div
                @click="selectCheckpoint(cp)"
                class="p-3 rounded-card border transition-all"
                :class="[
                  cp.is_locked
                    ? 'opacity-40 cursor-not-allowed border-white/5 bg-background'
                    : selectedCheckpointName === cp.topic_name
                      ? 'bg-brand/10 border-brand cursor-pointer shadow-lg shadow-brand/10'
                      : 'bg-background border-white/10 hover:border-brand/30 cursor-pointer',
                  idx % 2 !== 0 ? 'ml-4 sm:ml-8' : ''
                ]"
              >
                <div class="flex items-center gap-3">
                  <div
                    class="w-10 h-10 rounded-full flex items-center justify-center shrink-0 font-bold text-sm shadow-md"
                    :class="cp.is_completed
                      ? 'bg-success text-white'
                      : cp.is_locked
                        ? 'bg-white/10 text-text-secondary'
                        : 'bg-brand text-white'"
                  >
                    <i v-if="cp.is_completed" class="pi pi-check"></i>
                    <i v-else-if="cp.is_locked" class="pi pi-lock text-xs"></i>
                    <span v-else>{{ cp.topic_order }}</span>
                  </div>
                  <div class="flex-1 min-w-0">
                    <p class="font-semibold text-sm truncate">{{ cp.topic_name }}</p>
                    <p class="text-xs text-text-secondary mt-0.5">
                      {{ cp.attempted_count }}/{{ cp.total_count }} exercícios
                      <span v-if="cp.attempted_count > 0" class="ml-1">· {{ correctPct(cp) }}% corretos</span>
                    </p>
                  </div>
                  <i v-if="cp.is_completed" class="pi pi-check-circle text-success text-sm shrink-0"></i>
                </div>
                <div class="mt-2 h-1 bg-background rounded-full overflow-hidden">
                  <div
                    class="h-full rounded-full transition-all"
                    :class="cp.is_completed ? 'bg-success' : 'bg-brand'"
                    :style="{ width: topicProgress(cp) + '%' }"
                  ></div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- ─── Right: exercise solver ──────────────────────────────────────── -->
      <div class="col-span-12 lg:col-span-7">

        <!-- No checkpoint selected -->
        <div v-if="!selectedCheckpointName"
          class="bg-surface rounded-card border border-white/5 border-dashed p-12 text-center"
        >
          <i class="pi pi-arrow-left text-3xl text-brand/30 mb-3 block lg:hidden"></i>
          <i class="pi pi-arrow-circle-left text-3xl text-brand/30 mb-3 hidden lg:block"></i>
          <p class="text-text-secondary text-sm">Seleciona um tópico para começar.</p>
        </div>

        <!-- Checkpoint completed -->
        <div v-else-if="checkpointComplete"
          class="bg-surface rounded-card border border-white/5 p-8 text-center space-y-5"
        >
          <div class="w-20 h-20 bg-success/10 rounded-full flex items-center justify-center mx-auto">
            <i class="pi pi-trophy text-success text-4xl"></i>
          </div>
          <div>
            <h4 class="text-xl font-bold mb-1">Tópico Concluído!</h4>
            <p class="text-text-secondary text-sm">{{ selectedCheckpointName }}</p>
          </div>
          <div class="grid grid-cols-3 gap-3">
            <div class="bg-background rounded-card p-3 border border-white/5">
              <p class="text-2xl font-bold text-success">{{ sessionCorrect }}</p>
              <p class="text-xs text-text-secondary mt-0.5">Corretas</p>
            </div>
            <div class="bg-background rounded-card p-3 border border-white/5">
              <p class="text-2xl font-bold">{{ sessionTotal }}</p>
              <p class="text-xs text-text-secondary mt-0.5">Total</p>
            </div>
            <div class="bg-background rounded-card p-3 border border-white/5">
              <p class="text-2xl font-bold text-warning">+{{ sessionXP }}</p>
              <p class="text-xs text-text-secondary mt-0.5">XP</p>
            </div>
          </div>
          <div class="flex gap-3 justify-center flex-wrap">
            <button
              v-if="nextCheckpointData"
              @click="goToNextCheckpoint"
              class="px-6 py-3 bg-brand text-white rounded-btn font-bold hover:bg-brand/80 transition-all"
            >
              Próximo Tópico <i class="pi pi-arrow-right ml-2"></i>
            </button>
            <button
              @click="selectedCheckpointName = null; checkpointComplete = false"
              class="px-6 py-3 border border-white/10 rounded-btn font-semibold hover:border-white/30 transition-all text-sm"
            >
              Ver Percurso
            </button>
          </div>
        </div>

        <!-- No exercises in checkpoint -->
        <div v-else-if="!checkpointExercises.length"
          class="bg-surface rounded-card border border-white/5 border-dashed p-12 text-center"
        >
          <i class="pi pi-inbox text-3xl text-text-secondary/40 mb-3 block"></i>
          <p class="text-text-secondary text-sm">Sem exercícios neste tópico.</p>
        </div>

        <!-- Exercise solver -->
        <div v-else class="space-y-4">
          <!-- Header -->
          <div class="flex items-center justify-between">
            <span class="font-semibold text-sm truncate pr-4">{{ selectedCheckpointName }}</span>
            <span class="text-sm text-text-secondary shrink-0">{{ exerciseIndex + 1 }}/{{ checkpointExercises.length }}</span>
          </div>

          <!-- Progress bar + bonus badge -->
          <div class="flex items-center gap-3">
            <div class="flex-1 h-1.5 bg-surface rounded-full overflow-hidden">
              <div
                class="h-full bg-brand rounded-full transition-all duration-500"
                :style="{ width: ((exerciseIndex + (answered ? 1 : 0)) / checkpointExercises.length * 100) + '%' }"
              ></div>
            </div>
            <span
              v-if="bonusActive"
              class="shrink-0 text-[10px] font-bold px-2 py-0.5 rounded-chip bg-orange-500/15 border border-orange-500/30 text-orange-400 flex items-center gap-1"
            >
              <i class="pi pi-star-fill" style="font-size:9px"></i> Bónus 1.5×
            </span>
          </div>

          <transition name="slide-fade" mode="out-in">
            <div :key="currentExercise?.id_exercise || exerciseIndex" class="space-y-4">
              <!-- Tags -->
              <div class="flex flex-wrap gap-2">
                <span
                  class="text-xs px-3 py-1 rounded-chip border font-medium"
                  :class="difficultyBadgeClass(currentExercise?.difficulty)"
                >{{ difficultyBadgeLabel(currentExercise?.difficulty) }}</span>
                <span class="text-xs px-3 py-1 rounded-chip bg-surface border border-white/10 text-text-secondary">
                  {{ currentExercise?.type === 'True/False' ? 'V / F' : 'Escolha Múltipla' }}
                </span>
              </div>

              <!-- Question -->
              <div class="bg-surface rounded-card border border-white/5 p-6 sm:p-8">
                <p class="text-base sm:text-lg font-medium leading-relaxed text-center">
                  {{ currentExercise?.question }}
                </p>
              </div>

              <!-- Options + Actions -->
              <div class="bg-surface rounded-card border border-white/5 p-3 sm:p-5">
                <div class="space-y-2 sm:space-y-3">
                  <button
                    v-for="(option, index) in getOptions(currentExercise)"
                    :key="index"
                    @click="!answered && selectOption(index)"
                    class="w-full flex items-center gap-3 p-4 rounded-btn border text-left transition-all"
                    :class="getOptionClass(index)"
                    :disabled="answered"
                  >
                    <span
                      class="w-7 h-7 shrink-0 rounded-btn border flex items-center justify-center text-xs font-bold transition-all"
                      :class="getOptionLabelClass(index)"
                    >{{ getOptionLabel(currentExercise, index) }}</span>
                    <span class="text-sm leading-snug flex-1">{{ option }}</span>
                    <i v-if="answered && index === correctIndex" class="pi pi-check-circle text-success shrink-0"></i>
                    <i v-if="answered && index === selectedOption && index !== correctIndex" class="pi pi-times-circle text-error shrink-0"></i>
                  </button>
                </div>

                <div class="mt-4 space-y-3">
                  <!-- Confirm -->
                  <button
                    v-if="!answered"
                    @click="confirm"
                    :disabled="selectedOption === null"
                    class="w-full py-3.5 bg-brand text-white rounded-btn font-bold hover:bg-brand/80 transition-all disabled:opacity-40 disabled:cursor-not-allowed"
                  >
                    Confirmar
                  </button>

                  <template v-else>
                    <!-- Result -->
                    <div
                      class="p-4 rounded-btn border flex items-center gap-3"
                      :class="isCorrect ? 'bg-success/10 border-success/30' : 'bg-error/10 border-error/30'"
                    >
                      <i :class="isCorrect ? 'pi pi-check-circle text-success' : 'pi pi-times-circle text-error'" class="text-lg shrink-0"></i>
                      <div class="flex-1">
                        <span class="font-bold" :class="isCorrect ? 'text-success' : 'text-error'">
                          {{ isCorrect ? 'Correto!' : 'Incorreto' }}
                        </span>
                        <span v-if="lastXPGained > 0" class="ml-3 text-sm font-semibold flex items-center gap-1">
                          <span class="text-success">+{{ lastXPGained }} XP</span>
                          <span v-if="lastWasBonus" class="text-orange-400 text-xs">(bónus 1.5×)</span>
                        </span>
                      </div>
                    </div>

                    <!-- Explanation -->
                    <div v-if="currentExercise?.explanation" class="p-4 rounded-btn border border-brand/20 bg-brand/5">
                      <div class="flex gap-2">
                        <i class="pi pi-sparkles text-brand text-sm shrink-0 mt-0.5"></i>
                        <p class="text-sm leading-relaxed">{{ currentExercise.explanation }}</p>
                      </div>
                    </div>

                    <!-- Andy button -->
                    <button
                      @click="openTutor"
                      class="w-full py-3 flex items-center justify-center gap-2 bg-brand/10 border border-brand/20 text-brand rounded-btn text-sm font-semibold hover:bg-brand/20 transition-all"
                    >
                      <img src="/chatbot.png" alt="Andy" class="w-4 h-4 object-contain" />
                      Pedir explicação ao Andy
                    </button>

                    <!-- Report -->
                    <button
                      @click="reportExercise"
                      :disabled="reportState === 'loading' || reportState === 'done' || reportState === 'already'"
                      class="w-full py-3 flex items-center justify-center gap-2 rounded-btn text-sm font-semibold transition-all border"
                      :class="reportState === 'done'
                        ? 'bg-success/10 border-success/20 text-success cursor-default'
                        : reportState === 'already'
                          ? 'bg-surface border-white/10 text-text-secondary cursor-default'
                          : 'bg-error/5 border-error/20 text-error hover:bg-error/10'"
                    >
                      <i class="pi" :class="reportState === 'done' ? 'pi-check-circle' : reportState === 'already' ? 'pi-info-circle' : 'pi-flag'"></i>
                      {{ reportState === 'done' ? 'Exercício reportado' : reportState === 'already' ? 'Já reportaste este exercício' : 'Reportar problema' }}
                    </button>

                    <!-- Next / Finish -->
                    <button
                      @click="nextExercise"
                      class="w-full py-3.5 bg-brand text-white rounded-btn font-bold hover:bg-brand/80 transition-all"
                    >
                      {{ exerciseIndex < checkpointExercises.length - 1 ? 'Próximo' : 'Concluir Tópico' }}
                      <i class="pi pi-arrow-right ml-2"></i>
                    </button>
                  </template>
                </div>
              </div>
            </div>
          </transition>
        </div>
      </div>
    </div>

    <!-- ─── Andy Modal ────────────────────────────────────────────────────── -->
    <div v-if="showTutor" class="fixed inset-0 z-50 flex items-end sm:items-center justify-center">
      <div class="absolute inset-0 bg-black/60 backdrop-blur-sm" @click="closeTutor"></div>
      <div class="relative bg-surface border border-white/10 rounded-t-2xl sm:rounded-card w-full max-w-lg shadow-2xl z-10 max-h-[85vh] flex flex-col overflow-hidden">
        <!-- Header -->
        <div class="flex items-center justify-between p-4 border-b border-white/10 shrink-0">
          <div class="flex items-center gap-3">
            <div class="w-8 h-8 rounded-full overflow-hidden bg-brand/10 shrink-0">
              <img src="/chatbot.png" alt="Andy" class="w-full h-full object-cover" />
            </div>
            <div>
              <p class="font-bold text-sm">Andy</p>
              <p class="text-text-secondary text-xs">Assistente IA</p>
            </div>
          </div>
          <button @click="closeTutor" class="text-text-secondary hover:text-white transition-colors p-1">
            <i class="pi pi-times"></i>
          </button>
        </div>

        <!-- Exercise context -->
        <div class="px-4 py-2.5 bg-background/40 border-b border-white/5 shrink-0">
          <p class="text-xs text-text-secondary line-clamp-2">
            <i class="pi pi-book mr-1 text-brand"></i>{{ currentExercise?.question }}
          </p>
        </div>

        <!-- Chat messages -->
        <div ref="chatScroll" class="flex-1 overflow-y-auto p-4 space-y-3 min-h-[120px]">
          <div v-for="(msg, i) in chatHistory" :key="i">
            <!-- Andy bubble (left) -->
            <div v-if="msg.role === 'andy'" class="flex items-start gap-2">
              <div class="w-6 h-6 rounded-full overflow-hidden bg-brand/10 shrink-0 mt-1">
                <img src="/chatbot.png" alt="Andy" class="w-full h-full object-cover" />
              </div>
              <div class="bg-brand/5 border border-brand/15 rounded-2xl rounded-tl-none px-4 py-3 max-w-[85%]">
                <div class="andy-md text-sm leading-relaxed" v-html="renderMd(msg.text)"></div>
              </div>
            </div>
            <!-- User bubble (right) -->
            <div v-else class="flex justify-end">
              <div class="bg-white/10 rounded-2xl rounded-tr-none px-4 py-3 max-w-[85%]">
                <p class="text-sm">{{ msg.text }}</p>
              </div>
            </div>
          </div>

          <!-- Typing indicator -->
          <div v-if="tutorLoading" class="flex items-start gap-2">
            <div class="w-6 h-6 bg-brand/10 rounded-full flex items-center justify-center shrink-0 mt-1">
              <i class="pi pi-android text-brand" style="font-size:10px"></i>
            </div>
            <div class="bg-brand/5 border border-brand/15 rounded-2xl rounded-tl-none px-4 py-3">
              <div class="flex gap-1.5 items-center h-4">
                <div class="w-1.5 h-1.5 bg-brand/60 rounded-full animate-bounce" style="animation-delay:0ms"></div>
                <div class="w-1.5 h-1.5 bg-brand/60 rounded-full animate-bounce" style="animation-delay:150ms"></div>
                <div class="w-1.5 h-1.5 bg-brand/60 rounded-full animate-bounce" style="animation-delay:300ms"></div>
              </div>
            </div>
          </div>
        </div>

        <!-- Input -->
        <div class="p-4 border-t border-white/10 flex gap-2 shrink-0">
          <input
            v-model="tutorInput"
            @keyup.enter="sendTutor"
            placeholder="Pergunta algo ao Andy..."
            class="flex-1 bg-background border border-white/10 rounded-2xl px-4 py-2.5 text-sm outline-none focus:border-brand transition-colors"
          />
          <button
            @click="sendTutor"
            :disabled="!tutorInput.trim() || tutorLoading"
            class="w-10 h-10 bg-brand text-white rounded-full flex items-center justify-center disabled:opacity-40 hover:bg-brand/80 transition-all shrink-0"
          >
            <i class="pi pi-send text-sm"></i>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted, nextTick } from 'vue'
import { usePathStudentStore } from '../stores/pathStudentStore'
import { useStudentStore } from '../stores/studentStore'
import { http } from '../../../services/http'
import { micromark } from 'micromark'
import { gfm, gfmHtml } from 'micromark-extension-gfm'

const pathStore = usePathStudentStore()
const studentStore = useStudentStore()

// ─── Path / Checkpoint selection ─────────────────────────────────────────

const selectedPathId = ref(null)
const selectedCheckpointName = ref(null)
const loadingPath = ref(false)
const reportState = ref('idle') // idle | loading | done | already

const currentCheckpoints = computed(() => pathStore.selectedPath?.checkpoints || [])

const selectedCheckpointData = computed(() =>
  currentCheckpoints.value.find(c => c.topic_name === selectedCheckpointName.value)
)

const checkpointExercises = computed(() => {
  const session = pathStore.practiceSession
  // Se a practice-session é para este tópico, usa os exercícios filtrados (sem repetidos)
  if (
    session?.current_topic?.name === selectedCheckpointName.value &&
    Array.isArray(session.exercises) &&
    session.exercises.length > 0
  ) {
    return session.exercises
  }
  return selectedCheckpointData.value?.exercises || []
})

const nextCheckpointData = computed(() => {
  if (!selectedCheckpointName.value) return null
  const idx = currentCheckpoints.value.findIndex(c => c.topic_name === selectedCheckpointName.value)
  return currentCheckpoints.value.slice(idx + 1).find(c => !c.is_locked) || null
})

async function selectPath(id_uc) {
  if (selectedPathId.value === id_uc && pathStore.selectedPath?.id_uc === id_uc) return
  selectedPathId.value = id_uc
  selectedCheckpointName.value = null
  checkpointComplete.value = false
  loadingPath.value = true
  await Promise.all([
    pathStore.loadPath(id_uc),
    pathStore.loadPracticeSession(id_uc),
  ])
  loadingPath.value = false
}

function selectCheckpoint(cp) {
  if (cp.is_locked) return
  selectedCheckpointName.value = cp.topic_name
  exerciseIndex.value = 0
  selectedOption.value = null
  answered.value = false
  isCorrect.value = false
  lastXPGained.value = 0
  checkpointComplete.value = false
  sessionCorrect.value = 0
  sessionTotal.value = 0
  sessionXP.value = 0
  showTutor.value = false
  chatHistory.value = []
  reportState.value = 'idle'
}

function goToNextCheckpoint() {
  if (nextCheckpointData.value) selectCheckpoint(nextCheckpointData.value)
}

// ─── Exercise solving ─────────────────────────────────────────────────────

const exerciseIndex = ref(0)
const selectedOption = ref(null)
const answered = ref(false)
const isCorrect = ref(false)
const lastXPGained = ref(0)
const lastWasBonus = ref(false)
const checkpointComplete = ref(false)
const sessionCorrect = ref(0)
const sessionTotal = ref(0)
const sessionXP = ref(0)

const currentExercise = computed(() => checkpointExercises.value[exerciseIndex.value] || null)

const correctIndex = computed(() => {
  const ex = currentExercise.value
  if (!ex) return -1
  const solution = ex.solution || {}
  if (ex.type === 'True/False') {
    const c = String(solution.correct ?? '').toLowerCase()
    return (c === 'a' || c === 'true' || c === '0') ? 0 : 1
  }
  const correct = solution.correct
  if (typeof correct === 'number') return correct
  if (typeof correct === 'string') {
    const asNum = parseInt(correct, 10)
    if (!isNaN(asNum)) return asNum
    if (correct.length === 1) {
      const code = correct.toUpperCase().charCodeAt(0)
      if (code >= 65 && code <= 90) return code - 65
    }
  }
  return -1
})

function selectOption(index) { selectedOption.value = index }

const bonusActive = computed(() => {
  const done = studentStore.dailyStatus?.done_today ?? 0
  const limit = studentStore.dailyStatus?.daily_limit ?? 5
  return done < limit
})

async function confirm() {
  if (selectedOption.value === null || answered.value) return
  answered.value = true
  isCorrect.value = selectedOption.value === correctIndex.value

  const ex = currentExercise.value
  const baseXP = ex.difficulty === 'Easy' ? 10 : ex.difficulty === 'Medium' ? 20 : 35
  const xp = isCorrect.value ? (bonusActive.value ? Math.round(baseXP * 1.5) : baseXP) : 0
  lastXPGained.value = xp
  lastWasBonus.value = isCorrect.value && bonusActive.value
  sessionTotal.value++
  if (isCorrect.value) sessionCorrect.value++
  sessionXP.value += xp

  try {
    await studentStore.submitProgress(ex.id_exercise, isCorrect.value, xp)
  } catch (_) {}
}

function nextExercise() {
  if (exerciseIndex.value < checkpointExercises.value.length - 1) {
    exerciseIndex.value++
    selectedOption.value = null
    answered.value = false
    isCorrect.value = false
    lastXPGained.value = 0
    lastWasBonus.value = false
    showTutor.value = false
    chatHistory.value = []
    reportState.value = 'idle'
  } else {
    checkpointComplete.value = true
    Promise.all([
      pathStore.loadPath(selectedPathId.value),
      pathStore.loadPracticeSession(selectedPathId.value),
    ])
  }
}

// ─── Andy tutor ──────────────────────────────────────────────────────────

const showTutor = ref(false)
const tutorLoading = ref(false)
const tutorInput = ref('')
const chatHistory = ref([])
const chatScroll = ref(null)

watch(chatHistory, async () => {
  await nextTick()
  if (chatScroll.value) chatScroll.value.scrollTop = chatScroll.value.scrollHeight
}, { deep: true })

function renderMd(text) {
  if (!text) return ''
  return micromark(text, { extensions: [gfm()], htmlExtensions: [gfmHtml()] })
}

async function openTutor() {
  showTutor.value = true
  if (chatHistory.value.length === 0) {
    await _askTutor(`Explica a resposta correta para esta pergunta: "${currentExercise.value?.question}"`)
  }
}

async function _askTutor(question) {
  tutorLoading.value = true
  try {
    const { data } = await http.post('/api/v1/ai-tutor/query', {
      question: question.trim(),
      exercise_id: currentExercise.value?.id_exercise,
    })
    chatHistory.value.push({ role: 'andy', text: data.answer || data.response || 'Sem resposta.' })
  } catch {
    chatHistory.value.push({ role: 'andy', text: 'Erro ao contactar o Andy. Tenta novamente.' })
  } finally {
    tutorLoading.value = false
  }
}

async function sendTutor() {
  const q = tutorInput.value.trim()
  if (!q || tutorLoading.value) return
  chatHistory.value.push({ role: 'user', text: q })
  tutorInput.value = ''
  await _askTutor(q)
}

function closeTutor() { showTutor.value = false }

async function reportExercise() {
  if (reportState.value !== 'idle') return
  reportState.value = 'loading'
  try {
    await http.post(`/api/v1/students/exercises/${currentExercise.value?.id_exercise}/report`)
    reportState.value = 'done'
  } catch (e) {
    reportState.value = e?.response?.status === 409 ? 'already' : 'idle'
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────

function getOptions(exercise) {
  if (!exercise) return []
  if (exercise.type === 'True/False') return ['Verdadeiro', 'Falso']
  const opts = exercise.solution?.options || []
  return opts.map(o => {
    const s = String(o)
    if (s.length >= 3 && s[1] === ')' && s[2] === ' ') return s.substring(3)
    return s
  })
}

function getOptionLabel(exercise, index) {
  if (exercise?.type === 'True/False') return index === 0 ? 'V' : 'F'
  return String.fromCharCode(65 + index)
}

function getOptionClass(index) {
  if (!answered.value) {
    return index === selectedOption.value
      ? 'border-brand bg-brand/10 text-brand cursor-pointer'
      : 'border-white/10 hover:border-white/30 text-text-primary cursor-pointer'
  }
  if (index === correctIndex.value) return 'border-success bg-success/10 text-success cursor-default'
  if (index === selectedOption.value) return 'border-error bg-error/10 text-error cursor-default'
  return 'border-white/5 text-text-secondary/50 cursor-default'
}

function getOptionLabelClass(index) {
  if (!answered.value) {
    return index === selectedOption.value
      ? 'border-brand bg-brand/20 text-brand'
      : 'border-white/20 text-text-secondary'
  }
  if (index === correctIndex.value) return 'border-success bg-success/20 text-success'
  if (index === selectedOption.value) return 'border-error bg-error/20 text-error'
  return 'border-white/10 text-text-secondary'
}

function difficultyBadgeClass(d) {
  return ({
    Easy: 'bg-success/10 border-success/30 text-success',
    Medium: 'bg-warning/10 border-warning/30 text-warning',
    Hard: 'bg-error/10 border-error/30 text-error',
  })[d] || 'bg-surface border-white/10 text-text-secondary'
}

function difficultyBadgeLabel(d) {
  return ({ Easy: 'Fácil', Medium: 'Médio', Hard: 'Difícil' })[d] || d
}

function topicProgress(cp) {
  if (!cp.total_count) return 0
  return Math.round((cp.attempted_count / cp.total_count) * 100)
}

function correctPct(cp) {
  if (!cp.attempted_count) return 0
  return Math.round((cp.correct_count / cp.attempted_count) * 100)
}

// ─── Mount ────────────────────────────────────────────────────────────────

onMounted(async () => {
  await Promise.all([
    pathStore.loadPaths(),
    studentStore.loadDailyStatus(),
  ])
  if (pathStore.paths.length > 0) {
    await selectPath(pathStore.paths[0].id_uc)
  }
})
</script>

<style scoped>
.slide-fade-enter-active, .slide-fade-leave-active { transition: all 0.2s ease; }
.slide-fade-enter-from { opacity: 0; transform: translateX(16px); }
.slide-fade-leave-to { opacity: 0; transform: translateX(-16px); }

.andy-md :deep(p) { margin: 4px 0; }
.andy-md :deep(p:first-child) { margin-top: 0; }
.andy-md :deep(p:last-child) { margin-bottom: 0; }
.andy-md :deep(h1), .andy-md :deep(h2), .andy-md :deep(h3) { font-weight: 700; margin: 10px 0 4px; }
.andy-md :deep(h1) { font-size: 15px; }
.andy-md :deep(h2) { font-size: 14px; }
.andy-md :deep(h3) { font-size: 13px; }
.andy-md :deep(ul) { list-style-type: disc; padding-left: 18px; margin: 4px 0; }
.andy-md :deep(ol) { list-style-type: decimal; padding-left: 18px; margin: 4px 0; }
.andy-md :deep(li) { margin: 2px 0; }
.andy-md :deep(code) { background: rgba(0,0,0,0.35); padding: 1px 6px; border-radius: 4px; font-size: 12px; font-family: monospace; }
.andy-md :deep(pre) { background: rgba(0,0,0,0.35); border-radius: 6px; padding: 10px; font-size: 12px; overflow-x: auto; margin: 8px 0; font-family: monospace; white-space: pre-wrap; }
.andy-md :deep(pre code) { background: transparent; padding: 0; }
.andy-md :deep(table) { width: 100%; border-collapse: collapse; font-size: 12px; margin: 8px 0; }
.andy-md :deep(th) { background: rgba(0,0,0,0.3); padding: 6px 10px; text-align: left; font-weight: 600; border: 1px solid rgba(255,255,255,0.12); }
.andy-md :deep(td) { padding: 5px 10px; border: 1px solid rgba(255,255,255,0.08); }
.andy-md :deep(tr:nth-child(even) td) { background: rgba(255,255,255,0.03); }
.andy-md :deep(strong) { font-weight: 700; }
.andy-md :deep(em) { font-style: italic; }
.andy-md :deep(blockquote) { border-left: 3px solid rgba(255,255,255,0.2); padding-left: 10px; margin: 6px 0; color: rgba(255,255,255,0.6); }
</style>
