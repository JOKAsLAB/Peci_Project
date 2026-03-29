import { defineStore } from 'pinia'
import { computed, ref } from 'vue'

const AUTH_STORAGE_KEY = 'peci_professor_auth_v1'
const API_BASE_URL = (import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:8000').replace(/\/$/, '')

function _extractErrorMessage(payload, fallback) {
  if (payload && typeof payload === 'object' && typeof payload.detail === 'string') {
    return payload.detail
  }
  return fallback
}

async function _parseJsonSafe(response) {
  try {
    return await response.json()
  } catch {
    return null
  }
}

export const useAuthStore = defineStore('auth', () => {
  const user = ref(null)
  const token = ref(null)

  const isAuthenticated = computed(() => Boolean(token.value && user.value))

  function _persist() {
    const payload = {
      user: user.value,
      token: token.value,
    }
    localStorage.setItem(AUTH_STORAGE_KEY, JSON.stringify(payload))
  }

  function _clearPersisted() {
    localStorage.removeItem(AUTH_STORAGE_KEY)
  }

  function _hydrate() {
    const raw = localStorage.getItem(AUTH_STORAGE_KEY)
    if (!raw) return

    try {
      const parsed = JSON.parse(raw)
      user.value = parsed?.user ?? null
      token.value = parsed?.token ?? null
    } catch {
      _clearPersisted()
      user.value = null
      token.value = null
    }
  }

  function _setSession(authPayload) {
    user.value = authPayload.user
    token.value = authPayload.access_token
    _persist()
  }

  async function login(email, password) {
    const loginResponse = await fetch(`${API_BASE_URL}/api/v1/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    })

    const loginData = await _parseJsonSafe(loginResponse)
    if (!loginResponse.ok) {
      throw new Error(_extractErrorMessage(loginData, 'Falha ao autenticar.'))
    }

    if (loginData?.user?.role !== 'Professor') {
      throw new Error('Esta conta não tem permissões de docente.')
    }

    _setSession(loginData)
    return loginData.user
  }

  async function registerProfessor({ name, email, password, department, office, shortBio }) {
    const registerResponse = await fetch(`${API_BASE_URL}/api/v1/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name,
        email,
        password,
        role: 'Professor',
        department,
        office,
        short_bio: shortBio,
      }),
    })

    const registerData = await _parseJsonSafe(registerResponse)
    if (!registerResponse.ok) {
      throw new Error(_extractErrorMessage(registerData, 'Falha ao registar conta docente.'))
    }

    if (registerData?.user?.role !== 'Professor') {
      throw new Error('Falha ao registar conta docente.')
    }

    return registerData.user
  }

  async function restoreSession() {
    if (!token.value) return false

    const meResponse = await fetch(`${API_BASE_URL}/api/v1/auth/me`, {
      headers: { Authorization: `Bearer ${token.value}` },
    })

    const meData = await _parseJsonSafe(meResponse)
    if (!meResponse.ok || meData?.role !== 'Professor') {
      logout()
      return false
    }

    user.value = meData
    _persist()
    return true
  }

  function logout() {
    user.value = null
    token.value = null
    _clearPersisted()
  }

  _hydrate()

  return {
    user,
    token,
    isAuthenticated,
    login,
    registerProfessor,
    restoreSession,
    logout,
  }
})
