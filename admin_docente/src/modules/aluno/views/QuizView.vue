<template>
  <div class="space-y-8">
    <div>
      <h3 class="text-2xl sm:text-3xl font-bold">Quizz ao Vivo</h3>
      <p class="text-text-secondary mt-1">Entra numa sessão de quiz ao vivo com o teu professor.</p>
    </div>

    <!-- Ecrã de entrada -->
    <div v-if="phase === 'join' || phase === 'connecting'" class="max-w-md mx-auto">
      <div class="bg-surface rounded-card border border-white/5 p-8 space-y-6">
        <div class="text-center">
          <div class="w-16 h-16 rounded-btn bg-warning/10 flex items-center justify-center mx-auto mb-4">
            <i class="pi pi-bolt text-warning text-3xl"></i>
          </div>
          <h4 class="text-xl font-bold mb-2">Código de Sessão</h4>
          <p class="text-text-secondary text-sm">Insere o código fornecido pelo teu professor para entrares no quiz.</p>
        </div>

        <div class="space-y-2">
          <label class="text-xs font-bold text-text-secondary uppercase tracking-widest block">Código do Quiz</label>
          <input
            v-model="sessionCode"
            type="text"
            placeholder="Ex: ABC123"
            class="w-full bg-background p-4 rounded-btn border border-white/10 outline-none focus:border-brand text-center text-xl font-mono font-bold tracking-widest uppercase"
            @keyup.enter="joinQuiz"
            maxlength="20"
            :disabled="phase === 'connecting'"
          />
        </div>

        <div v-if="joinError" class="bg-error/10 border border-error/20 text-error text-sm p-3 rounded-btn flex items-center gap-2">
          <i class="pi pi-exclamation-circle"></i>
          {{ joinError }}
        </div>

        <button
          @click="joinQuiz"
          :disabled="!sessionCode.trim() || phase === 'connecting'"
          class="w-full py-4 bg-brand text-white rounded-btn font-bold hover:bg-brand/80 transition-all disabled:opacity-40 flex items-center justify-center gap-2"
        >
          <i v-if="phase === 'connecting'" class="pi pi-spin pi-spinner"></i>
          <span>{{ phase === 'connecting' ? 'A ligar...' : 'Entrar no Quiz' }}</span>
        </button>
      </div>
    </div>

    <!-- Quiz em curso -->
    <div v-else class="max-w-2xl mx-auto space-y-5">
      <!-- Barra de status -->
      <div class="bg-surface rounded-card border border-white/5 p-4 flex items-center justify-between gap-4">
        <div class="flex items-center gap-3 min-w-0">
          <div class="w-2 h-2 rounded-full bg-success animate-pulse shrink-0"></div>
          <span class="text-sm font-semibold">Conectado</span>
          <span class="text-xs text-text-secondary truncate">{{ quizTitle }}</span>
        </div>
        <div class="flex items-center gap-4">
          <span class="text-sm font-bold text-warning">{{ myScore }} pts</span>
          <button @click="leaveQuiz" class="text-xs text-error hover:underline shrink-0">Sair</button>
        </div>
      </div>

      <!-- A aguardar -->
      <div v-if="phase === 'waiting'" class="bg-surface rounded-card border border-white/5 p-10 sm:p-14 text-center">
        <div class="w-16 h-16 rounded-full border-2 border-brand/30 flex items-center justify-center mx-auto mb-5">
          <i class="pi pi-clock text-brand text-2xl"></i>
        </div>
        <p class="font-bold text-lg mb-2">A aguardar o professor...</p>
        <p class="text-text-secondary text-sm">O quiz ainda não começou. Fica atento!</p>
        <div class="mt-6 inline-flex items-center gap-2 text-text-secondary text-sm bg-background px-4 py-2 rounded-chip border border-white/10">
          <i class="pi pi-users"></i>
          <span>{{ participants }} participante(s) conectado(s)</span>
        </div>
      </div>

      <!-- Pergunta ativa / respondida -->
      <div v-else-if="(phase === 'question' || phase === 'answered') && currentQuestion" class="space-y-4">
        <div class="bg-surface rounded-card border border-white/5 p-5 sm:p-8" :class="phase === 'answered' ? 'border-white/5' : 'border-brand/20'">
          <div class="flex items-center justify-between mb-6">
            <span class="text-xs text-text-secondary uppercase tracking-widest font-semibold">
              Pergunta {{ questionIndex + 1 }}<span v-if="questionTotal"> / {{ questionTotal }}</span>
            </span>
            <div
              v-if="phase === 'question' && timeLeft > 0"
              class="flex items-center gap-2 font-bold text-sm px-3 py-1 rounded-chip border"
              :class="timeLeft <= 5 ? 'text-error border-error/40 bg-error/10' : 'text-warning border-warning/40 bg-warning/10'"
            >
              <i class="pi pi-clock"></i>
              {{ timeLeft }}s
            </div>
          </div>

          <p class="text-base sm:text-lg font-medium leading-relaxed text-center mb-6">
            {{ currentQuestion.question }}
          </p>

          <div class="space-y-3">
            <button
              v-for="(option, index) in currentQuestion.options"
              :key="index"
              @click="submitAnswer(index)"
              class="w-full flex items-center gap-3 p-4 rounded-btn border text-left transition-all"
              :class="optionClass(index)"
              :disabled="phase !== 'question'"
            >
              <span
                class="w-7 h-7 shrink-0 rounded-btn border flex items-center justify-center text-xs font-bold"
                :class="optionLabelClass(index)"
              >
                {{ String.fromCharCode(65 + index) }}
              </span>
              <span class="text-sm flex-1">{{ stripPrefix(option) }}</span>
              <i v-if="phase === 'answered' && answerResult" class="pi shrink-0" :class="getAnswerIcon(index)"></i>
            </button>
          </div>
        </div>

        <!-- Feedback após resposta -->
        <div v-if="phase === 'answered'" class="bg-surface rounded-card border border-white/5 p-4">
          <div v-if="answerResult" class="flex items-center justify-between">
            <div class="flex items-center gap-3">
              <div class="w-8 h-8 rounded-full flex items-center justify-center" :class="answerResult.is_correct ? 'bg-success/20' : 'bg-error/20'">
                <i class="pi text-sm" :class="answerResult.is_correct ? 'pi-check text-success' : 'pi-times text-error'"></i>
              </div>
              <span class="font-semibold" :class="answerResult.is_correct ? 'text-success' : 'text-error'">
                {{ answerResult.is_correct ? 'Correto!' : 'Errado' }}
              </span>
            </div>
            <span v-if="answerResult.points_earned > 0" class="text-sm font-bold text-warning">+{{ answerResult.points_earned }} pts</span>
          </div>
          <p v-else class="text-text-secondary text-sm text-center animate-pulse">A aguardar resultado...</p>
          <p class="text-text-secondary text-xs text-center mt-2">A aguardar a próxima pergunta...</p>
        </div>
      </div>

      <!-- Resultados finais -->
      <div v-else-if="phase === 'results'" class="space-y-4">
        <div class="bg-surface rounded-card border border-white/5 p-8 sm:p-10 text-center">
          <i class="pi pi-trophy text-5xl text-warning mb-5 block"></i>
          <h4 class="text-2xl font-bold mb-2">Quiz Terminado!</h4>
          <p class="text-text-secondary mb-6">Obrigado por participares.</p>

          <div class="grid grid-cols-3 gap-3 max-w-sm mx-auto">
            <div class="bg-background rounded-btn p-4">
              <p class="text-2xl font-bold text-warning">{{ myScore }}</p>
              <p class="text-text-secondary text-xs mt-1">Pontos</p>
            </div>
            <div class="bg-background rounded-btn p-4">
              <p class="text-2xl font-bold text-success">{{ correctAnswers }}</p>
              <p class="text-text-secondary text-xs mt-1">Corretas</p>
            </div>
            <div class="bg-background rounded-btn p-4">
              <p class="text-2xl font-bold text-brand">{{ accuracy }}%</p>
              <p class="text-text-secondary text-xs mt-1">Precisão</p>
            </div>
          </div>
        </div>

        <!-- Leaderboard -->
        <div v-if="leaderboard.length > 0" class="bg-surface rounded-card border border-white/5 p-6">
          <h5 class="font-bold mb-4 flex items-center gap-2">
            <i class="pi pi-list text-brand"></i> Classificação
          </h5>
          <div class="space-y-2">
            <div
              v-for="entry in leaderboard"
              :key="entry.student_id"
              class="flex items-center gap-3 p-3 rounded-btn border transition-all"
              :class="entry.student_id === authStore.user?.id ? 'border-brand/40 bg-brand/5' : 'border-white/5 bg-background'"
            >
              <span
                class="w-7 h-7 shrink-0 rounded-full flex items-center justify-center text-xs font-bold"
                :class="entry.rank === 1 ? 'bg-warning/20 text-warning' : entry.rank === 2 ? 'bg-white/10 text-white' : entry.rank === 3 ? 'bg-orange-500/20 text-orange-400' : 'bg-white/5 text-text-secondary'"
              >
                {{ entry.rank }}
              </span>
              <span class="flex-1 font-medium text-sm truncate">{{ entry.student_name }}</span>
              <span class="font-bold text-sm shrink-0" :class="entry.student_id === authStore.user?.id ? 'text-brand' : 'text-text-secondary'">
                {{ entry.score }} pts
              </span>
            </div>
          </div>
        </div>

        <button @click="leaveQuiz" class="w-full py-3 bg-brand text-white rounded-btn font-bold hover:bg-brand/80 transition-all">
          Fechar
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onUnmounted } from 'vue'
import { http } from '../../../services/http'
import { useAuthStore } from '../../../stores/authStore'

