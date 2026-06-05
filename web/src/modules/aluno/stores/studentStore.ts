// @ts-nocheck
import { defineStore } from 'pinia'
import { ref } from 'vue'
import { getApiErrorMessage, http } from '../../../services/http'

export const useStudentStore = defineStore('student', () => {
  const profile = ref(null)
  const courseUnits = ref([])
  const topicStats = ref([])
  const dailyStatus = ref(null)
  const isLoading = ref(false)
  const error = ref(null)

  async function loadProfile() {
    isLoading.value = true
    error.value = null
    try {
      const { data } = await http.get('/api/v1/students/me')
      profile.value = data
    } catch (e) {
      error.value = getApiErrorMessage(e, 'Erro ao carregar perfil.')
    } finally {
      isLoading.value = false
    }
  }

  async function loadCourseUnits() {
    try {
      const { data } = await http.get('/api/v1/students/course-units')
      courseUnits.value = data
    } catch (e) {}
  }

  async function loadTopicStats() {
    try {
      const { data } = await http.get('/api/v1/students/stats/topics')
      topicStats.value = data
    } catch (e) {}
  }

  async function loadDailyStatus() {
    try {
      const { data } = await http.get('/api/v1/students/daily-status')
      dailyStatus.value = data
    } catch (e) {}
  }

  async function submitProgress(exerciseId, isCorrect, xpEarned) {
    const { data } = await http.post('/api/v1/students/progress', {
      id_exercise: exerciseId,
      attempts: 1,
      status: isCorrect ? 'Correct' : 'Incorrect',
      xp_earned: xpEarned,
      sync_status: 'Synced',
    })
    if (profile.value && data) {
      profile.value.total_xp = data.new_total_xp
      profile.value.current_level = data.new_level
      profile.value.streak_days = data.streak_days
      profile.value.xp_in_current_level = data.new_total_xp % (profile.value.xp_for_next_level || 100)
    }
    if (dailyStatus.value) {
      dailyStatus.value.done_today = (dailyStatus.value.done_today || 0) + 1
    }
    return data
  }

  return {
    profile, courseUnits, topicStats, dailyStatus, isLoading, error,
    loadProfile, loadCourseUnits, loadTopicStats, loadDailyStatus, submitProgress,
  }
})
