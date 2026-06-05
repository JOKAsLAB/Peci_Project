// @ts-nocheck
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { http } from '../../../services/http'

export const useExerciseFeedStore = defineStore('exerciseFeed', () => {
  const exercises = ref([])
  const courseUnits = ref([])
  const isLoading = ref(false)
  const currentIndex = ref(0)
  const hasLoaded = ref(false)

  const filterCourseId = ref(null)
  const filterTopicName = ref(null)
  const filterDifficulty = ref(null)
  const filterType = ref(null)

  async function loadCourseUnits() {
    try {
      const { data } = await http.get('/api/v1/students/course-units')
      courseUnits.value = data
    } catch (e) {}
  }

  async function loadExercises() {
    isLoading.value = true
    try {
      const params = { limit: 50, offset: 0 }
      if (filterCourseId.value) params.id_uc = filterCourseId.value
      if (filterTopicName.value) params.topic_name = filterTopicName.value
      if (filterDifficulty.value) params.difficulty = filterDifficulty.value
      if (filterType.value) params.type = filterType.value

      const { data } = await http.get('/api/v1/students/exercises', { params })
      exercises.value = data
      currentIndex.value = 0
      hasLoaded.value = true
    } catch (e) {
      exercises.value = []
    } finally {
      isLoading.value = false
    }
  }

  async function loadTopics(id_uc) {
    try {
      const { data } = await http.get('/api/v1/students/topics', { params: { id_uc } })
      return data
    } catch (e) {
      return []
    }
  }

  const currentExercise = computed(() => exercises.value[currentIndex.value] ?? null)

  function nextExercise() {
    if (currentIndex.value < exercises.value.length - 1) currentIndex.value++
  }

  function prevExercise() {
    if (currentIndex.value > 0) currentIndex.value--
  }

  function applyFilters(filters) {
    filterCourseId.value = filters.courseId ?? null
    filterTopicName.value = filters.topicName ?? null
    filterDifficulty.value = filters.difficulty ?? null
    filterType.value = filters.type ?? null
    loadExercises()
  }

  function clearFilters() {
    filterCourseId.value = null
    filterTopicName.value = null
    filterDifficulty.value = null
    filterType.value = null
    loadExercises()
  }

  return {
    exercises, courseUnits, isLoading, currentIndex, currentExercise, hasLoaded,
    filterCourseId, filterTopicName, filterDifficulty, filterType,
    loadCourseUnits, loadExercises, loadTopics, nextExercise, prevExercise,
    applyFilters, clearFilters,
  }
})
