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

describe('professor authStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    global.fetch = vi.fn()
    global.localStorage = createStorageMock()
  })

  it('registerProfessor sends role Professor and persists authenticated session', async () => {
    fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => ({
        access_token: 'token-prof',
        user: { id: 'p-1', role: 'Professor', name: 'Docente 1' },
      }),
    })

    const store = useAuthStore()
    const user = await store.registerProfessor({
      name: 'Docente 1',
      email: 'docente1@ua.pt',
      password: 'secret123',
      department: 'DETI',
      office: '2.12',
      shortBio: 'Bio',
    })

    const firstCallBody = JSON.parse(fetch.mock.calls[0][1].body)
    expect(firstCallBody.role).toBe('Professor')
    expect(user.role).toBe('Professor')
    expect(store.isAuthenticated).toBe(true)
    expect(localStorage.getItem('peci_professor_auth_v1')).not.toBeNull()
  })

  it('rejects login when account role is not Professor', async () => {
    fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => ({ access_token: 'token-x', user: { id: 'x', role: 'Student' } }),
    })

    const store = useAuthStore()
    await expect(store.login('student@ua.pt', 'pass')).rejects.toThrow('não tem permissões')
    expect(store.isAuthenticated).toBe(false)
  })

  it('restores session only when /me confirms Professor role', async () => {
    localStorage.setItem(
      'peci_professor_auth_v1',
      JSON.stringify({ token: 'old-token', user: { id: 'p-2', role: 'Professor' } }),
    )

    fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => ({ id: 'p-2', role: 'Admin' }),
    })

    const store = useAuthStore()
    const restored = await store.restoreSession()

    expect(restored).toBe(false)
    expect(store.user).toBeNull()
    expect(store.token).toBeNull()
    expect(localStorage.getItem('peci_professor_auth_v1')).toBeNull()
  })
})
