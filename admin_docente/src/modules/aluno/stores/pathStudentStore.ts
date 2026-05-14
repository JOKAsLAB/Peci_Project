// @ts-nocheck
import { defineStore } from 'pinia'
import { ref } from 'vue'
import { http } from '../../../services/http'

export const usePathStudentStore = defineStore('pathStudent', () => {
  const paths = ref([])
  const selectedPath = ref(null)
  const practiceSession = ref(null)
  const isLoading = ref(false)
  const isPracticeLoading = ref(false)
  const hasLoaded = ref(false)

  async function loadPaths() {
    isLoading.value = true
    try {
      const { data } = await http.get('/api/v1/students/learning-paths')
      paths.value = data
      hasLoaded.value = true
    } catch (e) {
      paths.value = []
    } finally {
      isLoading.value = false
    }
  }

  async function loadPath(id_uc) {
    try {
      const { data } = await http.get(`/api/v1/students/learning-paths/${id_uc}`)
      selectedPath.value = data
    } catch (e) {}
  }

  async function loadPracticeSession(id_uc) {
    isPracticeLoading.value = true
    try {
      const { data } = await http.get('/api/v1/students/practice-session', { params: { id_uc } })
      practiceSession.value = data
    } catch (e) {
      practiceSession.value = null
    } finally {
      isPracticeLoading.value = false
    }
  }

  return {
    paths, selectedPath, practiceSession,
    isLoading, isPracticeLoading, hasLoaded,
    loadPaths, loadPath, loadPracticeSession,
  }
})
