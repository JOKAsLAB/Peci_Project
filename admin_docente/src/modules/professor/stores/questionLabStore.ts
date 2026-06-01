// @ts-nocheck
import { defineStore } from 'pinia';
import { ref } from 'vue';
import { getApiErrorMessage, http } from '../../../services/http';

export const useQuestionLabStore = defineStore('questionLab', () => {
  const availableDocuments = ref([]);
  const generatedDrafts = ref([]);
  const isLoading = ref(false);
  const error = ref(null);
  const hasLoaded = ref(false);

  // Backend usa Status=Pending enquanto o ficheiro está a ser indexado em segundo
  // plano. Na UI isso corresponde a "A processar" (Indexed = pronto, Error = falhou).
  function mapStatus(rawStatus) {
    const s = rawStatus?.toLowerCase() ?? 'pending';
    return s === 'pending' ? 'processing' : s;
  }

  async function loadDocuments(force = false, silent = false) {
    if (hasLoaded.value && !force) return;

    if (!silent) isLoading.value = true;
    error.value = null;
    try {
      const { data } = await http.get('/api/v1/professors/materials');
      availableDocuments.value = Array.isArray(data)
        ? data.map((doc) => ({
            id_material: doc.id_material,
            id_uc: doc.id_uc,
            name: doc.title,
            discipline: doc.id_uc,
            status: mapStatus(doc.status),
            fileType: doc.title?.split('.').pop()?.toLowerCase() ?? 'pdf',
            uploadedAt: doc.upload_date
              ? new Date(doc.upload_date).toLocaleDateString('pt-PT')
              : '—',
            uploaded_by_name: doc.uploaded_by_name ?? '',
            is_mine: doc.is_mine ?? true,
          }))
        : [];
      hasLoaded.value = true;
    } catch (e) {
      if (!silent) {
        availableDocuments.value = [];
        error.value = getApiErrorMessage(e, 'Erro ao carregar documentos.');
      }
      hasLoaded.value = true;
    } finally {
      if (!silent) isLoading.value = false;
    }
  }

  // Refresca a lista em segundo plano até nenhum documento estar "a processar".
  let pollTimer = null;

  function stopPolling() {
    if (pollTimer) {
      clearInterval(pollTimer);
      pollTimer = null;
    }
  }

  function startPolling() {
    stopPolling();
    pollTimer = setInterval(async () => {
      await loadDocuments(true, true);
      const stillProcessing = availableDocuments.value.some(
        (d) => d.status === 'processing',
      );
      if (!stillProcessing) stopPolling();
    }, 3000);
  }

  async function generateQuestions(draftPayload) {
    isLoading.value = true;
    error.value = null;
    try {
      await new Promise((resolve) => setTimeout(resolve, 2500));
      generatedDrafts.value.unshift({
        id: Date.now(),
        createdAt: new Date().toISOString().split('T')[0],
        status: 'draft',
        ...draftPayload,
      });
    } catch (e) {
      error.value =
        'Falha na comunicação com o motor de Inteligência Artificial.';
    } finally {
      isLoading.value = false;
    }
  }

  async function removeDraft(draftId) {
    isLoading.value = true;
    error.value = null;
    try {
      await new Promise((resolve) => setTimeout(resolve, 300));
      generatedDrafts.value = generatedDrafts.value.filter(
        (d) => d.id !== draftId,
      );
    } catch (e) {
      error.value = 'Erro ao remover o rascunho.';
    } finally {
      isLoading.value = false;
    }
  }

  async function markDraftReady(draftId) {
    isLoading.value = true;
    error.value = null;
    try {
      await new Promise((resolve) => setTimeout(resolve, 300));
      const draft = generatedDrafts.value.find((d) => d.id === draftId);
      if (draft) draft.status = 'ready';
    } catch (e) {
      error.value = 'Erro ao atualizar o estado do rascunho.';
    } finally {
      isLoading.value = false;
    }
  }

  async function uploadDocument(docPayload) {
    isLoading.value = true;
    error.value = null;
    try {
      const { data: newDoc } = await http.post(
        '/api/v1/professors/materials/upload',
        docPayload,
      );
      availableDocuments.value.push(newDoc);
    } catch (e) {
      error.value = getApiErrorMessage(
        e,
        'Falha ao carregar o documento para o repositório.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  async function removeDocument(docId) {
    isLoading.value = true;
    error.value = null;
    try {
      await http.delete(`/api/v1/professors/materials/${docId}`);
      availableDocuments.value = availableDocuments.value.filter(
        (d) => d.id_material !== docId,
      );
    } catch (e) {
      error.value = getApiErrorMessage(
        e,
        'Erro ao eliminar o documento e vetores associados.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  async function reindexDocument(docId) {
    isLoading.value = true;
    error.value = null;
    try {
      await http.post(`/api/v1/professors/materials/${docId}/reindex`);
      const doc = availableDocuments.value.find((d) => d.id_material === docId);
      if (doc) doc.status = 'processing';
      startPolling();
    } catch (e) {
      error.value = getApiErrorMessage(
        e,
        'Erro ao inicializar a reindexação do documento.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  return {
    availableDocuments,
    generatedDrafts,
    isLoading,
    error,
    hasLoaded,
    loadDocuments,
    startPolling,
    stopPolling,
    generateQuestions,
    removeDraft,
    markDraftReady,
    uploadDocument,
    removeDocument,
    reindexDocument,
  };
});