const authStore = useAuthStore()

const phase = ref('join') // join | connecting | waiting | question | answered | results
const sessionCode = ref('')
const joinError = ref('')
const sessionId = ref(null)
const quizTitle = ref('')
const participants = ref(0)

const currentQuestion = ref(null)
const questionIndex = ref(0)
const questionTotal = ref(0)
const timeLeft = ref(0)
const selectedOption = ref(null)
const answerResult = ref(null)
const myScore = ref(0)
const correctAnswers = ref(0)
const totalAnswered = ref(0)
const leaderboard = ref([])

let ws = null
let timerInterval = null
let questionStartedAt = 0

const accuracy = computed(() =>
  totalAnswered.value > 0 ? Math.round((correctAnswers.value / totalAnswered.value) * 100) : 0
)

function getWsUrl(sid) {
  const protocol = location.protocol === 'https:' ? 'wss:' : 'ws:'
  return `${protocol}//${location.host}/api/v1/quizzes/ws/student/${sid}?token=${authStore.token}`
}

function stripPrefix(option) {
  return (option.length >= 2 && option[1] === ')') ? option.slice(2).trim() : option
}

function extractLetter(option, index) {
  return (option.length >= 2 && option[1] === ')') ? option[0] : String.fromCharCode(65 + index)
}

