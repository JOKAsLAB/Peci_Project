<template>
  <div class="space-y-8">
    <div>
      <h3 class="text-3xl font-bold">Pedidos Admin</h3>
      <p class="text-text-secondary mt-1">Inbox de pedidos administrativos enviados pelos docentes (sem pedidos de matéria/exercícios).</p>
    </div>

    <div
      v-if="requestStore.error"
      class="bg-error/10 border border-error/30 text-error px-4 py-3 rounded-card text-sm"
    >
      <i class="pi pi-exclamation-triangle mr-2"></i> {{ requestStore.error }}
    </div>

    <div class="grid grid-cols-2 sm:grid-cols-4 gap-3 sm:gap-6">
      <div class="bg-surface p-4 sm:p-6 rounded-card border border-white/5">
        <p class="text-text-secondary text-xs sm:text-sm">Total</p>
        <p class="text-2xl sm:text-3xl font-bold mt-2">{{ requestStore.requests.length }}</p>
      </div>
      <div class="bg-surface p-4 sm:p-6 rounded-card border border-white/5">
        <p class="text-text-secondary text-xs sm:text-sm">Pendentes</p>
        <p class="text-2xl sm:text-3xl font-bold mt-2 text-warning">{{ requestStore.pendingCount }}</p>
      </div>
      <div class="bg-surface p-4 sm:p-6 rounded-card border border-white/5">
        <p class="text-text-secondary text-xs sm:text-sm">Aprovados</p>
        <p class="text-2xl sm:text-3xl font-bold mt-2 text-success">{{ requestStore.approvedCount }}</p>
      </div>
      <div class="bg-surface p-4 sm:p-6 rounded-card border border-white/5">
        <p class="text-text-secondary text-xs sm:text-sm">Rejeitados</p>
        <p class="text-2xl sm:text-3xl font-bold mt-2 text-error">{{ requestStore.rejectedCount }}</p>
      </div>
    </div>

    <div class="space-y-3">
      <div v-for="req in filteredRequests" :key="req.id" class="bg-surface rounded-card border border-white/5 p-6 hover:border-brand/30 transition-all">
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 mb-3">
          <div class="flex flex-wrap items-center gap-2">
            <span class="text-[10px] font-bold uppercase tracking-widest px-3 py-1 rounded-chip"
              :class="req.type === 'access' ? 'bg-brand/10 text-brand' : req.type === 'platform' ? 'bg-blue-500/10 text-blue-400' : req.type === 'operations' ? 'bg-cyan-500/10 text-cyan-300' : 'bg-warning/10 text-warning'">
              {{ typeLabel(req.type) }}
            </span>
            <span class="text-[10px] font-bold uppercase tracking-widest px-3 py-1 rounded-chip"
              :class="req.status === 'pending' ? 'bg-warning/10 text-warning' : req.status === 'approved' ? 'bg-success/10 text-success' : 'bg-error/10 text-error'">
              {{ req.status === 'pending' ? 'Pendente' : req.status === 'approved' ? 'Aprovado' : 'Rejeitado' }}
            </span>
          </div>
          <span class="text-text-secondary text-xs">{{ req.professor }} · {{ req.createdAt }}</span>
        </div>
        <h4 class="font-bold text-sm mb-1">{{ req.title }}</h4>
        <p class="text-text-secondary text-sm">{{ req.description }}</p>

        <div v-if="req.status === 'pending'" class="flex flex-col sm:flex-row items-stretch sm:items-center gap-2 mt-4">
          <input v-model="adminNotes[req.id]" type="text" placeholder="Nota administrativa (opcional)"
            class="flex-1 bg-background p-2.5 rounded-btn border border-white/10 outline-none focus:border-brand text-sm" />
          <div class="flex gap-2">
            <button @click="approve(req.id)" class="flex-1 sm:flex-none bg-success/10 text-success px-4 py-2.5 rounded-btn text-xs font-bold hover:bg-success/20 transition-all">
              <i class="pi pi-check mr-1"></i> Aprovar
            </button>
            <button @click="reject(req.id)" class="flex-1 sm:flex-none bg-error/10 text-error px-4 py-2.5 rounded-btn text-xs font-bold hover:bg-error/20 transition-all">
              <i class="pi pi-times mr-1"></i> Rejeitar
            </button>
          </div>
        </div>

        <p v-if="req.adminNote && req.status !== 'pending'" class="text-xs mt-2 text-brand italic">Nota: {{ req.adminNote }}</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, reactive, ref, onMounted } from 'vue';
import { useAdminRequestStore } from '../stores/adminRequestStore';

const requestStore = useAdminRequestStore();
const statusFilter = ref('all');
const adminNotes = reactive({});

const typeLabels = { access: 'Acesso', platform: 'Plataforma', operations: 'Operações', other: 'Outro' };
function typeLabel(type) {
  return typeLabels[type] || 'Outro';
}

const filteredRequests = computed(() => {
  if (statusFilter.value === 'all') return requestStore.requests;
  return requestStore.requests.filter((r) => r.status === statusFilter.value);
});

async function approve(id) {
  const confirmed = window.confirm('Aprovar este pedido administrativo?')
  if (!confirmed) return

  await requestStore.updateRequestStatus(id, 'approved', adminNotes[id] || '');
}

async function reject(id) {
  const confirmed = window.confirm('Rejeitar este pedido administrativo?')
  if (!confirmed) return

  await requestStore.updateRequestStatus(id, 'rejected', adminNotes[id] || '');
}

onMounted(async () => {
  await requestStore.loadRequests();
});
</script>
