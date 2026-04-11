// @ts-nocheck
import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { getApiErrorMessage, http } from '../../../services/http';

export const usePathStore = defineStore('paths', () => {
  const paths = ref([]);
  const isLoading = ref(false);
  const error = ref(null);
  const hasLoaded = ref(false);

  // ─── CARREGAMENTO DE CAMINHOS DE APRENDIZAGEM ────────────────────────────

  async function loadPaths() {
    if (hasLoaded.value) return;

    isLoading.value = true;
    error.value = null;
    try {
      const { data } = await http.get('/api/v1/professors/learning-paths');
      paths.value = Array.isArray(data) ? data : [];
      hasLoaded.value = true;
    } catch (e) {
      // Se houver erro (ex: 403 Forbidden porque não tem disciplinas), apenas retorna array vazio
      paths.value = [];
      hasLoaded.value = true;
      console.warn('Erro ao carregar caminhos:', e);
    } finally {
      isLoading.value = false;
    }
  }

  // ─── COMPUTED PROPERTIES ────────────────────────────────────────────────

  const publishedPaths = computed(() => paths.value.filter((p) => p.published));

  const totalModules = computed(() => {
    return paths.value.reduce((sum, p) => sum + (p.modules?.length || 0), 0);
  });

  const totalExercisesInPaths = computed(() => {
    return paths.value.reduce((sum, p) => {
      const pathExercises =
        p.modules?.reduce((mSum, m) => mSum + (m.exercises?.length || 0), 0) ||
        0;
      return sum + pathExercises;
    }, 0);
  });

  // ─── AÇÕES DE GESTÃO DE CAMINHOS ────────────────────────────────────────

  function getPath(disciplineCode) {
    return paths.value.find((p) => p.disciplineCode === disciplineCode);
  }

  function addModule(pathId, moduleData) {
    const path = paths.value.find((p) => p.id === pathId);
    if (path) {
      const newModule = {
        ...moduleData,
        id: Date.now(),
        order: (path.modules?.length || 0) + 1,
        exercises: [],
      };
      if (!path.modules) path.modules = [];
      path.modules.push(newModule);
      path.lastModified = new Date().toISOString().split('T')[0];
    }
  }

  function updateModule(pathId, moduleId, data) {
    const path = paths.value.find((p) => p.id === pathId);
    if (path) {
      const idx = path.modules.findIndex((m) => m.id === moduleId);
      if (idx !== -1) {
        path.modules[idx] = { ...path.modules[idx], ...data };
        path.lastModified = new Date().toISOString().split('T')[0];
      }
    }
  }

  function removeModule(pathId, moduleId) {
    const path = paths.value.find((p) => p.id === pathId);
    if (path) {
      path.modules = path.modules.filter((m) => m.id !== moduleId);
      path.modules.forEach((m, i) => (m.order = i + 1));
      path.lastModified = new Date().toISOString().split('T')[0];
    }
  }

  function reorderModules(pathId, reorederedModules) {
    const path = paths.value.find((p) => p.id === pathId);
    if (path) {
      path.modules = reorederedModules;
      path.modules.forEach((m, i) => (m.order = i + 1));
      path.lastModified = new Date().toISOString().split('T')[0];
    }
  }

  function moveModuleUp(pathId, moduleId) {
    const path = paths.value.find((p) => p.id === pathId);
    if (!path) return;
    const idx = path.modules.findIndex((m) => m.id === moduleId);
    if (idx > 0) {
      const temp = path.modules[idx];
      path.modules[idx] = path.modules[idx - 1];
      path.modules[idx - 1] = temp;
      path.modules.forEach((m, i) => (m.order = i + 1));
    }
  }

  function moveModuleDown(pathId, moduleId) {
    const path = paths.value.find((p) => p.id === pathId);
    if (!path) return;
    const idx = path.modules.findIndex((m) => m.id === moduleId);
    if (idx < path.modules.length - 1) {
      const temp = path.modules[idx];
      path.modules[idx] = path.modules[idx + 1];
      path.modules[idx + 1] = temp;
      path.modules.forEach((m, i) => (m.order = i + 1));
    }
  }

  function addExerciseToModule(pathId, moduleId, exercise) {
    const path = paths.value.find((p) => p.id === pathId);
    if (!path) return;
    const mod = path.modules.find((m) => m.id === moduleId);
    if (mod) {
      mod.exercises.push(exercise);
      path.lastModified = new Date().toISOString().split('T')[0];
    }
  }

  function removeExerciseFromModule(pathId, moduleId, exerciseId) {
    const path = paths.value.find((p) => p.id === pathId);
    if (!path) return;
    const mod = path.modules.find((m) => m.id === moduleId);
    if (mod) {
      mod.exercises = mod.exercises.filter((e) => e.id !== exerciseId);
      path.lastModified = new Date().toISOString().split('T')[0];
    }
  }

  function updateExerciseInModule(pathId, moduleId, exerciseId, data) {
    const path = paths.value.find((p) => p.id === pathId);
    if (!path) return;
    const mod = path.modules.find((m) => m.id === moduleId);
    if (!mod) return;
    const idx = mod.exercises.findIndex((e) => e.id === exerciseId);
    if (idx !== -1) mod.exercises[idx] = { ...mod.exercises[idx], ...data };
  }

  function togglePathPublished(pathId) {
    const path = paths.value.find((p) => p.id === pathId);
    if (path) path.published = !path.published;
  }

  function toggleModuleStatus(pathId, moduleId) {
    const path = paths.value.find((p) => p.id === pathId);
    if (!path) return;
    const mod = path.modules.find((m) => m.id === moduleId);
    if (mod) mod.status = mod.status === 'published' ? 'draft' : 'published';
  }

  return {
    // Estado
    paths,
    isLoading,
    error,
    hasLoaded,
    // Computed
    publishedPaths,
    totalModules,
    totalExercisesInPaths,
    // Ações: Carregamento
    loadPaths,
    // Ações: Gestão de Caminhos
    getPath,
    addModule,
    updateModule,
    removeModule,
    reorderModules,
    moveModuleUp,
    moveModuleDown,
    addExerciseToModule,
    removeExerciseFromModule,
    updateExerciseInModule,
    togglePathPublished,
    toggleModuleStatus,
  };
});
