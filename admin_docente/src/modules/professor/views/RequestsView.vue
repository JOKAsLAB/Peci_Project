<template>
  <div class="space-y-8">
    <div class="page-header">
      <div>
        <h3 class="text-3xl font-bold">Pedidos ao Admin</h3>
        <p class="text-text-secondary mt-1">
          Use esta área apenas para temas administrativos e operacionais da
          plataforma.
        </p>
      </div>
      <button
        @click="showCreateModal = true"
        class="bg-brand px-6 py-3 rounded-btn text-sm font-bold hover:brightness-110 transition-all"
      >
        <i class="pi pi-plus mr-2"></i> Novo Pedido
      </button>
    </div>

    <div
      v-if="requestStore.error"
      class="bg-error/10 border border-error/30 text-error px-4 py-3 rounded-card text-sm"
    >
      <i class="pi pi-exclamation-triangle mr-2"></i>
      {{ requestStore.error }}
    </div>

    <!-- Métricas -->
    <div class="grid grid-cols-3 sm:grid-cols-3 gap-3 sm:gap-6">
      <div class="bg-surface p-4 sm:p-6 rounded-card border border-white/5">
        <p class="text-text-secondary text-xs sm:text-sm">Total</p>
        <p class="text-2xl sm:text-3xl font-bold mt-2">
          {{ requestStore.requests.length }}
        </p>
      </div>
      <div class="bg-surface p-4 sm:p-6 rounded-card border border-white/5">
        <p class="text-text-secondary text-xs sm:text-sm">Pendentes</p>
        <p class="text-2xl sm:text-3xl font-bold mt-2 text-warning">
          {{
            requestStore.requests.filter((r) => r.status === 'pending').length
          }}
        </p>
      </div>
      <div class="bg-surface p-4 sm:p-6 rounded-card border border-white/5">
        <p class="text-text-secondary text-xs sm:text-sm">Resolvidos</p>
        <p class="text-2xl sm:text-3xl font-bold mt-2 text-success">
          {{
            requestStore.requests.filter((r) => r.status !== 'pending').length
          }}
        </p>
      </div>
    </div>

    <!-- Lista de pedidos -->
    <div class="space-y-3">
      <div
        v-for="req in filteredRequests"
        :key="req.id"
        class="bg-surface rounded-card border border-white/5 p-6 hover:border-brand/30 transition-all"
      >
        <div class="flex items-center justify-between mb-3">
          <div class="flex items-center gap-3">
            <span
              class="text-[10px] font-bold uppercase tracking-widest px-3 py-1 rounded-chip"
              :class="
                req.type === 'access'
                  ? 'bg-brand/10 text-brand'
                  : req.type === 'platform'
                    ? 'bg-blue-500/10 text-blue-400'
                    : req.type === 'operations'
                      ? 'bg-cyan-500/10 text-cyan-300'
                      : req.type === 'other'
                        ? 'bg-warning/10 text-warning'
                        : 'bg-success/10 text-success'
              "
            >
              {{ typeLabel(req.type) }}
            </span>
            <span
              class="text-[10px] font-bold uppercase tracking-widest px-3 py-1 rounded-chip"
              :class="
                req.status === 'pending'
                  ? 'bg-warning/10 text-warning'
                  : req.status === 'approved'
                    ? 'bg-success/10 text-success'
                    : 'bg-error/10 text-error'
              "
            >
              {{
                req.status === 'pending'
                  ? 'Pendente'
                  : req.status === 'approved'
                    ? 'Aprovado'
                    : 'Rejeitado'
              }}
            </span>
          </div>
          <span class="text-text-secondary text-xs">{{ req.createdAt }}</span>
        </div>
        <h4 class="font-bold text-sm mb-1">{{ req.title }}</h4>
        <p class="text-text-secondary text-sm">{{ req.description }}</p>
        <p v-if="req.adminNote" class="text-xs mt-2 text-brand italic">
          Nota do admin: {{ req.adminNote }}
        </p>
      </div>

      <div
        v-if="filteredRequests.length === 0"
        class="bg-surface rounded-card border border-white/5 border-dashed p-12 text-center"
      >
        <i class="pi pi-inbox text-4xl text-brand/30 mb-4 block"></i>
        <p class="text-text-secondary">Sem pedidos nesta categoria.</p>
      </div>
    </div>

    <div class="flex items-center gap-3">
      <button
        v-for="f in ['Todos', 'Pendentes', 'Aprovados', 'Rejeitados']"
        :key="f"
        @click="statusFilter = f"
        :class="
          statusFilter === f
            ? 'bg-brand text-white'
            : 'bg-surface text-text-secondary border border-white/10'
        "
        class="px-5 py-2 rounded-chip text-sm font-bold transition-all"
      >
        {{ f }}
      </button>
    </div>

    <!-- Modal Criar Pedido -->
    <Teleport to="body">
      <div
        v-if="showCreateModal"
        class="fixed inset-0 z-50 flex items-center justify-center"
      >
        <div
          class="absolute inset-0 bg-black/60 backdrop-blur-sm"
          @click="showCreateModal = false"
        ></div>
        <div
          class="relative bg-surface border border-white/10 rounded-card w-full max-w-lg p-8 shadow-2xl z-10"
        >
          <div class="flex justify-between items-center mb-6">
            <h4 class="text-xl font-bold">Novo Pedido</h4>
            <button
              @click="showCreateModal = false"
              class="text-text-secondary hover:text-white"
            >
              <i class="pi pi-times"></i>
            </button>
          </div>

          <div class="space-y-4">
            <div>
              <label
                class="text-xs font-bold text-text-secondary uppercase tracking-widest"
                >Tipo</label
              >
              <select
                v-model="newRequest.type"
                class="w-full bg-background mt-2 p-3 rounded-btn border border-white/10 outline-none focus:border-brand text-sm"
              >
                <option value="access">Acesso / Permissões</option>
                <option value="platform">Plataforma / Bug</option>
                <option value="operations">Pedido Operacional</option>
                <option value="other">Outro</option>
              </select>
            </div>
            <div>
              <label
                class="text-xs font-bold text-text-secondary uppercase tracking-widest"
                >Assunto</label
              >
              <input
                v-model="newRequest.title"
                type="text"
                placeholder="Breve descrição"
                class="w-full bg-background mt-2 p-3 rounded-btn border border-white/10 outline-none focus:border-brand text-sm"
              />
            </div>
            <div>
              <label
                class="text-xs font-bold text-text-secondary uppercase tracking-widest"
                >Descrição</label
              >
              <textarea
                v-model="newRequest.description"
                rows="4"
                placeholder="Detalhe do pedido..."
                class="w-full bg-background mt-2 p-3 rounded-btn border border-white/10 outline-none focus:border-brand text-sm resize-none"
              ></textarea>
            </div>
            <button
              @click="submitRequest"
              :disabled="!newRequest.title || !newRequest.description"
              class="w-full bg-brand py-3 rounded-btn text-sm font-bold disabled:opacity-30 disabled:cursor-not-allowed hover:brightness-110 transition-all"
            >
              <i class="pi pi-send mr-2"></i> Submeter Pedido
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
import { computed, reactive, ref, onMounted } from 'vue';
import { useAdminRequestStore } from '../stores/adminRequestStore';

