<template>
  <div class="space-y-6">
    <!-- Header -->
    <div>
      <h3 class="text-2xl sm:text-3xl font-bold">Praticar</h3>
      <p class="text-text-secondary mt-1">Pratica livremente, sem limite.</p>
    </div>

    <!-- Desktop grid layout -->
    <div class="lg:grid lg:grid-cols-12 lg:gap-8 lg:items-start">

      <!-- ─── Left sidebar: Filters ──────────────────────────────────────── -->
      <div class="lg:col-span-4">
        <!-- Mobile toggle -->
        <button
          @click="showFilters = !showFilters"
          class="w-full lg:hidden flex items-center justify-between px-4 py-3 bg-surface rounded-card border border-white/10 mb-3 text-sm"
          :class="hasActiveFilters ? 'border-brand/40 text-brand' : 'text-text-secondary'"
        >
          <span class="flex items-center gap-2 font-semibold">
            <i class="pi pi-sliders-h"></i>
            Filtros
            <span
              v-if="activeFilterCount > 0"
              class="w-5 h-5 bg-brand text-white text-[10px] rounded-full flex items-center justify-center font-bold"
            >{{ activeFilterCount }}</span>
          </span>
          <i :class="showFilters ? 'pi-chevron-up' : 'pi-chevron-down'" class="pi text-xs"></i>
        </button>

        <!-- Filter panel (always visible lg+, toggleable mobile) -->
        <div :class="[showFilters ? '' : 'hidden', 'lg:block lg:sticky lg:top-6 space-y-3']">
          <div class="bg-surface rounded-card border border-white/5 p-5 space-y-4">
            <p class="text-xs font-bold text-text-secondary uppercase tracking-widest hidden lg:block">Filtros</p>

            <div class="space-y-3">
              <div>
                <label class="text-xs text-text-secondary uppercase tracking-widest mb-1.5 block font-semibold">Disciplina</label>
                <select
                  v-model="localCourseId"
                  @change="onCourseChange"
                  class="w-full bg-background rounded-btn border border-white/10 px-3 py-2 text-sm outline-none focus:border-brand"
                >
                  <option :value="null">Todas</option>
                  <option v-for="uc in feedStore.courseUnits" :key="uc.id_uc" :value="uc.id_uc">{{ uc.name }}</option>
                </select>
              </div>

              <div>
                <label class="text-xs text-text-secondary uppercase tracking-widest mb-1.5 block font-semibold">Tópico</label>
                <select
                  v-model="localTopicName"
                  :disabled="!localCourseId || topicsLoading"
                  class="w-full bg-background rounded-btn border border-white/10 px-3 py-2 text-sm outline-none focus:border-brand disabled:opacity-40"
                >
                  <option :value="null">Todos</option>
                  <option v-for="t in availableTopics" :key="t.name" :value="t.name">{{ t.name }}</option>
                </select>
              </div>

              <div>
                <label class="text-xs text-text-secondary uppercase tracking-widest mb-1.5 block font-semibold">Dificuldade</label>
                <select
                  v-model="localDifficulty"
                  class="w-full bg-background rounded-btn border border-white/10 px-3 py-2 text-sm outline-none focus:border-brand"
                >
                  <option :value="null">Todas</option>
                  <option value="Easy">Fácil</option>
                  <option value="Medium">Médio</option>
                  <option value="Hard">Difícil</option>
                </select>
              </div>

              <div>
                <label class="text-xs text-text-secondary uppercase tracking-widest mb-1.5 block font-semibold">Tipo</label>
                <select
                  v-model="localType"
                  class="w-full bg-background rounded-btn border border-white/10 px-3 py-2 text-sm outline-none focus:border-brand"
                >
                  <option :value="null">Todos</option>
                  <option value="Multiple Choice">Escolha Múltipla</option>
                  <option value="True/False">Verdadeiro/Falso</option>
                </select>
              </div>
            </div>

            <div class="flex gap-2 pt-1">
              <button
                @click="applyFilters"
                class="flex-1 py-2 bg-brand text-white rounded-btn text-sm font-semibold hover:bg-brand/80 transition-all"
              >
                Aplicar
              </button>
              <button
                v-if="hasActiveFilters"
                @click="clearFilters"
                class="px-4 py-2 border border-error/30 text-error rounded-btn text-sm hover:bg-error/10 transition-all"
              >
                Limpar
              </button>
            </div>

            <!-- Active filter chips (inside panel) -->
            <div v-if="hasActiveFilters" class="flex flex-wrap gap-1.5 pt-1 border-t border-white/5">
              <span v-if="feedStore.filterCourseId"
                class="flex items-center gap-1 text-xs px-2 py-1 rounded-chip bg-brand/10 border border-brand/30 text-brand"
              >
                {{ courseUnitName }}
                <button @click="removeFilter('course')"><i class="pi pi-times text-[9px]"></i></button>
              </span>
              <span v-if="feedStore.filterTopicName"
                class="flex items-center gap-1 text-xs px-2 py-1 rounded-chip bg-brand/10 border border-brand/30 text-brand"
              >
                {{ feedStore.filterTopicName }}
                <button @click="removeFilter('topic')"><i class="pi pi-times text-[9px]"></i></button>
              </span>
              <span v-if="feedStore.filterDifficulty"
                class="flex items-center gap-1 text-xs px-2 py-1 rounded-chip border font-medium"
                :class="difficultyChipClass"
              >
                {{ difficultyLabel }}
                <button @click="removeFilter('difficulty')"><i class="pi pi-times text-[9px]"></i></button>
              </span>
              <span v-if="feedStore.filterType"
                class="flex items-center gap-1 text-xs px-2 py-1 rounded-chip bg-surface border border-white/20 text-text-secondary"
              >
                {{ typeLabel }}
                <button @click="removeFilter('type')"><i class="pi pi-times text-[9px]"></i></button>
              </span>
            </div>
          </div>

          <!-- Exercise navigator (desktop only) -->
          <div v-if="feedStore.exercises.length > 0" class="hidden lg:block bg-surface rounded-card border border-white/5 p-5">
            <div class="flex items-center justify-between mb-3">
              <p class="text-xs font-bold text-text-secondary uppercase tracking-widest">Exercícios</p>
              <span class="text-xs text-text-secondary">{{ feedStore.currentIndex + 1 }}/{{ feedStore.exercises.length }}</span>
            </div>
            <div class="flex flex-wrap gap-1.5">
              <button
                v-for="(_, i) in Math.min(feedStore.exercises.length, 25)"
                :key="i"
                @click="jumpTo(i)"
                class="w-7 h-7 rounded-btn text-xs font-bold transition-all"
                :class="i === feedStore.currentIndex
                  ? 'bg-brand text-white'
                  : 'bg-background text-text-secondary hover:bg-white/10'"
              >{{ i + 1 }}</button>
              <span v-if="feedStore.exercises.length > 25" class="text-xs text-text-secondary self-center ml-1">
                +{{ feedStore.exercises.length - 25 }}
              </span>
            </div>
          </div>
        </div>
      </div>

      <!-- ─── Right: Exercise content ───────────────────────────────────── -->
      <div class="lg:col-span-8 mt-4 lg:mt-0">

        <!-- Loading -->
        <div v-if="feedStore.isLoading" class="flex items-center justify-center py-32">
          <div class="text-center">
            <i class="pi pi-spinner pi-spin text-brand text-4xl mb-4 block"></i>
            <p class="text-text-secondary">A carregar exercícios...</p>
          </div>
        </div>

        <!-- Empty -->
        <div v-else-if="feedStore.exercises.length === 0" class="flex items-center justify-center py-32">
          <div class="text-center">
            <i class="pi pi-inbox text-4xl text-text-secondary/40 mb-4 block"></i>
            <p class="text-text-secondary">
              {{ hasActiveFilters ? 'Nenhum exercício para estes filtros.' : 'Ainda não há exercícios disponíveis.' }}
            </p>
            <button v-if="hasActiveFilters" @click="clearFilters" class="mt-4 text-brand text-sm hover:underline">
              Limpar filtros
            </button>
          </div>
        </div>

        <!-- Exercise card -->
        <div v-else-if="feedStore.currentExercise">
          <!-- Mobile counter + dots -->
          <div class="flex items-center justify-between mb-4 text-sm text-text-secondary lg:hidden">
            <span>Exercício {{ feedStore.currentIndex + 1 }} de {{ feedStore.exercises.length }}</span>
            <div class="flex gap-1">
              <div
                v-for="(_, i) in Math.min(feedStore.exercises.length, 10)"
                :key="i"
                class="w-2 h-2 rounded-full transition-all"
                :class="i === feedStore.currentIndex ? 'bg-brand' : 'bg-white/20'"
              ></div>
              <span v-if="feedStore.exercises.length > 10" class="text-xs ml-1">...</span>
            </div>
          </div>

          <transition name="slide-fade" mode="out-in">
            <div :key="feedStore.currentExercise.id_exercise" class="space-y-4">
              <!-- Tags -->
              <div class="flex flex-wrap gap-2">
                <span
                  v-if="feedStore.currentExercise.course_unit_info?.name"
                  class="text-xs px-3 py-1 rounded-chip bg-brand/10 border border-brand/30 text-brand"
                >{{ feedStore.currentExercise.course_unit_info.name }}</span>
                <span
                  v-if="feedStore.currentExercise.topic_name"
                  class="text-xs px-3 py-1 rounded-chip bg-surface border border-white/10 text-text-secondary"
                >{{ feedStore.currentExercise.topic_name }}</span>
                <span
                  class="text-xs px-3 py-1 rounded-chip border font-medium"
                  :class="difficultyBadgeClass(feedStore.currentExercise.difficulty)"
                >{{ difficultyBadgeLabel(feedStore.currentExercise.difficulty) }}</span>
                <span class="text-xs px-3 py-1 rounded-chip bg-surface border border-white/10 text-text-secondary">
                  {{ feedStore.currentExercise.type === 'True/False' ? 'V / F' : 'Escolha Múltipla' }}
                </span>
              </div>

              <!-- Question -->
              <div class="bg-surface rounded-card border border-white/5 p-6 sm:p-8">
                <p class="text-base sm:text-lg font-medium leading-relaxed text-center">
                  {{ feedStore.currentExercise.question }}
                </p>
              </div>

              <!-- Options + Actions -->
              <div class="bg-surface rounded-card border border-white/5 p-4 sm:p-6">
                <div class="space-y-3">
                  <button
                    v-for="(option, index) in getOptions(feedStore.currentExercise)"
                    :key="index"
                    @click="!answered && selectOption(index)"
                    class="w-full flex items-center gap-3 p-4 rounded-btn border text-left transition-all"
                    :class="getOptionClass(index)"
                    :disabled="answered"
                  >
                    <span
                      class="w-7 h-7 shrink-0 rounded-btn border flex items-center justify-center text-xs font-bold transition-all"
                      :class="getOptionLabelClass(index)"
                    >{{ getOptionLabel(feedStore.currentExercise, index) }}</span>
                    <span class="text-sm leading-snug flex-1">{{ option }}</span>
                    <i v-if="answered && index === correctIndex" class="pi pi-check-circle text-success shrink-0"></i>
                    <i v-if="answered && index === selectedOption && index !== correctIndex" class="pi pi-times-circle text-error shrink-0"></i>
                  </button>
                </div>

                <div class="mt-4">
                  <!-- Confirm -->
                  <button
                    v-if="!answered"
                    @click="confirm"
                    :disabled="selectedOption === null"
                    class="w-full py-3.5 bg-brand text-white rounded-btn font-bold hover:bg-brand/80 transition-all disabled:opacity-40 disabled:cursor-not-allowed"
                  >
                    Confirmar
                  </button>

                  <!-- Feedback -->
                  <div v-else class="space-y-3">
                    <div
                      class="p-4 rounded-btn border flex items-center gap-3"
                      :class="isCorrect ? 'bg-success/10 border-success/30' : 'bg-error/10 border-error/30'"
                    >
                      <i :class="isCorrect ? 'pi pi-check-circle text-success' : 'pi pi-times-circle text-error'" class="text-lg shrink-0"></i>
                      <span class="font-bold" :class="isCorrect ? 'text-success' : 'text-error'">
                        {{ isCorrect ? 'Correto!' : 'Incorreto' }}
                      </span>
                    </div>

                    <div
                      v-if="feedStore.currentExercise.explanation"
                      class="p-4 rounded-btn border border-brand/20 bg-brand/5"
                    >
                      <div class="flex gap-2">
                        <i class="pi pi-sparkles text-brand text-sm shrink-0 mt-0.5"></i>
                        <p class="text-sm leading-relaxed">{{ feedStore.currentExercise.explanation }}</p>
                      </div>
                    </div>

                    <!-- Andy -->
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

                    <!-- Navigation -->
                    <div class="flex gap-3">
                      <button
                        @click="prevExercise"
                        :disabled="feedStore.currentIndex === 0"
                        class="flex-1 py-3 border border-white/10 rounded-btn text-sm font-semibold hover:border-white/30 transition-all disabled:opacity-30"
                      >
                        <i class="pi pi-arrow-left mr-2"></i>Anterior
                      </button>
                      <button
                        @click="nextExercise"
                        :disabled="feedStore.currentIndex === feedStore.exercises.length - 1"
                        class="flex-1 py-3 bg-brand text-white rounded-btn text-sm font-bold hover:bg-brand/80 transition-all disabled:opacity-40"
                      >
                        Próximo<i class="pi pi-arrow-right ml-2"></i>
                      </button>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Navigation without answer (mobile inline) -->
              <div v-if="!answered" class="flex justify-between text-sm text-text-secondary">
                <button
                  @click="prevExercise"
                  :disabled="feedStore.currentIndex === 0"
                  class="flex items-center gap-1 hover:text-white transition-colors disabled:opacity-30"
                >
                  <i class="pi pi-arrow-left"></i> Anterior
                </button>
                <button
                  @click="nextExercise"
                  :disabled="feedStore.currentIndex === feedStore.exercises.length - 1"
                  class="flex items-center gap-1 hover:text-white transition-colors disabled:opacity-30"
                >
                  Próximo <i class="pi pi-arrow-right"></i>
                </button>
              </div>
            </div>
          </transition>
        </div>
      </div>
    </div>

    <!-- ─── Andy Modal ─────────────────────────────────────────────────── -->
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
            <i class="pi pi-book mr-1 text-brand"></i>{{ feedStore.currentExercise?.question }}
          </p>
        </div>

        <!-- Chat messages -->
        <div ref="chatScroll" class="flex-1 overflow-y-auto p-4 space-y-3 min-h-[120px]">
          <div v-for="(msg, i) in chatHistory" :key="i">
            <div v-if="msg.role === 'andy'" class="flex items-start gap-2">
              <div class="w-6 h-6 rounded-full overflow-hidden bg-brand/10 shrink-0 mt-1">
                <img src="/chatbot.png" alt="Andy" class="w-full h-full object-cover" />
              </div>
              <div class="bg-brand/5 border border-brand/15 rounded-2xl rounded-tl-none px-4 py-3 max-w-[85%]">
                <div class="andy-md text-sm leading-relaxed" v-html="renderMd(msg.text)"></div>
              </div>
            </div>
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
import { useExerciseFeedStore } from '../stores/exerciseFeedStore'
import { http } from '../../../services/http'
import { micromark } from 'micromark'
import { gfm, gfmHtml } from 'micromark-extension-gfm'

