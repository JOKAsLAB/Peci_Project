// @ts-nocheck
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { getApiErrorMessage, http } from '../../../services/http'

function _makeAcronym(name, fallback) {
  const normalized = String(name || '')
    .trim()
    .split(/\s+/)
    .filter(Boolean)
    .map((word) => word[0])
    .join('')
    .toUpperCase()
  if (normalized.length >= 2) return normalized.slice(0, 6)
  return String(fallback || 'UC')
}

function _toFrontendProfessor(item) {
  return {
    id: item.id,
    name: item.name,
    email: item.email,
  }
}

function _toFrontendDiscipline(item) {
  const professorItems = Array.isArray(item.professors)
    ? item.professors.map(_toFrontendProfessor)
    : []

  return {
    id: item.id_uc,
    code: String(item.id_uc),
    name: item.name,
    acronym: _makeAcronym(item.name, item.id_uc),
    semester: item.semester || '-',
    students: 0,
    active: true,
    year: item.curricular_year ? `${item.curricular_year}/${item.curricular_year + 1}` : '-',
    curricularYear: item.curricular_year,
    professors: professorItems.map((professor) => professor.name),
    professorItems,
  }
}

function _parseCurricularYear(value) {
  if (!value) return null
  const firstChunk = String(value).split('/')[0]
  const parsed = Number.parseInt(firstChunk, 10)
  return Number.isNaN(parsed) ? null : parsed
}

export const useDisciplineStore = defineStore('disciplines', () => {
  const disciplines = ref([])
  const isLoading = ref(false)
  const error = ref(null)
  const hasLoaded = ref(false)
  const supportsStatus = false

  const activeDisciplines = computed(() => disciplines.value.filter(d => d.active))
  const inactiveDisciplines = computed(() => disciplines.value.filter(d => !d.active))
  const totalStudents = computed(() => disciplines.value.reduce((sum, d) => sum + d.students, 0))

  async function loadDisciplines({ force = false } = {}) {
    if (hasLoaded.value && !force) return

    isLoading.value = true
    error.value = null
    try {
      const { data: payload } = await http.get('/api/v1/admin/course-units')

      disciplines.value = Array.isArray(payload) ? payload.map(_toFrontendDiscipline) : []
      hasLoaded.value = true
    } catch (e) {
      error.value = getApiErrorMessage(e, 'Falha ao carregar unidades curriculares.')
      if (!hasLoaded.value) disciplines.value = []
    } finally {
      isLoading.value = false
    }
  }

  async function addDiscipline(data) {
    isLoading.value = true
    error.value = null
    try {
      const payload = {
        id_uc: Number.parseInt(data.code, 10),
        name: data.name,
        semester: data.semester || null,
        curricular_year: _parseCurricularYear(data.year),
        professor_ids: Array.isArray(data.professorIds) ? data.professorIds : [],
      }

      if (Number.isNaN(payload.id_uc)) {
        throw new Error('Código da UC inválido.')
      }

      const { data: body } = await http.post('/api/v1/admin/course-units', payload)

      disciplines.value.unshift(_toFrontendDiscipline(body))
    } catch (err) {
      error.value = getApiErrorMessage(err, 'Falha na comunicação com o servidor ao criar disciplina.')
    } finally {
      isLoading.value = false
    }
  }

  async function updateDiscipline(id, data) {
    isLoading.value = true
    error.value = null
    try {
      const payload = {
        name: data.name,
        semester: data.semester || null,
        curricular_year: _parseCurricularYear(data.year),
        professor_ids: Array.isArray(data.professorIds) ? data.professorIds : [],
      }

      const { data: body } = await http.patch(`/api/v1/admin/course-units/${id}`, payload)

      const idx = disciplines.value.findIndex(d => d.id === id)
      if (idx !== -1) {
        disciplines.value[idx] = _toFrontendDiscipline(body)
      }
    } catch (err) {
      error.value = getApiErrorMessage(err, 'Falha ao atualizar dados da disciplina.')
    } finally {
      isLoading.value = false
    }
  }

  async function removeDiscipline(id) {
    isLoading.value = true
    error.value = null
    try {
      await http.delete(`/api/v1/admin/course-units/${id}`)

      disciplines.value = disciplines.value.filter(d => d.id !== id)
    } catch (err) {
      error.value = getApiErrorMessage(err, 'Falha ao remover a disciplina.')
    } finally {
      isLoading.value = false
    }
  }

  async function toggleStatus(id) {
    error.value = 'O estado ativo/inativo de UCs ainda não está exposto no backend.'
  }

  return {
    disciplines,
    isLoading,
    error,
    hasLoaded,
    supportsStatus,
    activeDisciplines,
    inactiveDisciplines,
    totalStudents,
    loadDisciplines,
    addDiscipline,
    updateDiscipline,
    removeDiscipline,
    toggleStatus
  }
})