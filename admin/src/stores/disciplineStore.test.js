import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import { useAuthStore } from './authStore'
import { useDisciplineStore } from './disciplineStore'

function createStorageMock() {
  const data = new Map()
  return {
    getItem: (key) => (data.has(key) ? data.get(key) : null),
    setItem: (key, value) => data.set(key, String(value)),
    removeItem: (key) => data.delete(key),
    clear: () => data.clear(),
  }
}

describe('admin disciplineStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    global.fetch = vi.fn()
    global.localStorage = createStorageMock()
    global.sessionStorage = createStorageMock()

    const authStore = useAuthStore()
    authStore.token = 'token-admin'
    authStore.user = { id: 'admin-1', role: 'Admin' }
  })

  it('loads disciplines and maps backend payload', async () => {
    fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => ([
        { id_uc: 41953, name: 'Projeto em Engenharia', semester: '2S', curricular_year: 3 },
      ]),
    })

    const store = useDisciplineStore()
    await store.loadDisciplines({ force: true })

    expect(store.disciplines).toHaveLength(1)
    expect(store.disciplines[0].code).toBe('41953')
    expect(store.disciplines[0].semester).toBe('2S')
  })

  it('rejects invalid UC code before reaching backend', async () => {
    const store = useDisciplineStore()
    await store.addDiscipline({ code: 'abc', name: 'UC Invalida', semester: '1S', year: '2025/2026' })

    expect(fetch).not.toHaveBeenCalled()
    expect(store.error).toContain('Código da UC inválido')
  })

  it('executes CRUD mutation sequence against backend', async () => {
    fetch
      .mockResolvedValueOnce({
        ok: true,
        json: async () => ({ id_uc: 50001, name: 'Nova UC', semester: '1S', curricular_year: 2 }),
      })
      .mockResolvedValueOnce({
        ok: true,
        json: async () => ({ id_uc: 50001, name: 'UC Atualizada', semester: '2S', curricular_year: 2 }),
      })
      .mockResolvedValueOnce({ ok: true, json: async () => ({ message: 'deleted' }) })

    const store = useDisciplineStore()

    await store.addDiscipline({ code: '50001', name: 'Nova UC', semester: '1S', year: '2/3' })
    expect(store.disciplines).toHaveLength(1)

    await store.updateDiscipline(50001, { name: 'UC Atualizada', semester: '2S', year: '2/3' })
    expect(store.disciplines[0].name).toBe('UC Atualizada')

    await store.removeDiscipline(50001)
    expect(store.disciplines).toHaveLength(0)
  })

  it('returns explicit backend capability message for toggleStatus', async () => {
    const store = useDisciplineStore()
    await store.toggleStatus(41953)

    expect(store.error).toContain('ainda não está exposto no backend')
  })
})
