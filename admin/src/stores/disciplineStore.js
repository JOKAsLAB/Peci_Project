import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { useAuthStore } from './authStore'

const API_BASE_URL = (import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:8000').replace(/\/$/, '')

async function _parseJsonSafe(response) {
  try {
    return await response.json()
  } catch {
    return null
  }
}

function _extractErrorMessage(payload, fallback) {
  if (payload && typeof payload === 'object') {
    if (typeof payload.detail === 'string') return payload.detail
    if (Array.isArray(payload.detail)) {
      return payload.detail.map((item) => item?.msg).filter(Boolean).join('; ') || fallback
    }
  }
  return fallback
}

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

function _toFrontendDiscipline(item) {
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
    professors: [],
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

  function _authHeaders() {
    const authStore = useAuthStore()
    const token = authStore.token
    if (!token) throw new Error('Sessão inválida. Volte a autenticar.')
    return { Authorization: `Bearer ${token}` }
  }

  async function loadDisciplines({ force = false } = {}) {
    if (hasLoaded.value && !force) return

    isLoading.value = true
    error.value = null
    try {
      const response = await fetch(`${API_BASE_URL}/api/v1/admin/course-units`, {
        headers: {
          ..._authHeaders(),
        },
      })

      const payload = await _parseJsonSafe(response)
      if (!response.ok) {
        throw new Error(_extractErrorMessage(payload, 'Falha ao carregar unidades curriculares.'))
      }

      disciplines.value = Array.isArray(payload) ? payload.map(_toFrontendDiscipline) : []
      hasLoaded.value = true
    } catch (e) {
      error.value = e.message || 'Falha ao carregar unidades curriculares.'
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
      }

      if (Number.isNaN(payload.id_uc)) {
        throw new Error('Código da UC inválido.')
      }

      const response = await fetch(`${API_BASE_URL}/api/v1/admin/course-units`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ..._authHeaders(),
        },
        body: JSON.stringify(payload),
      })

      const body = await _parseJsonSafe(response)
      if (!response.ok) {
        throw new Error(_extractErrorMessage(body, 'Falha na comunicação com o servidor ao criar disciplina.'))
      }

      disciplines.value.unshift(_toFrontendDiscipline(body))
    } catch (err) {
      error.value = err.message || 'Falha na comunicação com o servidor ao criar disciplina.'
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
      }

      const response = await fetch(`${API_BASE_URL}/api/v1/admin/course-units/${id}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          ..._authHeaders(),
        },
        body: JSON.stringify(payload),
      })

      const body = await _parseJsonSafe(response)
      if (!response.ok) {
        throw new Error(_extractErrorMessage(body, 'Falha ao atualizar dados da disciplina.'))
      }

      const idx = disciplines.value.findIndex(d => d.id === id)
      if (idx !== -1) {
        disciplines.value[idx] = _toFrontendDiscipline(body)
      }
    } catch (err) {
      error.value = err.message || 'Falha ao atualizar dados da disciplina.'
    } finally {
      isLoading.value = false
    }
  }

  async function removeDiscipline(id) {
    isLoading.value = true
    error.value = null
    try {
      const response = await fetch(`${API_BASE_URL}/api/v1/admin/course-units/${id}`, {
        method: 'DELETE',
        headers: {
          ..._authHeaders(),
        },
      })

      const body = await _parseJsonSafe(response)
      if (!response.ok) {
        throw new Error(_extractErrorMessage(body, 'Falha ao remover a disciplina.'))
      }

      disciplines.value = disciplines.value.filter(d => d.id !== id)
    } catch (err) {
      error.value = err.message || 'Falha ao remover a disciplina.'
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