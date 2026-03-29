<template>
  <div class="space-y-8">
    <div class="flex justify-between items-end">
      <div>
        <p class="text-brand font-bold text-sm uppercase tracking-widest mb-1">
          Segurança & Acesso
        </p>
        <h3 class="text-3xl font-bold">Aprovação de Contas Docentes</h3>
        <p class="text-text-secondary mt-1">
          Analise pedidos de criação de conta de professor antes de permitir o
          acesso ao painel docente.
        </p>
      </div>
    </div>

    <div
      v-if="userStore.error"
      class="bg-error/10 border border-error/30 text-error px-4 py-3 rounded-card text-sm"
    >
      <i class="pi pi-exclamation-triangle mr-2"></i> {{ userStore.error }}
    </div>

    <div class="grid grid-cols-3 gap-6">
      <div class="bg-surface p-6 rounded-card border border-white/5">
        <p class="text-text-secondary text-sm">Pendentes</p>
        <p class="text-3xl font-bold mt-2 text-warning">
          {{ pendingRequests.length }}
        </p>
      </div>
      <div class="bg-surface p-6 rounded-card border border-white/5">
        <p class="text-text-secondary text-sm">Aprovados</p>
        <p class="text-3xl font-bold mt-2 text-success">
          {{ approvedRequests.length }}
        </p>
      </div>
      <div class="bg-surface p-6 rounded-card border border-white/5">
        <p class="text-text-secondary text-sm">Rejeitados</p>
        <p class="text-3xl font-bold mt-2 text-error">
          {{ rejectedRequests.length }}
        </p>
      </div>
    </div>

    <div class="flex items-center gap-3">
      <button
        v-for="f in ['Pendentes', 'Aprovados', 'Rejeitados', 'Todos']"
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

      <div class="ml-auto relative">
        <i
          class="pi pi-search absolute left-3 top-1/2 -translate-y-1/2 text-text-secondary text-sm"
        ></i>
        <input
          v-model="search"
          placeholder="Pesquisar por nome, NMec ou email..."
          class="bg-surface border border-white/10 pl-10 pr-4 py-2 rounded-btn text-sm outline-none focus:border-brand w-80"
        />
      </div>
    </div>

    <div class="space-y-4">
      <article
        v-for="request in filteredRequests"
        :key="request.id"
        class="bg-surface p-6 rounded-card border border-white/5"
        :class="{ 'opacity-50 pointer-events-none': userStore.isLoading }"
      >
        <div class="flex items-start justify-between gap-6">
          <div class="space-y-3">
            <div class="flex items-center gap-3">
              <h4 class="text-lg font-bold">{{ request.name }}</h4>
              <span
                class="text-[10px] font-bold uppercase tracking-widest px-3 py-1 rounded-chip"
                :class="statusClass(request.status)"
              >
                {{ statusLabel(request.status) }}
              </span>
            </div>

            <div
              class="grid grid-cols-2 gap-x-8 gap-y-2 text-sm text-text-secondary"
            >
              <p>
                <strong class="text-text-primary">Email:</strong>
                {{ request.email }}
              </p>
              <p>
                <strong class="text-text-primary">Criado em:</strong>
                {{ request.requestedAt }}
              </p>
            </div>
          </div>

          <div
            v-if="request.status === 'pending'"
            class="flex flex-col gap-3 min-w-56"
          >
            <button
              @click="approve(request.id)"
              :disabled="userStore.isLoading"
              class="bg-success text-black px-4 py-2 rounded-btn font-bold hover:brightness-110 transition-all text-sm disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
            >
              <i v-if="userStore.isLoading" class="pi pi-spinner pi-spin"></i>
              Aprovar Conta
            </button>
            <button
              @click="reject(request.id)"
              :disabled="userStore.isLoading"
              class="bg-error text-white px-4 py-2 rounded-btn font-bold hover:brightness-110 transition-all text-sm disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
            >
              <i v-if="userStore.isLoading" class="pi pi-spinner pi-spin"></i>
              Rejeitar Pedido
            </button>
          </div>
        </div>
      </article>

      <div
        v-if="filteredRequests.length === 0"
        class="bg-surface rounded-card border border-white/5 border-dashed p-10 text-center text-text-secondary"
      >
        Nenhum pedido encontrado para os filtros atuais.
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, reactive, ref, onMounted } from 'vue';
import { useUserStore } from '../stores/userStore';

const userStore = useUserStore();

const statusFilter = ref('Pendentes');
const search = ref('');
const reviewNotes = reactive({});

const pendingRequests = computed(() =>
  userStore.pendingProfessorRequests.filter((r) => r.status === 'pending'),
);
const approvedRequests = computed(() =>
  userStore.pendingProfessorRequests.filter((r) => r.status === 'approved'),
);
const rejectedRequests = computed(() =>
  userStore.pendingProfessorRequests.filter((r) => r.status === 'rejected'),
);

const filteredRequests = computed(() => {
  let list = userStore.pendingProfessorRequests;

  if (statusFilter.value === 'Pendentes') {
    list = list.filter((r) => r.status === 'pending');
  } else if (statusFilter.value === 'Aprovados') {
    list = list.filter((r) => r.status === 'approved');
  } else if (statusFilter.value === 'Rejeitados') {
    list = list.filter((r) => r.status === 'rejected');
  }

  if (search.value.trim()) {
    const q = search.value.toLowerCase();
    list = list.filter(
      (r) =>
        r.name.toLowerCase().includes(q) ||
        String(r.nmec).includes(q) ||
        r.email.toLowerCase().includes(q),
    );
  }

  return list;
});

function statusLabel(status) {
  if (status === 'approved') return 'Aprovado';
  if (status === 'rejected') return 'Rejeitado';
  return 'Pendente';
}

function statusClass(status) {
  if (status === 'approved')
    return 'bg-success/10 text-success border border-success/20';
  if (status === 'rejected')
    return 'bg-error/10 text-error border border-error/20';
  return 'bg-warning/10 text-warning border border-warning/20';
}

async function approve(requestId) {
  const note = reviewNotes[requestId] || '';
  await userStore.approveProfessorRequest(requestId, note);
  if (!userStore.error) {
    delete reviewNotes[requestId]; // Limpa a memória para chaves antigas
  }
}

async function reject(requestId) {
  const note = reviewNotes[requestId] || '';
  await userStore.rejectProfessorRequest(requestId, note);
  if (!userStore.error) {
    delete reviewNotes[requestId];
  }
}

onMounted(async () => {
  await userStore.loadProfessorRequests();
});
</script>
