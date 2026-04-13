// @ts-nocheck
import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { getApiErrorMessage, http } from '../../../services/http';
import { useAuthStore } from '../../../stores/authStore';

function normalizeExercise(apiExercise) {
  if (!apiExercise) {
    console.error('Exercise data is null or undefined');
    return null;
  }

  const authStore = useAuthStore();
  const uc = authStore.user?.course_units?.find(
    (u) => u.id_uc === apiExercise.id_uc || u.id === apiExercise.id_uc,
  );

  const normalized = {
    id: apiExercise.id_exercise || '',
    id_exercise: apiExercise.id_exercise || '',
    id_uc: apiExercise.id_uc || 0,
    title: apiExercise.question || 'Sem Título',
    type: apiExercise.type || 'Multiple Choice',
    question: apiExercise.question || '',
    solution: apiExercise.solution || {},
    difficulty: apiExercise.difficulty || 'Easy',
    explanation: apiExercise.explanation || '',
    published: apiExercise.published === true,
    topic_name: apiExercise.topic_name || 'Sem Tópico',
    material_ref: apiExercise.material_ref || null,
    discipline: uc?.name || `Disciplina ${apiExercise.id_uc}`,
    module: apiExercise.topic_name || 'Sem Módulo',
    options: apiExercise.solution?.options || [],
    correct: apiExercise.solution?.correct ?? '',
  };

  if (!normalized.id) {
    console.warn('Exercise missing id_exercise:', apiExercise);
  }

  return normalized;
}

export const useExerciseStore = defineStore('exercises', () => {
  const exercises = ref([]);
  const isLoading = ref(false);
  const error = ref(null);
  const hasLoaded = ref(false);

  async function loadExercises(force = false) {
    if (hasLoaded.value && !force) return;

    isLoading.value = true;
    error.value = null;
    try {
      const { data } = await http.get('/api/v1/professors/exercises');
      exercises.value = Array.isArray(data)
        ? data.map((ex) => normalizeExercise(ex)).filter((ex) => ex !== null)
        : [];
      hasLoaded.value = true;
    } catch (e) {
      exercises.value = [];
      hasLoaded.value = true;
      error.value = getApiErrorMessage(e, 'Erro ao carregar exercícios.');
    } finally {
      isLoading.value = false;
    }
  }

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

  async function addExercise(exerciseData) {
    isLoading.value = true;
    error.value = null;
    try {
      const { data: newExercise } = await http.post(
        '/api/v1/professors/exercises',
        exerciseData,
      );
      exercises.value.push(normalizeExercise(newExercise));
    } catch (e) {
      error.value = getApiErrorMessage(e, 'Falha ao gravar exercício.');
      throw e;
    } finally {
      isLoading.value = false;
    }
  }

  async function removeExercise(id) {
    isLoading.value = true;
    error.value = null;
    try {
      const ex = exercises.value.find(
        (e) => e.id === id || e.id_exercise === id,
      );
      if (!ex) throw new Error('Exercício não encontrado');
      await http.delete(`/api/v1/professors/exercises/${ex.id_exercise}`);
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
      const ex = exercises.value.find(
        (e) => e.id === id || e.id_exercise === id,
      );

      // Se não está no store (página do percurso), faz patch direto
      const exerciseId = ex?.id_exercise ?? id;
      const newPublished = ex ? !ex.published : false;

      const { data: updated } = await http.patch(
        `/api/v1/professors/exercises/${exerciseId}`,
        { published: newPublished },
      );

      const idx = exercises.value.findIndex(
        (e) => e.id === id || e.id_exercise === id,
      );
      if (idx !== -1) {
        exercises.value[idx] = normalizeExercise(updated);
      }
    } catch (e) {
      error.value = getApiErrorMessage(e, 'Erro ao alterar publicação.');
    } finally {
      isLoading.value = false;
    }
  }

  async function updateExercise(id, data) {
    isLoading.value = true;
    error.value = null;
    try {
      const ex = exercises.value.find(
        (e) => e.id === id || e.id_exercise === id,
      );

      // Se não está no store (página do percurso), usa o id diretamente
      const exerciseId = ex?.id_exercise ?? id;

      const { data: updated } = await http.patch(
        `/api/v1/professors/exercises/${exerciseId}`,
        data,
      );

      const idx = exercises.value.findIndex(
        (e) => e.id === id || e.id_exercise === id,
      );
      if (idx !== -1) {
        exercises.value[idx] = normalizeExercise(updated);
      }
    } catch (e) {
      error.value = getApiErrorMessage(e, 'Falha ao atualizar exercício.');
      throw e;
    } finally {
      isLoading.value = false;
    }
  }

  return {
    exercises,
    isLoading,
    error,
    hasLoaded,
    publishedExercises,
    draftExercises,
    disciplines,
    modules,
    modulesByDiscipline,
    byDiscipline,
    loadExercises,
    addExercise,
    removeExercise,
    togglePublished,
    updateExercise,
  };
});
