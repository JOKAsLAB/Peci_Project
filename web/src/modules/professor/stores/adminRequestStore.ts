// @ts-nocheck
import { defineStore } from 'pinia';
import { ref } from 'vue';
import { getApiErrorMessage, http } from '../../../services/http';

const REQUEST_TYPE_PREFIX_RE = /^\s*\[(access|platform|operations|other)\]\s*/i;

function encodeTitle(type, title) {
  const normalizedType = ['access', 'platform', 'operations', 'other'].includes(type) ? type : 'other';
  return `[${normalizedType}] ${title}`;
}

function decodeTitle(rawTitle) {
  const title = String(rawTitle || '');
  const match = title.match(REQUEST_TYPE_PREFIX_RE);
  if (!match) {
    return { type: 'other', title };
  }
  return {
    type: match[1].toLowerCase(),
    title: title.replace(REQUEST_TYPE_PREFIX_RE, '').trim(),
  };
}

function formatDate(value) {
  if (!value) return '-';
  return String(value).split('T')[0];
}

function toFrontendRequest(item) {
  const decoded = decodeTitle(item.title);
  const requestType = item.request_type ? String(item.request_type).toLowerCase() : decoded.type;
  return {
    id: item.id_request,
    type: requestType,
    title: decoded.title,
    description: item.description,
    status: item.status,
    createdAt: formatDate(item.creation_date),
    adminNote: item.admin_comment || '',
  };
}

export const useAdminRequestStore = defineStore('professorAdminRequests', () => {
  const requests = ref([]);
  const isLoading = ref(false);
  const error = ref(null);
  const hasLoaded = ref(false);

  async function loadRequests({ force = false } = {}) {
    if (hasLoaded.value && !force) return;

    isLoading.value = true;
    error.value = null;
    try {
      const { data: payload } = await http.get('/api/v1/professors/requests');

      requests.value = (Array.isArray(payload) ? payload : []).map(toFrontendRequest);
      hasLoaded.value = true;
    } catch (e) {
      error.value = getApiErrorMessage(e, 'Falha ao carregar pedidos ao admin.');
      if (!hasLoaded.value) requests.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  async function addRequest(payload) {
    isLoading.value = true;
    error.value = null;
    try {
      const { data: body } = await http.post('/api/v1/professors/requests', {
          request_type: payload.type,
          title: payload.title,
          description: payload.description,
      });

      requests.value.unshift(toFrontendRequest(body));
    } catch (e) {
      error.value = getApiErrorMessage(e, 'Falha ao submeter pedido ao admin.');
      throw e;
    } finally {
      isLoading.value = false;
    }
  }

  function clearError() {
    error.value = null;
  }

  return {
    requests,
    isLoading,
    error,
    hasLoaded,
    loadRequests,
    addRequest,
    clearError,
  };
});
