import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import { useAuthStore } from './authStore'
import { useUserStore } from './userStore'

function createStorageMock() {
  const data = new Map()
  return {
    getItem: (key) => (data.has(key) ? data.get(key) : null),
    setItem: (key, value) => data.set(key, String(value)),
    removeItem: (key) => data.delete(key),
    clear: () => data.clear(),
  }
}

describe('admin userStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    global.fetch = vi.fn()
    global.localStorage = createStorageMock()
    global.sessionStorage = createStorageMock()

    const authStore = useAuthStore()
    authStore.token = 'token-admin'
    authStore.user = { id: 'admin-1', role: 'Admin' }
  })

  it('loads users and maps backend role/status to frontend fields', async () => {
    fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => ([
        {
          id: 'u-1',
          name: 'Docente Teste',
          email: 'docente@ua.pt',
          role: 'Professor',
          status: 'Active',
          registration_date: '2026-03-20T10:00:00',
        },
      ]),
    })

    const store = useUserStore()
    await store.loadUsers({ force: true })

    expect(store.users).toHaveLength(1)
    expect(store.users[0].role).toBe('professor')
    expect(store.users[0].active).toBe(true)
    expect(store.professors).toHaveLength(1)
  })

  it('registers a user and refreshes the list from backend', async () => {
    fetch
      .mockResolvedValueOnce({ ok: true, json: async () => ({ id: 'new-user' }) })
      .mockResolvedValueOnce({
        ok: true,
        json: async () => ([
          {
            id: 'u-2',
            name: 'Aluno Teste',
            email: 'aluno@ua.pt',
            role: 'Student',
            status: 'Active',
            registration_date: '2026-03-21T09:00:00',
          },
        ]),
      })

    const store = useUserStore()
    await store.addUser({
      name: 'Aluno Teste',
      email: 'aluno@ua.pt',
      password: 'abc123',
      role: 'aluno',
    })

    expect(fetch).toHaveBeenCalledTimes(2)
    expect(store.users).toHaveLength(1)
    expect(store.users[0].role).toBe('aluno')
  })

  it('filters professor account approvals to only access request type', async () => {
    fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => ([
        {
          id_request: 10,
          id_professor: 'prof-1',
          title: '[access] Pedido de acesso ao painel',
          description: 'Ativar perfil docente',
          status: 'pending',
          admin_comment: null,
          creation_date: '2026-03-20T00:00:00',
          resolution_date: null,
        },
        {
          id_request: 11,
          id_professor: 'prof-2',
          title: '[platform] Erro no dashboard',
          description: 'Bug visual',
          status: 'pending',
          admin_comment: null,
          creation_date: '2026-03-21T00:00:00',
          resolution_date: null,
        },
      ]),
    })

    const store = useUserStore()
    await store.loadProfessorRequests({ force: true })

    expect(store.pendingProfessorRequests).toHaveLength(1)
    expect(store.pendingProfessorRequests[0].type).toBe('access')
    expect(store.pendingProfessorCount).toBe(1)
  })

  it('skips updateUser API call when no mutable fields are provided', async () => {
    const store = useUserStore()
    await store.updateUser('u-1', {})

    expect(fetch).not.toHaveBeenCalled()
    expect(store.error).toBeNull()
  })
})
