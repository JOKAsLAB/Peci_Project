// @ts-nocheck
import { defineStore } from 'pinia';
import { ref } from 'vue';
import { getApiErrorMessage, http } from '../../../services/http';

export interface ReportedExercise {
  id_exercise: string;
  question: string;
  type: string;
  difficulty: string;
  topic_name: string;
  discipline: string;
  id_uc: number;
  solution: Record<string, unknown>;
  explanation: string;
  published: boolean;
  report_count: number;
  first_reported_at: string;
  last_reported_at: string;
}

export const useReportedExerciseStore = defineStore('reportedExercises', () => {
  const reportedExercises = ref<ReportedExercise[]>([]);
  const isLoading = ref(false);
  const error = ref<string | null>(null);
  const hasLoaded = ref(false);

  async function loadReportedExercises(force = false) {
    if (hasLoaded.value && !force) return;

    isLoading.value = true;
    error.value = null;
    try {
      const { data } = await http.get('/api/v1/professors/exercises/reported');
      reportedExercises.value = Array.isArray(data) ? data : [];
      hasLoaded.value = true;
    } catch (e) {
      reportedExercises.value = [];
      hasLoaded.value = true;
      error.value = getApiErrorMessage(e, 'Erro ao carregar exercícios reportados.');
    } finally {
      isLoading.value = false;
    }
  }

  async function dismissReport(exerciseId: string) {
    isLoading.value = true;
    error.value = null;
    try {
      await http.delete(`/api/v1/professors/exercises/${exerciseId}/reports`);
      reportedExercises.value = reportedExercises.value.filter(
        (e) => e.id_exercise !== exerciseId,
      );
    } catch (e) {
      error.value = getApiErrorMessage(e, 'Erro ao dispensar report.');
      throw e;
    } finally {
      isLoading.value = false;
    }
  }

  return {
    reportedExercises,
    isLoading,
    error,
    hasLoaded,
    loadReportedExercises,
    dismissReport,
  };
});
