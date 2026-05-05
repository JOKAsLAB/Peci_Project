// @ts-nocheck
import { defineStore } from 'pinia'
import { ref } from 'vue'
import { http, getApiErrorMessage } from '../../../services/http'
import { useAuthStore } from '../../../stores/authStore'

export const useQuizStore = defineStore('quiz', () => {
  const quizzes = ref([])
  const isLoading = ref(false)
  const error = ref(null)
  const hasLoaded = ref(false)

  // Active session state
  const activeSession = ref(null)   // { id_session, room_code, quiz_title, phase: 'lobby'|'active'|'finished' }
  const participants = ref([])       // [{ student_id, student_name }]
  const currentQuestion = ref(null) // WS question payload
  const sessionEnded = ref(false)
  const finalLeaderboard = ref([])

  let _ws: WebSocket | null = null

  // ------------------------------------------------------------------
  // Quiz CRUD
  // ------------------------------------------------------------------

  async function loadQuizzes(force = false) {
    if (hasLoaded.value && !force) return
    isLoading.value = true
    error.value = null
    try {
      const { data } = await http.get('/api/v1/professors/quizzes')
      quizzes.value = data
      hasLoaded.value = true
    } catch (e) {
      error.value = getApiErrorMessage(e, 'Erro ao carregar quizzes.')
    } finally {
      isLoading.value = false
    }
  }

  async function createQuiz(payload) {
    isLoading.value = true
    error.value = null
    try {
      const { data } = await http.post('/api/v1/professors/quizzes', payload)
      quizzes.value.unshift(data)
      return data
    } catch (e) {
      error.value = getApiErrorMessage(e, 'Erro ao criar quiz.')
      throw e
    } finally {
      isLoading.value = false
    }
  }

  async function deleteQuiz(id: string) {
    try {
      await http.delete(`/api/v1/professors/quizzes/${id}`)
      quizzes.value = quizzes.value.filter((q) => q.id_quiz !== id)
    } catch (e) {
      error.value = getApiErrorMessage(e, 'Erro ao apagar quiz.')
    }
  }

  // ------------------------------------------------------------------
  // Session
  // ------------------------------------------------------------------

  async function openSession(quizId: string) {
    isLoading.value = true
    error.value = null
    try {
      const { data } = await http.post(`/api/v1/professors/quizzes/${quizId}/sessions`)
      activeSession.value = { ...data, phase: 'lobby' }
      participants.value = []
      currentQuestion.value = null
      sessionEnded.value = false
      finalLeaderboard.value = []
      return data
    } catch (e) {
      error.value = getApiErrorMessage(e, 'Erro ao abrir sessão.')
      throw e
    } finally {
      isLoading.value = false
    }
  }

  function connectWs(sessionId: string) {
    const authStore = useAuthStore()
    const rawBase = (import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:8000').replace(/\/$/, '')
    const wsBase = rawBase.replace(/^https/, 'wss').replace(/^http/, 'ws')
    const url = `${wsBase}/api/v1/quizzes/ws/professor/${sessionId}?token=${authStore.token || ''}`

    _ws = new WebSocket(url)

    _ws.onmessage = (ev) => {
      try {
        const msg = JSON.parse(ev.data)
        if (msg.type === 'joined') {
          participants.value.push({ student_id: msg.student_id, student_name: msg.student_name })
        } else if (msg.type === 'session_started') {
          if (activeSession.value) activeSession.value.phase = 'active'
          currentQuestion.value = msg
        } else if (msg.type === 'question') {
          currentQuestion.value = msg
        } else if (msg.type === 'session_ended') {
          finalLeaderboard.value = msg.leaderboard || []
          sessionEnded.value = true
          if (activeSession.value) activeSession.value.phase = 'finished'
          _ws?.close()
        }
      } catch (e) {
        console.error('[QuizWS] parse error', e)
      }
    }

    _ws.onerror = (e) => console.error('[QuizWS] error', e)
    _ws.onclose = () => { _ws = null }
  }

  function _send(type: string) {
    if (_ws?.readyState === WebSocket.OPEN) {
      _ws.send(JSON.stringify({ type }))
    }
  }

  function startSession() { _send('start') }
  function nextQuestion() { _send('next') }
  function endSession()   { _send('end') }

  function closeSession() {
    _ws?.close()
    _ws = null
    activeSession.value = null
    participants.value = []
    currentQuestion.value = null
    sessionEnded.value = false
    finalLeaderboard.value = []
  }

  return {
    quizzes, isLoading, error, hasLoaded,
    activeSession, participants, currentQuestion, sessionEnded, finalLeaderboard,
    loadQuizzes, createQuiz, deleteQuiz,
    openSession, connectWs, startSession, nextQuestion, endSession, closeSession,
  }
})
