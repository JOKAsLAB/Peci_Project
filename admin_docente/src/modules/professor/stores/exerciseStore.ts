// @ts-nocheck
import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { getApiErrorMessage, http } from '../../../services/http';

export const useExerciseStore = defineStore('exercises', () => {
  const exercises = ref([]);
  const isLoading = ref(false);
  const error = ref(null);
  const hasLoaded = ref(false);

  // ─── CARREGAMENTO DE EXERCÍCIOS ──────────────────────────────────────────

  async function loadExercises() {
    if (hasLoaded.value) return;

    isLoading.value = true;
    error.value = null;
    try {
      const { data } = await http.get('/api/v1/professors/exercises');
      exercises.value = Array.isArray(data) ? data : [];
      hasLoaded.value = true;
    } catch (e) {
      // Se houver erro (ex: 403 Forbidden porque não tem disciplinas), apenas retorna array vazio
      exercises.value = [];
      hasLoaded.value = true;
      console.warn('Erro ao carregar exercícios:', e);
    } finally {
      isLoading.value = false;
    }
  }

  // ─── COMPUTED PROPERTIES ────────────────────────────────────────────────

  const publishedExercises = computed(() =>
    exercises.value.filter((e) => e.published),
  );
  const draftExercises = computed(() =>
    exercises.value.filter((e) => !e.published),
  );

  const disciplines = computed(() => [
    ...new Set(exercises.value.map((e) => e.discipline)),
  ]);
  const modules = computed(() => [
    ...new Set(exercises.value.map((e) => e.module)),
  ]);
  const modulesByDiscipline = computed(() => {
    const map = {};
    for (const ex of exercises.value) {
      if (!map[ex.discipline]) map[ex.discipline] = new Set();
      map[ex.discipline].add(ex.module);
    }
    return Object.fromEntries(Object.entries(map).map(([k, v]) => [k, [...v]]));
  });

  const byDiscipline = computed(() => {
    const map = {};
    for (const ex of exercises.value) {
      if (!map[ex.discipline]) map[ex.discipline] = [];
      map[ex.discipline].push(ex);
    }
    return map;
  });

  // ─── AÇÕES DE GESTÃO DE EXERCÍCIOS ──────────────────────────────────────

  async function addExercise(exerciseData) {
    isLoading.value = true;
    error.value = null;
    try {
      const { data: newExercise } = await http.post(
        '/api/v1/professors/exercises',
        exerciseData,
      );
      exercises.value.push(newExercise);
    } catch (e) {
      error.value = getApiErrorMessage(
        e,
        'Falha ao gravar exercício no servidor.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  async function removeExercise(id) {
    isLoading.value = true;
    error.value = null;
    try {
      await http.delete(`/api/v1/professors/exercises/${id}`);
      exercises.value = exercises.value.filter((e) => e.id !== id);
    } catch (e) {
      error.value = getApiErrorMessage(e, 'Erro ao remover exercício.');
    } finally {
      isLoading.value = false;
    }
  }

  async function togglePublished(id) {
    isLoading.value = true;
    error.value = null;
    try {
      const ex = exercises.value.find((e) => e.id === id);
      if (!ex) throw new Error('Exercício não encontrado');

      const newPublished = !ex.published;
      const { data: updated } = await http.patch(
        `/api/v1/professors/exercises/${id}`,
        {
          published: newPublished,
        },
      );

      const idx = exercises.value.findIndex((e) => e.id === id);
      if (idx !== -1) {
        exercises.value[idx] = updated;
      }
    } catch (e) {
      error.value = getApiErrorMessage(
        e,
        'Erro ao alterar estado de publicação.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  async function updateExercise(id, data) {
    isLoading.value = true;
    error.value = null;
    try {
      const { data: updated } = await http.patch(
        `/api/v1/professors/exercises/${id}`,
        data,
      );
      const idx = exercises.value.findIndex((e) => e.id === id);
      if (idx !== -1) {
        exercises.value[idx] = updated;
      }
    } catch (e) {
      error.value = getApiErrorMessage(
        e,
        'Falha ao atualizar dados do exercício.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  return {
    // Estado
    exercises,
    isLoading,
    error,
    hasLoaded,
    // Computed
    publishedExercises,
    draftExercises,
    disciplines,
    modules,
    modulesByDiscipline,
    byDiscipline,
    // Ações: Carregamento
    loadExercises,
    // Ações: CRUD
    addExercise,
    removeExercise,
    togglePublished,
    updateExercise,
  };
});
