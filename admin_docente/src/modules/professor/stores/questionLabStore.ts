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

  // ─── LÓGICA DE CARREGAMENTO DE DOCUMENTOS ──────────────────────────────────

  async function loadDocuments() {
    if (hasLoaded.value) return;

    isLoading.value = true;
    error.value = null;
    try {
      const { data } = await http.get('/api/v1/professors/materials');
      availableDocuments.value = Array.isArray(data)
        ? data.map((doc) => ({
            id_material: doc.id_material,
            id_uc: doc.id_uc,
            name: doc.title,
            discipline: doc.id_uc, // ou busca o nome da UC se tiveres
            status: doc.status?.toLowerCase() ?? 'pending',
            fileType: doc.title?.split('.').pop()?.toLowerCase() ?? 'pdf',
            uploadedAt: doc.upload_date
              ? new Date(doc.upload_date).toLocaleDateString('pt-PT')
              : '—',
            size: '—',
            chapter: '—',
          }))
        : [];
      hasLoaded.value = true;
    } catch (e) {
      availableDocuments.value = [];
      hasLoaded.value = true;
      console.warn('Erro ao carregar documentos:', e);
    } finally {
      isLoading.value = false;
    }
  }

  // ─── LÓGICA DE INFERÊNCIA RAG (QUESTION LAB) ────────────────────────────────

  async function generateQuestions(draftPayload) {
    isLoading.value = true;
    error.value = null;
    try {
      // Simulação realista do tempo de inferência do pipeline RAG + LLM
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

  // ─── LÓGICA DE GESTÃO DE DOCUMENTOS (DOCUMENTS VIEW) ──────────────────────

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
        (d) => d.id_material !== docId, // ← era d.id
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
      const doc = availableDocuments.value.find((d) => d.id_material === docId); // ← era d.id
      if (doc) {
        doc.status = 'processing';
      }
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
    // Estado
    availableDocuments,
    generatedDrafts,
    isLoading,
    error,
    hasLoaded,
    // Ações: Carregamento
    loadDocuments,
    // Ações: RAG / IA
    generateQuestions,
    removeDraft,
    markDraftReady,
    // Ações: Documentos
    uploadDocument,
    removeDocument,
    reindexDocument,
  };
});
