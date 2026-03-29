import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import { useQuestionLabStore } from './questionLabStore'

describe('professor questionLabStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.useFakeTimers()
    vi.setSystemTime(new Date('2026-03-29T10:00:00.000Z'))
  })

  it('generates a draft after simulated RAG/LLM delay', async () => {
    const store = useQuestionLabStore()
    const promise = store.generateQuestions({
      title: 'Lote SD',
      discipline: 'SD',
      questionType: 'multipleChoice',
    })

    await vi.advanceTimersByTimeAsync(2500)
    await promise

    expect(store.generatedDrafts).toHaveLength(1)
    expect(store.generatedDrafts[0].status).toBe('draft')
    expect(store.generatedDrafts[0].title).toBe('Lote SD')
  })

  it('uploads document and transitions to indexed status asynchronously', async () => {
    const store = useQuestionLabStore()
    const initialCount = store.availableDocuments.length

    const uploadPromise = store.uploadDocument({
      name: 'Novo_Documento.pdf',
      discipline: 'AC',
      chapter: 'Pipeline',
      fileType: 'pdf',
      size: '1.2 MB',
    })

    await vi.advanceTimersByTimeAsync(600)
    await uploadPromise

    expect(store.availableDocuments.length).toBe(initialCount + 1)
    const newDoc = store.availableDocuments.at(-1)
    expect(newDoc.status).toBe('processing')

    await vi.advanceTimersByTimeAsync(3000)

    expect(newDoc.status).toBe('indexed')
    expect(newDoc.chunks).toBeGreaterThan(0)
  })

  it('reindexes document and eventually marks it indexed again', async () => {
    const store = useQuestionLabStore()
    const docId = store.availableDocuments[0].id

    const reindexPromise = store.reindexDocument(docId)
    await vi.advanceTimersByTimeAsync(200)
    await reindexPromise

    const target = store.availableDocuments.find((d) => d.id === docId)
    expect(target.status).toBe('processing')

    await vi.advanceTimersByTimeAsync(2500)

    expect(target.status).toBe('indexed')
    expect(target.chunks).toBeGreaterThan(0)
  })
})