const feedStore = useExerciseFeedStore()

const showFilters = ref(false)
const selectedOption = ref(null)
const answered = ref(false)
const isCorrect = ref(false)
const availableTopics = ref([])
const topicsLoading = ref(false)
const reportState = ref('idle') // idle | loading | done | already

const localCourseId = ref(feedStore.filterCourseId)
const localTopicName = ref(feedStore.filterTopicName)
const localDifficulty = ref(feedStore.filterDifficulty)
const localType = ref(feedStore.filterType)

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

// ─── Computed ─────────────────────────────────────────────────────────────

const hasActiveFilters = computed(() =>
  feedStore.filterCourseId !== null ||
  feedStore.filterTopicName !== null ||
  feedStore.filterDifficulty !== null ||
  feedStore.filterType !== null
)

const activeFilterCount = computed(() => {
  let n = 0
  if (feedStore.filterCourseId !== null) n++
  if (feedStore.filterTopicName !== null) n++
  if (feedStore.filterDifficulty !== null) n++
  if (feedStore.filterType !== null) n++
  return n
})

const courseUnitName = computed(() =>
  feedStore.courseUnits.find(uc => uc.id_uc === feedStore.filterCourseId)?.name || ''
)

const difficultyLabel = computed(() =>
  ({ Easy: 'Fácil', Medium: 'Médio', Hard: 'Difícil' })[feedStore.filterDifficulty] || ''
)

