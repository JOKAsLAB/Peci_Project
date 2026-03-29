import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import { useExerciseStore } from './exerciseStore'
import { usePathStore } from './pathStore'

describe('professor exerciseStore and pathStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.useFakeTimers()
    vi.setSystemTime(new Date('2026-03-29T10:00:00.000Z'))
  })

  it('adds, updates, toggles and removes exercises in local transactional flow', async () => {
    const store = useExerciseStore()
    const initialLength = store.exercises.length

    const addPromise = store.addExercise({
      title: 'Questão de teste',
      module: 'Teste',
      discipline: 'SD',
      difficulty: 'Fácil',
      type: 'trueFalse',
      options: ['Verdadeiro', 'Falso'],
      correct: 0,
      solution: 'Verdadeiro',
      explanation: 'Explicação',
      published: false,
    })

    await vi.advanceTimersByTimeAsync(400)
    await addPromise

    expect(store.exercises.length).toBe(initialLength + 1)
    const createdId = store.exercises.at(-1).id

    const togglePromise = store.togglePublished(createdId)
    await vi.advanceTimersByTimeAsync(300)
    await togglePromise
    expect(store.exercises.at(-1).published).toBe(true)

    const updatePromise = store.updateExercise(createdId, { difficulty: 'Médio' })
    await vi.advanceTimersByTimeAsync(400)
    await updatePromise
    expect(store.exercises.at(-1).difficulty).toBe('Médio')

    const removePromise = store.removeExercise(createdId)
    await vi.advanceTimersByTimeAsync(300)
    await removePromise

    expect(store.exercises.length).toBe(initialLength)
  })

  it('supports path operations for modules and exercises', () => {
    const store = usePathStore()
    const sdPath = store.getPath('SD')
    expect(sdPath).toBeTruthy()

    const originalModules = sdPath.modules.length
    store.addModule(sdPath.id, {
      id: 'sd-extra',
      title: 'Módulo Extra',
      description: 'Módulo criado em teste',
    })
    expect(sdPath.modules.length).toBe(originalModules + 1)

    store.updateModule(sdPath.id, 'sd-extra', { title: 'Módulo Extra Atualizado' })
    expect(sdPath.modules.find((m) => m.id === 'sd-extra').title).toBe('Módulo Extra Atualizado')

    store.addExerciseToModule(sdPath.id, 'sd-extra', { id: 'ex-extra', title: 'Exercício X' })
    expect(sdPath.modules.find((m) => m.id === 'sd-extra').exercises).toHaveLength(1)

    store.updateExerciseInModule(sdPath.id, 'sd-extra', 'ex-extra', { title: 'Exercício Y' })
    expect(sdPath.modules.find((m) => m.id === 'sd-extra').exercises[0].title).toBe('Exercício Y')

    store.removeExerciseFromModule(sdPath.id, 'sd-extra', 'ex-extra')
    expect(sdPath.modules.find((m) => m.id === 'sd-extra').exercises).toHaveLength(0)

    store.toggleModuleStatus(sdPath.id, 'sd-extra')
    expect(sdPath.modules.find((m) => m.id === 'sd-extra').status).toBe('published')

    const wasPublished = sdPath.published
    store.togglePathPublished(sdPath.id)
    expect(sdPath.published).toBe(!wasPublished)

    store.removeModule(sdPath.id, 'sd-extra')
    expect(sdPath.modules.length).toBe(originalModules)
  })
})
