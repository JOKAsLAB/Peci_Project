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

describe('professor adminRequestStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    global.fetch = vi.fn()
    global.localStorage = createStorageMock()

    const authStore = useAuthStore()
    authStore.token = 'token-prof'
    authStore.user = { id: 'prof-1', role: 'Professor' }
  })

  it('sends request_type and plain title when creating admin request', async () => {
    fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => ({
        id_request: 42,
        request_type: 'platform',
        title: 'Falha no upload',
        description: 'Erro ao subir ficheiro',
        status: 'pending',
        creation_date: '2026-03-22T10:00:00',
        admin_comment: null,
      }),
    })

    const store = useAdminRequestStore()
    await store.addRequest({
      type: 'platform',
      title: 'Falha no upload',
      description: 'Erro ao subir ficheiro',
    })

    const requestBody = JSON.parse(fetch.mock.calls[0][1].body)
    expect(requestBody.request_type).toBe('platform')
    expect(requestBody.title).toBe('Falha no upload')
    expect(store.requests[0].type).toBe('platform')
    expect(store.requests[0].title).toBe('Falha no upload')
  })

  it('loads requests and decodes legacy prefixed titles', async () => {
    fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => ([
        {
          id_request: 50,
          title: '[access] Pedido de acesso',
          description: 'Acesso ao módulo X',
          status: 'approved',
          creation_date: '2026-03-21T11:00:00',
          admin_comment: 'Aprovado',
        },
      ]),
    })

    const store = useAdminRequestStore()
    await store.loadRequests({ force: true })

    expect(store.requests).toHaveLength(1)
    expect(store.requests[0].type).toBe('access')
    expect(store.requests[0].title).toBe('Pedido de acesso')
    expect(store.requests[0].adminNote).toBe('Aprovado')
  })
})
