// @ts-nocheck
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { getApiErrorMessage, http } from '../../../services/http'
const REQUEST_TYPE_PREFIX_RE = /^\s*\[(access|platform|operations|other)\]\s*/i

function _roleToFrontend(role) {
  if (role === 'Professor') return 'professor'
  if (role === 'Admin') return 'admin'
  return 'aluno'
}

function _roleToBackend(role) {
  if (role === 'professor') return 'Professor'
  if (role === 'admin') return 'Admin'
  return 'Student'
}

function _statusToActive(status) {
  return status === 'Active'
}

function _activeToStatus(active) {
  return active ? 'Active' : 'Suspended'
}

function _formatDate(value) {
  if (!value) return '-'
  return String(value).split('T')[0]
}

function _extractRequestType(title) {
  const text = String(title || '')
  const match = text.match(REQUEST_TYPE_PREFIX_RE)
  if (!match) return { type: 'other', cleanTitle: text }
  return {
    type: match[1].toLowerCase(),
    cleanTitle: text.replace(REQUEST_TYPE_PREFIX_RE, '').trim(),
  }
}

function _toFrontendUser(item) {
  return {
    id: item.id,
    name: item.name,
    nmec: String(item.id).slice(0, 6).toUpperCase(),
    email: item.email,
    password: '',
    role: _roleToFrontend(item.role),
    avatar: null,
    active: _statusToActive(item.status),
    backendStatus: item.status,
    lastLogin: _formatDate(item.registration_date),
    disciplines: [],
  }
}

function _toProfessorRequest(item) {
  const parsed = _extractRequestType(item.title)
  const requestType = item.request_type ? String(item.request_type).toLowerCase() : parsed.type
  const professorRef = String(item.id_professor || '')
  const professorInfo = item.professor_info && typeof item.professor_info === 'object' ? item.professor_info : null
  const resolvedProfessorId = String(professorInfo?.id || professorRef)
  return {
    id: item.id_request,
    type: requestType,
    name: professorInfo?.name || `Professor ${resolvedProfessorId.slice(0, 8) || 'N/A'}`,
    nmec: resolvedProfessorId.slice(0, 6).toUpperCase() || '-',
    email: professorInfo?.email || '-',
    password: '',
    requestedAt: _formatDate(item.creation_date),
    department: '-',
    message: item.description,
    title: parsed.cleanTitle || 'Pedido de acesso',
    status: item.status,
    reviewedAt: item.resolution_date ? _formatDate(item.resolution_date) : null,
    reviewerNote: item.admin_comment || '',
  }
}

export const useUserStore = defineStore('users', () => {
  const users = ref([])
  const pendingProfessorRequests = ref([])

  const isLoading = ref(false)
  const error = ref(null)
  const hasLoadedUsers = ref(false)
  const hasLoadedProfessorRequests = ref(false)

  const professors = computed(() => users.value.filter(u => u.role === 'professor'))
  const students = computed(() => users.value.filter(u => u.role === 'aluno'))
  const activeUsers = computed(() => users.value.filter(u => u.active))
  const inactiveUsers = computed(() => users.value.filter(u => !u.active))
  const pendingProfessorCount = computed(() => pendingProfessorRequests.value.filter(r => r.status === 'pending').length)

  async function loadUsers({ force = false, q = '' } = {}) {
    if (hasLoadedUsers.value && !force && !q) return

    isLoading.value = true
    error.value = null
    try {
      const { data: payload } = await http.get('/api/v1/admin/users', {
        params: q ? { q } : undefined,
      })

      users.value = Array.isArray(payload) ? payload.map(_toFrontendUser) : []
      hasLoadedUsers.value = true
    } catch (e) {
      error.value = getApiErrorMessage(e, 'Falha ao carregar utilizadores.')
      if (!hasLoadedUsers.value) users.value = []
    } finally {
      isLoading.value = false
    }
  }

  async function addUser(data) {
    isLoading.value = true
    error.value = null
    try {
      await http.post('/api/v1/auth/register', {
        name: data.name,
        email: data.email,
        password: data.password,
        role: _roleToBackend(data.role),
      })

      await loadUsers({ force: true })
    } catch (e) {
      error.value = getApiErrorMessage(e, 'Falha ao adicionar utilizador.')
    } finally {
      isLoading.value = false
    }
  }

  async function updateUser(id, data) {
    isLoading.value = true
    error.value = null
    try {
      const payload = {}
      if (typeof data.name === 'string' && data.name.trim()) {
        payload.name = data.name.trim()
      }

      if (typeof data.active === 'boolean') {
        payload.status = _activeToStatus(data.active)
      } else if (typeof data.status === 'string') {
        payload.status = data.status
      }

      if (!payload.name && !payload.status) {
        return
      }

      const { data: body } = await http.patch(`/api/v1/admin/users/${id}`, payload)

      const updated = _toFrontendUser(body)
      const idx = users.value.findIndex(u => u.id === id)
      if (idx !== -1) {
        users.value[idx] = { ...users.value[idx], ...updated }
      }
    } catch (e) {
      error.value = getApiErrorMessage(e, 'Falha ao atualizar utilizador.')
    } finally {
      isLoading.value = false
    }
  }

  async function removeUser(id) {
    isLoading.value = true
    error.value = null
    try {
      await http.delete(`/api/v1/admin/users/${id}`)

      users.value = users.value.filter(u => u.id !== id)
    } catch (e) {
      error.value = getApiErrorMessage(e, 'Falha ao remover utilizador.')
    } finally {
      isLoading.value = false
    }
  }

  async function toggleStatus(id) {
    const user = users.value.find(u => u.id === id)
    if (!user) return
    await updateUser(id, { active: !user.active })
  }

  async function loadProfessorRequests({ force = false } = {}) {
    if (hasLoadedProfessorRequests.value && !force) return

    isLoading.value = true
    error.value = null
    try {
      const { data: payload } = await http.get('/api/v1/admin/requests')

      pendingProfessorRequests.value = (Array.isArray(payload) ? payload : [])
        .map(_toProfessorRequest)
        .filter((request) => request.type === 'access')
      hasLoadedProfessorRequests.value = true
    } catch (e) {
      error.value = getApiErrorMessage(e, 'Falha ao carregar pedidos de conta docente.')
      if (!hasLoadedProfessorRequests.value) pendingProfessorRequests.value = []
    } finally {
      isLoading.value = false
    }
  }

  async function _decideProfessorRequest(requestId, status, reviewerNote = '') {
    isLoading.value = true
    error.value = null
    try {
      await http.patch(`/api/v1/admin/requests/${requestId}/decision`, {
        status,
        admin_comment: reviewerNote || null,
      })

      await loadProfessorRequests({ force: true })
    } catch (e) {
      error.value = getApiErrorMessage(e, 'Falha ao atualizar decisão do pedido.')
    } finally {
      isLoading.value = false
    }
  }

  async function approveProfessorRequest(requestId, reviewerNote = '') {
    await _decideProfessorRequest(requestId, 'approved', reviewerNote)
  }

  async function rejectProfessorRequest(requestId, reviewerNote = '') {
    await _decideProfessorRequest(requestId, 'rejected', reviewerNote)
  }

  return {
    users,
    pendingProfessorRequests,
    isLoading,
    error,
    hasLoadedUsers,
    hasLoadedProfessorRequests,
    professors,
    students,
    activeUsers,
    inactiveUsers,
    pendingProfessorCount,
    loadUsers,
    loadProfessorRequests,
    addUser,
    updateUser,
    removeUser,
    toggleStatus,
    approveProfessorRequest,
    rejectProfessorRequest,
  }
})