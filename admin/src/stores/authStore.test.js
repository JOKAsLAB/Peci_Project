import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import { useAuthStore } from './authStore'

function createStorageMock() {
  const data = new Map()
  return {
    getItem: (key) => (data.has(key) ? data.get(key) : null),
    setItem: (key, value) => data.set(key, String(value)),
    removeItem: (key) => data.delete(key),
    clear: () => data.clear(),
  }
}

describe('admin authStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    global.fetch = vi.fn()
    global.localStorage = createStorageMock()
    global.sessionStorage = createStorageMock()
  })

  it('stores session in sessionStorage when remember is false', async () => {
    fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => ({
        access_token: 'token-admin',
        user: { id: '1', role: 'Admin', name: 'Admin User' },
      }),
    })

    const store = useAuthStore()
    await store.login('admin@ua.pt', 'admin123', { remember: false })

    expect(store.isAuthenticated).toBe(true)
    expect(localStorage.getItem('peci_admin_auth_v1')).toBeNull()

    const rawSession = sessionStorage.getItem('peci_admin_auth_session_v1')
    expect(rawSession).not.toBeNull()
    expect(JSON.parse(rawSession).token).toBe('token-admin')
  })

  it('rejects login when role is not Admin', async () => {
    fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => ({
        access_token: 'token-prof',
        user: { id: '2', role: 'Professor' },
      }),
    })

    const store = useAuthStore()
    await expect(store.login('prof@ua.pt', 'secret')).rejects.toThrow('não tem permissões')

    expect(store.isAuthenticated).toBe(false)
    expect(localStorage.getItem('peci_admin_auth_v1')).toBeNull()
    expect(sessionStorage.getItem('peci_admin_auth_session_v1')).toBeNull()
  })

  it('clears persisted state when restoreSession resolves with non-admin profile', async () => {
    localStorage.setItem(
      'peci_admin_auth_v1',
      JSON.stringify({
        token: 'old-token',
        user: { id: '1', role: 'Admin' },
      }),
    )

    fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => ({ id: '1', role: 'Professor' }),
    })

    const store = useAuthStore()
    const restored = await store.restoreSession()

    expect(restored).toBe(false)
    expect(store.user).toBeNull()
    expect(store.token).toBeNull()
    expect(localStorage.getItem('peci_admin_auth_v1')).toBeNull()
    expect(sessionStorage.getItem('peci_admin_auth_session_v1')).toBeNull()
  })

  it('keeps session valid when restoreSession returns an admin profile', async () => {
    sessionStorage.setItem(
      'peci_admin_auth_session_v1',
      JSON.stringify({ token: 'session-token', user: { id: '3', role: 'Admin' } }),
    )

    fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => ({ id: '3', role: 'Admin', name: 'Admin Restored' }),
    })

    const store = useAuthStore()
    const restored = await store.restoreSession()

    expect(restored).toBe(true)
    expect(store.user.name).toBe('Admin Restored')
    expect(localStorage.getItem('peci_admin_auth_v1')).not.toBeNull()
  })
})
