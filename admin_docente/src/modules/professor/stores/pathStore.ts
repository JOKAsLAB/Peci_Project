// @ts-nocheck
import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { getApiErrorMessage, http } from '../../../services/http';

export const usePathStore = defineStore('paths', () => {
  const paths = ref([]);
  const isLoading = ref(false);
  const error = ref(null);
  const hasLoaded = ref(false);

  const totalModules = computed(() =>
    paths.value.reduce((sum, p) => sum + (p.total_topics || 0), 0),
  );

  const totalExercisesInPaths = computed(() =>
    paths.value.reduce((sum, p) => sum + (p.total_exercises || 0), 0),
  );

  async function loadPaths(force = false) {
    if (hasLoaded.value && !force) return;

    isLoading.value = true;
    error.value = null;
    try {
      const { data } = await http.get('/api/v1/professors/learning-paths');
      paths.value = Array.isArray(data) ? data : [];
      hasLoaded.value = true;
    } catch (e) {
      paths.value = [];
      hasLoaded.value = true;
      error.value = getApiErrorMessage(e, 'Erro ao carregar percursos.');
    } finally {
      isLoading.value = false;
    }
  }

  return {
    paths,
    isLoading,
    error,
    hasLoaded,
    totalModules,
    totalExercisesInPaths,
    loadPaths,
  };
});
