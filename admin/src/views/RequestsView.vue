<template>
  <div class="space-y-8">
    <div>
      <p class="text-brand font-bold text-sm uppercase tracking-widest mb-1">Administração</p>
      <h3 class="text-3xl font-bold">Pedidos Administrativos</h3>
      <p class="text-text-secondary mt-1">Inbox de pedidos administrativos enviados pelos docentes (sem pedidos de matéria/exercícios).</p>
    </div>

    <div
      v-if="requestStore.error"
      class="bg-error/10 border border-error/30 text-error px-4 py-3 rounded-card text-sm"
    >
      <i class="pi pi-exclamation-triangle mr-2"></i> {{ requestStore.error }}
    </div>

    <div class="grid grid-cols-4 gap-6">
      <div class="bg-surface p-6 rounded-card border border-white/5">
        <p class="text-text-secondary text-sm">Total</p>
        <p class="text-3xl font-bold mt-2">{{ requestStore.requests.length }}</p>
      </div>
      <div class="bg-surface p-6 rounded-card border border-white/5">
        <p class="text-text-secondary text-sm">Pendentes</p>
        <p class="text-3xl font-bold mt-2 text-warning">{{ requestStore.pendingCount }}</p>
      </div>
      <div class="bg-surface p-6 rounded-card border border-white/5">
        <p class="text-text-secondary text-sm">Aprovados</p>
        <p class="text-3xl font-bold mt-2 text-success">{{ requestStore.approvedCount }}</p>
      </div>
      <div class="bg-surface p-6 rounded-card border border-white/5">
        <p class="text-text-secondary text-sm">Rejeitados</p>
        <p class="text-3xl font-bold mt-2 text-error">{{ requestStore.rejectedCount }}</p>
      </div>
    </div>

    <div class="space-y-3">
      <div v-for="req in filteredRequests" :key="req.id" class="bg-surface rounded-card border border-white/5 p-6 hover:border-brand/30 transition-all">
        <div class="flex items-center justify-between mb-3">
          <div class="flex items-center gap-3">
            <span class="text-[10px] font-bold uppercase tracking-widest px-3 py-1 rounded-chip"
              :class="req.type === 'access' ? 'bg-brand/10 text-brand' : req.type === 'platform' ? 'bg-blue-500/10 text-blue-400' : 'bg-warning/10 text-warning'">
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

        <div v-if="req.status === 'pending'" class="flex items-center gap-3 mt-4">
          <input v-model="adminNotes[req.id]" type="text" placeholder="Nota administrativa (opcional)"
            class="flex-1 bg-background p-2.5 rounded-btn border border-white/10 outline-none focus:border-brand text-sm" />
          <button @click="approve(req.id)" class="bg-success/10 text-success px-4 py-2 rounded-btn text-xs font-bold hover:bg-success/20 transition-all">
            <i class="pi pi-check mr-1"></i> Aprovar
          </button>
          <button @click="reject(req.id)" class="bg-error/10 text-error px-4 py-2 rounded-btn text-xs font-bold hover:bg-error/20 transition-all">
            <i class="pi pi-times mr-1"></i> Rejeitar
          </button>
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

const typeLabels = { access: 'Acesso', platform: 'Plataforma', other: 'Outro' };
function typeLabel(type) {
  return typeLabels[type] || 'Outro';
}

const filteredRequests = computed(() => {
  if (statusFilter.value === 'all') return requestStore.requests;
  return requestStore.requests.filter((r) => r.status === statusFilter.value);
});

async function approve(id) {
  await requestStore.updateRequestStatus(id, 'approved', adminNotes[id] || '');
}

async function reject(id) {
  await requestStore.updateRequestStatus(id, 'rejected', adminNotes[id] || '');
}

onMounted(async () => {
  await requestStore.loadRequests();
});
</script>