const showCreateModal = ref(false);
const statusFilter = ref('Todos');
const requestStore = useAdminRequestStore();

const typeLabels = {
  access: 'Acesso',
  platform: 'Plataforma',
  operations: 'Operações',
  other: 'Outro',
};
function typeLabel(type) {
  return typeLabels[type] || 'Outro';
}

const filteredRequests = computed(() => {
  if (statusFilter.value === 'Todos') return requestStore.requests;
  if (statusFilter.value === 'Pendentes') {
    return requestStore.requests.filter((req) => req.status === 'pending');
  }
  if (statusFilter.value === 'Aprovados') {
    return requestStore.requests.filter((req) => req.status === 'approved');
  }
  return requestStore.requests.filter((req) => req.status === 'rejected');
});

const newRequest = reactive({
  type: 'access',
  title: '',
  description: '',
});

async function submitRequest() {
  if (!newRequest.title || !newRequest.description) return;

  const confirmed = window.confirm('Submeter este pedido ao administrador?');
  if (!confirmed) return;

  try {
    await requestStore.addRequest({ ...newRequest });
    newRequest.title = '';
    newRequest.description = '';
    showCreateModal.value = false;
  } catch {
    // erro já mapeado no store
  }
}

onMounted(async () => {
  await requestStore.loadRequests();
});
</script>