const typeLabel = computed(() =>
  feedStore.filterType === 'True/False' ? 'V / F' : 'Escolha Múltipla'
)

const difficultyChipClass = computed(() => ({
  Easy: 'bg-success/10 border-success/30 text-success',
  Medium: 'bg-warning/10 border-warning/30 text-warning',
  Hard: 'bg-error/10 border-error/30 text-error',
})[feedStore.filterDifficulty] || '')

const correctIndex = computed(() => {
  const ex = feedStore.currentExercise
  if (!ex) return -1
  if (ex.type === 'True/False') {
    const c = String(ex.solution?.correct ?? '').toLowerCase()
    return (c === 'a' || c === 'true' || c === '0') ? 0 : 1
  }
  const correct = ex.solution?.correct
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

// ─── Exercise change reset ────────────────────────────────────────────────

watch(() => feedStore.currentIndex, () => {
  selectedOption.value = null
  answered.value = false
  isCorrect.value = false
  chatHistory.value = []
  showTutor.value = false
  reportState.value = 'idle'
})

// ─── Exercise logic ───────────────────────────────────────────────────────

function getOptions(exercise) {
  if (exercise.type === 'True/False') return ['Verdadeiro', 'Falso']
  const opts = exercise.solution?.options || []
  return opts.map(o => {
    const s = String(o)
    if (s.length >= 3 && s[1] === ')' && s[2] === ' ') return s.substring(3)
    return s
  })
}

function getOptionLabel(exercise, index) {
  if (exercise.type === 'True/False') return index === 0 ? 'V' : 'F'
  return String.fromCharCode(65 + index)
}

function selectOption(index) { selectedOption.value = index }

function confirm() {
  if (selectedOption.value === null || answered.value) return
  answered.value = true
  isCorrect.value = selectedOption.value === correctIndex.value
  // Free practice — no XP, no progress tracking
}

function nextExercise() { feedStore.nextExercise() }
function prevExercise() { feedStore.prevExercise() }

function jumpTo(i) {
  feedStore.currentIndex = i
}

// ─── Andy chatbot ─────────────────────────────────────────────────────────

function renderMd(text) {
  if (!text) return ''
  return micromark(text, { extensions: [gfm()], htmlExtensions: [gfmHtml()] })
}

async function openTutor() {
  showTutor.value = true
  if (chatHistory.value.length === 0) {
    await _askTutor(`Explica a resposta correta para esta pergunta: "${feedStore.currentExercise?.question}"`)
  }
}

async function _askTutor(question) {
  tutorLoading.value = true
  try {
    const { data } = await http.post('/api/v1/ai-tutor/query', {
      question: question.trim(),
      exercise_id: feedStore.currentExercise?.id_exercise,
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
    await http.post(`/api/v1/students/exercises/${feedStore.currentExercise.id_exercise}/report`)
    reportState.value = 'done'
  } catch (e) {
    reportState.value = e?.response?.status === 409 ? 'already' : 'idle'
  }
}

// ─── Filters ──────────────────────────────────────────────────────────────

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

async function onCourseChange() {
  localTopicName.value = null
  availableTopics.value = []
  if (!localCourseId.value) return
  topicsLoading.value = true
  try {
    availableTopics.value = await feedStore.loadTopics(localCourseId.value)
  } finally {
    topicsLoading.value = false
  }
}

function applyFilters() {
  feedStore.applyFilters({
    courseId: localCourseId.value,
    topicName: localTopicName.value,
    difficulty: localDifficulty.value,
    type: localType.value,
  })
  showFilters.value = false
}

function clearFilters() {
  localCourseId.value = null
  localTopicName.value = null
  localDifficulty.value = null
  localType.value = null
  availableTopics.value = []
  feedStore.clearFilters()
  showFilters.value = false
}

function removeFilter(type) {
  if (type === 'course') { localCourseId.value = null; localTopicName.value = null }
  else if (type === 'topic') localTopicName.value = null
  else if (type === 'difficulty') localDifficulty.value = null
  else if (type === 'type') localType.value = null
  applyFilters()
}

onMounted(async () => {
  await Promise.all([
    feedStore.loadCourseUnits(),
    feedStore.hasLoaded ? Promise.resolve() : feedStore.loadExercises(),
  ])
})
</script>

<style scoped>
.slide-fade-enter-active, .slide-fade-leave-active { transition: all 0.2s ease; }
.slide-fade-enter-from { opacity: 0; transform: translateX(16px); }
.slide-fade-leave-to { opacity: 0; transform: translateX(-16px); }
.fade-enter-active, .fade-leave-active { transition: opacity 0.2s ease; }
.fade-enter-from, .fade-leave-to { opacity: 0; }

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
