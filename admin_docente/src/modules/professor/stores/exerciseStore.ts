// @ts-nocheck
import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { getApiErrorMessage, http } from '../../../services/http';

// Função para normalizar dados da API para o formato esperado pelo componente
function normalizeExercise(apiExercise: any) {
  if (!apiExercise) {
    console.error('❌ Exercise data is null or undefined');
    return null;
  }
  
  const normalized = {
    // Mapeamento de campos OBRIGATÓRIOS da API
    id: apiExercise.id_exercise || '',  // UUID
    id_exercise: apiExercise.id_exercise || '',
    id_uc: apiExercise.id_uc || 0,
    title: apiExercise.topic_name || 'Sem Título',
    type: apiExercise.type || 'Multiple Choice',
    question: apiExercise.question || '',
    solution: apiExercise.solution || {},
    difficulty: apiExercise.difficulty || 'Easy',
    explanation: apiExercise.explanation || '',
    published: apiExercise.published === true,  // Força boolean
    topic_name: apiExercise.topic_name || 'Sem Tópico',
    material_ref: apiExercise.material_ref || null,
    course_unit_info: apiExercise.course_unit_info || { id_uc: apiExercise.id_uc, name: `Disciplina ${apiExercise.id_uc}` },
    
    // Propriedades derivadas para compatibilidade com componente
    discipline: apiExercise.course_unit_info?.name || `Disciplina ${apiExercise.id_uc}`,
    module: apiExercise.topic_name || 'Sem Módulo',
  };
  
  // Validação: se algum campo crítico está vazio, lançar aviso
  if (!normalized.id) {
    console.warn('⚠️ Exercise missing id_exercise:', apiExercise);
  }
  
  return normalized;
}

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
      console.log('📥 API Response received, count:', Array.isArray(data) ? data.length : 'not array');
      
      exercises.value = Array.isArray(data) 
        ? data
            .map(ex => {
              const normalized = normalizeExercise(ex);
              return normalized;
            })
            .filter((ex) => ex !== null) // Remove null entries
        : [];
      
      console.log('✅ Loaded and normalized exercises:', exercises.value.length);
      if (exercises.value.length > 0) {
        console.log('   Sample:', exercises.value[0]);
      }
      hasLoaded.value = true;
    } catch (e) {
      exercises.value = [];
      hasLoaded.value = true;
      console.error('❌ Erro ao carregar exercícios:', e);
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
      exercises.value.push(normalizeExercise(newExercise));
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
      // id pode ser tanto id_exercise quanto id (são iguais), mas para a API usamos o id_exercise
      const ex = exercises.value.find((e) => e.id === id || e.id_exercise === id);
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
      const ex = exercises.value.find((e) => e.id === id || e.id_exercise === id);
      if (!ex) throw new Error('Exercício não encontrado');

      const newPublished = !ex.published;
      const { data: updated } = await http.patch(
        `/api/v1/professors/exercises/${ex.id_exercise}`,
        {
          published: newPublished,
        },
      );

      const idx = exercises.value.findIndex((e) => e.id === id);
      if (idx !== -1) {
        exercises.value[idx] = normalizeExercise(updated);
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
      const ex = exercises.value.find((e) => e.id === id || e.id_exercise === id);
      if (!ex) throw new Error('Exercício não encontrado');
      
      const { data: updated } = await http.patch(
        `/api/v1/professors/exercises/${ex.id_exercise}`,
        data,
      );
      const idx = exercises.value.findIndex((e) => e.id === id);
      if (idx !== -1) {
        exercises.value[idx] = normalizeExercise(updated);
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
