import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import { useAuthStore } from './authStore'
import { useAdminRequestStore } from './adminRequestStore'

function createStorageMock() {
  const data = new Map()
  return {
    getItem: (key) => (data.has(key) ? data.get(key) : null),
    setItem: (key, value) => data.set(key, String(value)),
    removeItem: (key) => data.delete(key),
    clear: () => data.clear(),
  }
}

describe('admin adminRequestStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    global.fetch = vi.fn()
    global.localStorage = createStorageMock()
    global.sessionStorage = createStorageMock()

    const authStore = useAuthStore()
    authStore.token = 'token-admin'
    authStore.user = { id: 'admin-1', role: 'Admin' }
  })

  it('loads requests, decodes typed title prefix and computes counters', async () => {
    fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => ([
        {
          id_request: 7,
          id_professor: 'prof-77',
          title: '[platform] Erro no painel',
          description: 'Stacktrace no dashboard',
          status: 'pending',
          admin_comment: null,
          creation_date: '2026-03-22T10:00:00',
        },
      ]),
    })

    const store = useAdminRequestStore()
    await store.loadRequests({ force: true })

    expect(store.requests).toHaveLength(1)
    expect(store.requests[0].type).toBe('platform')
    expect(store.requests[0].title).toBe('Erro no painel')
    expect(store.pendingCount).toBe(1)
  })

  it('updates request decision and replaces local state item', async () => {
    fetch
      .mockResolvedValueOnce({
        ok: true,
        json: async () => ([
          {
            id_request: 8,
            id_professor: 'prof-88',
            title: '[access] Pedido de acesso',
            description: 'Necessito acesso',
            status: 'pending',
            admin_comment: null,
            creation_date: '2026-03-22T10:00:00',
          },
        ]),
      })
      .mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          id_request: 8,
          id_professor: 'prof-88',
          title: '[access] Pedido de acesso',
          description: 'Necessito acesso',
          status: 'approved',
          admin_comment: 'Aprovado para sprint atual',
          creation_date: '2026-03-22T10:00:00',
        }),
      })

    const store = useAdminRequestStore()
    await store.loadRequests({ force: true })
    await store.updateRequestStatus(8, 'approved', 'Aprovado para sprint atual')

    expect(store.requests[0].status).toBe('approved')
    expect(store.requests[0].adminNote).toContain('Aprovado')
    expect(store.approvedCount).toBe(1)
  })
})