async function joinQuiz() {
  const code = sessionCode.value.trim().toUpperCase()
  if (!code || phase.value === 'connecting') return
  phase.value = 'connecting'
  joinError.value = ''

  try {
    const { data } = await http.post(`/api/v1/students/quizzes/join/${code}`)
    sessionId.value = data.id_session
    quizTitle.value = data.quiz_title || ''
    connectWs(data.id_session)
  } catch (e) {
    phase.value = 'join'
    joinError.value = e.response?.data?.detail || 'Código inválido ou sessão não encontrada.'
  }
}

function connectWs(sid) {
  const url = getWsUrl(sid)
  ws = new WebSocket(url)

  ws.onopen = () => {
    phase.value = 'waiting'
  }

  ws.onmessage = (event) => {
    try { handleMessage(JSON.parse(event.data)) } catch (_) {}
  }

  ws.onerror = () => {
    if (phase.value === 'connecting' || phase.value === 'waiting') {
      joinError.value = 'Não foi possível conectar ao quiz.'
      phase.value = 'join'
    }
    ws = null
  }

  ws.onclose = () => {
    ws = null
  }
}

function handleMessage(msg) {
  switch (msg.type) {
    case 'participants_update':
      participants.value = msg.count || 0
      break
    case 'question':
      currentQuestion.value = {
        question: msg.question,
        options: msg.options || [],
        exercise_type: msg.exercise_type,
      }
      questionIndex.value = msg.index ?? questionIndex.value
      questionTotal.value = msg.total ?? questionTotal.value
      timeLeft.value = msg.time_limit_seconds || 30
      selectedOption.value = null
      answerResult.value = null
      questionStartedAt = Date.now()
      phase.value = 'question'
      clearInterval(timerInterval)
      timerInterval = setInterval(() => {
        timeLeft.value = Math.max(0, timeLeft.value - 1)
        if (timeLeft.value === 0) {
          clearInterval(timerInterval)
          if (phase.value === 'question') {
            phase.value = 'answered'
            totalAnswered.value++
          }
        }
      }, 1000)
      break
    case 'session_ended':
      leaderboard.value = msg.leaderboard || []
      phase.value = 'results'
      clearInterval(timerInterval)
      if (ws) { ws.close(); ws = null }
      break
  }
}

