// @ts-nocheck
import { defineStore } from 'pinia';
import { ref } from 'vue';

export const useQuestionLabStore = defineStore('questionLab', () => {
  // Estado: Vetor de documentos na BD
  const availableDocuments = ref([
    {
      id: 1,
      name: 'Cap4_CircuitosSequenciais.pdf',
      discipline: 'SD',
      chapter: 'Circuitos Sequenciais',
      fileType: 'pdf',
      size: '3.2 MB',
      status: 'indexed',
      updatedAt: '2026-03-04',
      uploadedAt: '2026-03-04',
    },
    {
      id: 2,
      name: 'Apontamentos_MIPS.pdf',
      discipline: 'AC',
      chapter: 'Datapaths MIPS',
      fileType: 'pdf',
      size: '5.7 MB',
      status: 'indexed',
      updatedAt: '2026-03-04',
      uploadedAt: '2026-03-04',
    },
    {
      id: 3,
      name: 'Pipeline_Hazards.pdf',
      discipline: 'AC',
      chapter: 'Pipeline',
      fileType: 'pdf',
      size: '2.1 MB',
      status: 'indexed',
      updatedAt: '2026-03-05',
      uploadedAt: '2026-03-05',
    },
    {
      id: 4,
      name: 'Guia_SPI_I2C.docx',
      discipline: 'SE',
      chapter: 'Comunicacao Serie',
      fileType: 'docx',
      size: '4.5 MB',
      status: 'processing',
      updatedAt: '2026-03-06',
      uploadedAt: '2026-03-06',
    },
  ]);

  // Estado: Histórico de rascunhos gerados
  const generatedDrafts = ref([]);

  // Estado transacional global para a Store
  const isLoading = ref(false);
  const error = ref(null);

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
      // Simula o tempo de upload do ficheiro binário
      await new Promise((resolve) => setTimeout(resolve, 600));

      const newDoc = {
        id: Date.now(),
        status: 'processing',
        uploadedAt: new Date().toISOString().split('T')[0],
        updatedAt: new Date().toISOString().split('T')[0],
        chunks: 0,
        ...docPayload,
      };

      availableDocuments.value.push(newDoc);

      // Desacopla o processo de chunking/indexação do bloqueio principal da UI
      setTimeout(() => {
        const target = availableDocuments.value.find((d) => d.id === newDoc.id);
        if (target) {
          target.chunks = Math.floor(Math.random() * 50 + 10);
          target.status = 'indexed';
        }
      }, 3000);
    } catch (e) {
      error.value = 'Falha ao carregar o documento para o repositório.';
    } finally {
      isLoading.value = false;
    }
  }

  async function removeDocument(docId) {
    isLoading.value = true;
    error.value = null;
    try {
      await new Promise((resolve) => setTimeout(resolve, 300));
      availableDocuments.value = availableDocuments.value.filter(
        (d) => d.id !== docId,
      );
    } catch (e) {
      error.value = 'Erro ao eliminar o documento e vetores associados.';
    } finally {
      isLoading.value = false;
    }
  }

  async function reindexDocument(docId) {
    isLoading.value = true;
    error.value = null;
    try {
      await new Promise((resolve) => setTimeout(resolve, 200));
      const doc = availableDocuments.value.find((d) => d.id === docId);
      if (doc) {
        doc.status = 'processing';
        doc.chunks = 0;

        // Simula recálculo de embeddings em background
        setTimeout(() => {
          const target = availableDocuments.value.find((d) => d.id === docId);
          if (target) {
            target.chunks = Math.floor(Math.random() * 60 + 15);
            target.status = 'indexed';
            target.updatedAt = new Date().toISOString().split('T')[0];
          }
        }, 2500);
      }
    } catch (e) {
      error.value = 'Erro ao inicializar a reindexação do documento.';
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
