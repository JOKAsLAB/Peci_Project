// @ts-nocheck
import { defineStore } from 'pinia';
import { computed, ref } from 'vue';
import { getApiErrorMessage, http } from '../../../services/http';

const REQUEST_TYPE_PREFIX_RE = /^\s*\[(access|platform|operations|other)\]\s*/i;

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
  const professorRef = String(item.id_professor || '');
  return {
    id: item.id_request,
    type: requestType,
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

  async function loadRequests({ force = false, status = null } = {}) {
    if (hasLoaded.value && !force && !status) return;

    isLoading.value = true;
    error.value = null;
    try {
      const { data: payload } = await http.get('/api/v1/admin/requests', {
        params: status ? { status } : undefined,
      });

      requests.value = (Array.isArray(payload) ? payload : []).map(toFrontendRequest);
      hasLoaded.value = true;
    } catch (e) {
      error.value = getApiErrorMessage(e, 'Falha ao carregar pedidos administrativos.');
      if (!hasLoaded.value) requests.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  async function updateRequestStatus(id, status, note = '') {
    isLoading.value = true;
    error.value = null;
    try {
      const { data: payload } = await http.patch(`/api/v1/admin/requests/${id}/decision`, {
      status,
      admin_comment: note || null,
      });

      const updated = toFrontendRequest(payload);
      const idx = requests.value.findIndex((r) => r.id === id);
      if (idx !== -1) {
        requests.value[idx] = updated;
      }
    } catch (e) {
      error.value = getApiErrorMessage(e, 'Falha ao atualizar estado do pedido.');
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
