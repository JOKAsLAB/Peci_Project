import { defineStore } from 'pinia';
import { ref } from 'vue';
import { useAuthStore } from './authStore';

const API_BASE_URL = (import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:8000').replace(/\/$/, '');
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

async function parseJsonSafe(response) {
  try {
    return await response.json();
  } catch {
    return null;
  }
}

function extractErrorMessage(payload, fallback) {
  if (payload && typeof payload === 'object') {
    if (typeof payload.detail === 'string') return payload.detail;
    if (Array.isArray(payload.detail)) {
      return payload.detail.map((item) => item?.msg).filter(Boolean).join('; ') || fallback;
    }
  }
  return fallback;
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

  function authHeaders() {
    const authStore = useAuthStore();
    if (!authStore.token) {
      throw new Error('Sessão inválida. Volte a autenticar.');
    }
    return { Authorization: `Bearer ${authStore.token}` };
  }

  async function loadRequests({ force = false } = {}) {
    if (hasLoaded.value && !force) return;

    isLoading.value = true;
    error.value = null;
    try {
      const response = await fetch(`${API_BASE_URL}/api/v1/professors/requests`, {
        headers: {
          ...authHeaders(),
        },
      });

      const payload = await parseJsonSafe(response);
      if (!response.ok) {
        throw new Error(extractErrorMessage(payload, 'Falha ao carregar pedidos ao admin.'));
      }

      requests.value = (Array.isArray(payload) ? payload : []).map(toFrontendRequest);
      hasLoaded.value = true;
    } catch (e) {
      error.value = e.message || 'Falha ao carregar pedidos ao admin.';
      if (!hasLoaded.value) requests.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  async function addRequest(payload) {
    isLoading.value = true;
    error.value = null;
    try {
      const response = await fetch(`${API_BASE_URL}/api/v1/professors/requests`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...authHeaders(),
        },
        body: JSON.stringify({
          request_type: payload.type,
          title: payload.title,
          description: payload.description,
        }),
      });

      const body = await parseJsonSafe(response);
      if (!response.ok) {
        throw new Error(extractErrorMessage(body, 'Falha ao submeter pedido ao admin.'));
      }

      requests.value.unshift(toFrontendRequest(body));
    } catch (e) {
      error.value = e.message || 'Falha ao submeter pedido ao admin.';
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
