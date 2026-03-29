import { defineStore } from 'pinia'
import { computed, ref } from 'vue'

const AUTH_STORAGE_KEY = 'peci_admin_auth_v1'
const AUTH_SESSION_STORAGE_KEY = 'peci_admin_auth_session_v1'
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

  function _persist(persistInLocalStorage = true) {
    const payload = {
      user: user.value,
      token: token.value,
    }

    const serialized = JSON.stringify(payload)
    if (persistInLocalStorage) {
      localStorage.setItem(AUTH_STORAGE_KEY, serialized)
      sessionStorage.removeItem(AUTH_SESSION_STORAGE_KEY)
      return
    }

    sessionStorage.setItem(AUTH_SESSION_STORAGE_KEY, serialized)
    localStorage.removeItem(AUTH_STORAGE_KEY)
  }

  function _clearPersisted() {
    localStorage.removeItem(AUTH_STORAGE_KEY)
    sessionStorage.removeItem(AUTH_SESSION_STORAGE_KEY)
  }

  function _hydrate() {
    const raw = localStorage.getItem(AUTH_STORAGE_KEY) || sessionStorage.getItem(AUTH_SESSION_STORAGE_KEY)
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

  function _setSession(authPayload, persistInLocalStorage = true) {
    user.value = authPayload.user
    token.value = authPayload.access_token
    _persist(persistInLocalStorage)
  }

  async function login(email, password, options = {}) {
    const remember = options.remember !== false

    const loginResponse = await fetch(`${API_BASE_URL}/api/v1/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    })

    const loginData = await _parseJsonSafe(loginResponse)
    if (!loginResponse.ok) {
      throw new Error(_extractErrorMessage(loginData, 'Falha ao autenticar.'))
    }

    if (loginData?.user?.role !== 'Admin') {
      throw new Error('Esta conta não tem permissões de administrador.')
    }

    _setSession(loginData, remember)
    return loginData.user
  }

  async function restoreSession() {
    if (!token.value) return false

    const meResponse = await fetch(`${API_BASE_URL}/api/v1/auth/me`, {
      headers: { Authorization: `Bearer ${token.value}` },
    })

    const meData = await _parseJsonSafe(meResponse)
    if (!meResponse.ok || meData?.role !== 'Admin') {
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
    restoreSession,
    logout,
  }
})