async function submitAnswer(index) {
  if (phase.value !== 'question' || selectedOption.value !== null) return
  selectedOption.value = index
  phase.value = 'answered'
  totalAnswered.value++
  clearInterval(timerInterval)

  const timeTakenMs = Date.now() - questionStartedAt
  const option = currentQuestion.value?.options[index] || ''
  const letter = extractLetter(option, index)

  try {
    const { data } = await http.post(`/api/v1/students/quizzes/sessions/${sessionId.value}/answer`, {
      answer: letter,
      time_taken_ms: timeTakenMs,
    })
    answerResult.value = data
    myScore.value = data.total_score ?? myScore.value
    if (data.is_correct) correctAnswers.value++
  } catch (_) {}
}

function optionClass(index) {
  if (phase.value === 'question') {
    return 'border-white/10 hover:border-brand/40 cursor-pointer'
  }
  if (selectedOption.value === index) {
    if (!answerResult.value) return 'border-brand bg-brand/10 cursor-default'
    return answerResult.value.is_correct
      ? 'border-success bg-success/10 cursor-default'
      : 'border-error bg-error/10 cursor-default'
  }
  if (answerResult.value && !answerResult.value.is_correct) {
    const correctIdx = (answerResult.value.correct_answer || '').charCodeAt(0) - 65
    if (index === correctIdx) return 'border-success bg-success/10 cursor-default'
  }
  return 'border-white/5 opacity-40 cursor-default'
}

function optionLabelClass(index) {
  if (selectedOption.value === index) {
    if (!answerResult.value) return 'border-brand bg-brand/20 text-brand'
    return answerResult.value.is_correct
      ? 'border-success bg-success/20 text-success'
      : 'border-error bg-error/20 text-error'
  }
  if (answerResult.value && !answerResult.value.is_correct) {
    const correctIdx = (answerResult.value.correct_answer || '').charCodeAt(0) - 65
    if (index === correctIdx) return 'border-success bg-success/20 text-success'
  }
  return 'border-white/20 text-text-secondary'
}

function getAnswerIcon(index) {
  if (!answerResult.value) return ''
  if (selectedOption.value === index) {
    return answerResult.value.is_correct ? 'pi-check text-success' : 'pi-times text-error'
  }
  if (!answerResult.value.is_correct) {
    const correctIdx = (answerResult.value.correct_answer || '').charCodeAt(0) - 65
    if (index === correctIdx) return 'pi-check text-success'
  }
  return ''
}

function leaveQuiz() {
  if (ws) { ws.close(); ws = null }
  clearInterval(timerInterval)
  phase.value = 'join'
  sessionCode.value = ''
  joinError.value = ''
  sessionId.value = null
  quizTitle.value = ''
  currentQuestion.value = null
  selectedOption.value = null
  answerResult.value = null
  myScore.value = 0
  correctAnswers.value = 0
  totalAnswered.value = 0
  leaderboard.value = []
  participants.value = 0
}

onUnmounted(leaveQuiz)
</script>
