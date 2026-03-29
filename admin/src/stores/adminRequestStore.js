import { defineStore } from 'pinia';
import { computed, ref } from 'vue';
import { useAuthStore } from './authStore';

const API_BASE_URL = (import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:8000').replace(/\/$/, '');
const REQUEST_TYPE_PREFIX_RE = /^\s*\[(access|platform|other)\]\s*/i;

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
  const professorRef = String(item.id_professor || '');
  return {
    id: item.id_request,
    type: decoded.type,
    professor: `Professor ${professorRef.slice(0, 8) || 'N/A'}`,
    title: decoded.title || 'Pedido administrativo',
    description: item.description,
    status: item.status,
    createdAt: formatDate(item.creation_date),
    adminNote: item.admin_comment || '',
  };
}

export const useAdminRequestStore = defineStore('adminRequests', () => {
  const requests = ref([]);
  const isLoading = ref(false);
  const error = ref(null);
  const hasLoaded = ref(false);

  const pendingCount = computed(() => requests.value.filter((r) => r.status === 'pending').length);
  const approvedCount = computed(() => requests.value.filter((r) => r.status === 'approved').length);
  const rejectedCount = computed(() => requests.value.filter((r) => r.status === 'rejected').length);

  function authHeaders() {
    const authStore = useAuthStore();
    if (!authStore.token) {
      throw new Error('Sessão inválida. Volte a autenticar.');
    }
    return { Authorization: `Bearer ${authStore.token}` };
  }

  async function loadRequests({ force = false, status = null } = {}) {
    if (hasLoaded.value && !force && !status) return;

    isLoading.value = true;
    error.value = null;
    try {
      const params = new URLSearchParams();
      if (status) params.set('status', status);

      const query = params.toString() ? `?${params.toString()}` : '';
      const response = await fetch(`${API_BASE_URL}/api/v1/admin/requests${query}`, {
        headers: {
          ...authHeaders(),
        },
      });

      const payload = await parseJsonSafe(response);
      if (!response.ok) {
        throw new Error(extractErrorMessage(payload, 'Falha ao carregar pedidos administrativos.'));
      }

      requests.value = (Array.isArray(payload) ? payload : []).map(toFrontendRequest);
      hasLoaded.value = true;
    } catch (e) {
      error.value = e.message || 'Falha ao carregar pedidos administrativos.';
      if (!hasLoaded.value) requests.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  async function updateRequestStatus(id, status, note = '') {
    isLoading.value = true;
    error.value = null;
    try {
      const response = await fetch(`${API_BASE_URL}/api/v1/admin/requests/${id}/decision`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          ...authHeaders(),
        },
        body: JSON.stringify({
          status,
          admin_comment: note || null,
        }),
      });

      const payload = await parseJsonSafe(response);
      if (!response.ok) {
        throw new Error(extractErrorMessage(payload, 'Falha ao atualizar estado do pedido.'));
      }

      const updated = toFrontendRequest(payload);
      const idx = requests.value.findIndex((r) => r.id === id);
      if (idx !== -1) {
        requests.value[idx] = updated;
      }
    } catch (e) {
      error.value = e.message || 'Falha ao atualizar estado do pedido.';
    } finally {
      isLoading.value = false;
    }
  }

  return {
    requests,
    isLoading,
    error,
    hasLoaded,
    pendingCount,
    approvedCount,
    rejectedCount,
    loadRequests,
    updateRequestStatus,
  };
});
