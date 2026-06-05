<template>
  <div class="space-y-8">
    <div v-if="!authStore.hasCourseUnits" class="space-y-8">
      <div>
        <h3 class="text-3xl font-bold">Nenhuma Disciplina Atribuída</h3>
        <p class="text-text-secondary mt-1">
          Ainda não tem unidades curriculares associadas à sua conta para editar
          conteúdo.
        </p>
      </div>
      <div class="bg-surface rounded-card border border-white/5 p-4 sm:p-8">
        <div class="max-w-lg">
          <div class="flex items-center gap-4 mb-6">
            <div
              class="w-12 h-12 rounded-full bg-warning/10 flex items-center justify-center"
            >
              <i class="pi pi-exclamation-circle text-warning text-xl"></i>
            </div>
            <div>
              <p class="font-bold">Solicitar Acesso a Disciplinas</p>
              <p class="text-text-secondary text-sm">
                Contacte o administrador da plataforma para atribuir uma ou mais
                unidades curriculares.
              </p>
            </div>
          </div>
          <router-link
            to="/professor/requests"
            class="inline-flex items-center gap-2 px-6 py-3 bg-brand text-white rounded-btn hover:bg-brand/80 transition-all font-semibold"
          >
            <i class="pi pi-envelope"></i>
            Enviar Pedido ao Admin
          </router-link>
        </div>
      </div>
    </div>

    <template v-else>
      <div>
        <h3 class="text-2xl sm:text-3xl font-bold">Dashboard</h3>
        <p class="text-text-secondary mt-1">
          Resumo das suas operações de conteúdo e suporte académico.
        </p>
      </div>

      <div class="grid grid-cols-2 sm:grid-cols-4 gap-3 sm:gap-6">
        <div class="bg-surface p-4 sm:p-6 rounded-card border border-white/5">
          <div class="flex items-center gap-2 sm:gap-3 mb-3">
            <div
              class="w-8 h-8 sm:w-10 sm:h-10 shrink-0 rounded-btn bg-success/10 flex items-center justify-center"
            >
              <i class="pi pi-check-circle text-success text-sm sm:text-base"></i>
            </div>
            <p class="text-text-secondary text-xs sm:text-sm leading-tight">Exercícios Publicados</p>
          </div>
          <p class="text-2xl sm:text-3xl font-bold text-success">
            {{ exerciseStore.publishedExercises.length }}
          </p>
        </div>

        <div class="bg-surface p-4 sm:p-6 rounded-card border border-white/5">
          <div class="flex items-center gap-2 sm:gap-3 mb-3">
            <div
              class="w-8 h-8 sm:w-10 sm:h-10 shrink-0 rounded-btn bg-warning/10 flex items-center justify-center"
            >
              <i class="pi pi-pencil text-warning text-sm sm:text-base"></i>
            </div>
            <p class="text-text-secondary text-xs sm:text-sm leading-tight">Em Rascunho</p>
          </div>
          <p class="text-2xl sm:text-3xl font-bold text-warning">
            {{ exerciseStore.draftExercises.length }}
          </p>
        </div>

        <div class="bg-surface p-4 sm:p-6 rounded-card border border-white/5">
          <div class="flex items-center gap-2 sm:gap-3 mb-3">
            <div
              class="w-8 h-8 sm:w-10 sm:h-10 shrink-0 rounded-btn bg-brand/10 flex items-center justify-center"
            >
              <i class="pi pi-map text-brand text-sm sm:text-base"></i>
            </div>
            <p class="text-text-secondary text-xs sm:text-sm leading-tight">Percursos</p>
          </div>
          <p class="text-2xl sm:text-3xl font-bold text-brand">
            {{ pathStore.paths.length }}
          </p>
        </div>

        <div class="bg-surface p-4 sm:p-6 rounded-card border border-white/5">
          <div class="flex items-center gap-2 sm:gap-3 mb-3">
            <div
              class="w-8 h-8 sm:w-10 sm:h-10 shrink-0 rounded-btn bg-cyan-400/10 flex items-center justify-center"
            >
              <i class="pi pi-file text-cyan-300 text-sm sm:text-base"></i>
            </div>
            <p class="text-text-secondary text-xs sm:text-sm leading-tight">Docs Indexados</p>
          </div>
          <p class="text-2xl sm:text-3xl font-bold text-cyan-300">
            {{ indexedDocumentsCount }}
          </p>
        </div>
      </div>

      <div class="grid grid-cols-1 gap-6">
        <div class="bg-surface rounded-card border border-white/5 p-6">
          <h4 class="text-lg font-bold mb-4 flex items-center gap-2">
            <i class="pi pi-bolt text-brand"></i> Atividade Recente
          </h4>
          <div class="space-y-3">
            <div
              class="flex items-center justify-between bg-background p-4 rounded-btn border border-white/5"
            >
              <div>
                <p class="font-bold">Último exercício criado</p>
                <p class="text-text-secondary text-xs">
                  {{ latestExerciseTitle }}
                </p>
              </div>
            </div>

            <div
              class="flex items-center justify-between bg-background p-4 rounded-btn border border-white/5"
            >
              <div>
                <p class="font-bold">Percursos disponíveis</p>
                <p class="text-text-secondary text-xs">{{ latestPathName }}</p>
              </div>
              <div class="text-right">
                <p class="text-brand font-bold">{{ pathStore.paths.length }}</p>
                <p class="text-text-secondary text-xs">Total</p>
              </div>
            </div>

            <div
              class="flex items-center justify-between bg-background p-4 rounded-btn border border-white/5"
            >
              <div>
                <p class="font-bold">Pedidos ao Admin pendentes</p>
                <p class="text-text-secondary text-xs">
                  Acompanhe respostas administrativas
                </p>
              </div>
              <div class="text-right">
                <p class="text-warning font-bold">{{ pendingRequestsCount }}</p>
                <p class="text-text-secondary text-xs">Em aberto</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<script setup>
import { computed, onMounted } from 'vue';
import { useAuthStore } from '../../../stores/authStore';
import { useExerciseStore } from '../stores/exerciseStore';
import { usePathStore } from '../stores/pathStore';
import { useQuestionLabStore } from '../stores/questionLabStore';
import { useAdminRequestStore } from '../stores/adminRequestStore';

const authStore = useAuthStore();
const exerciseStore = useExerciseStore();
const pathStore = usePathStore();
const questionLabStore = useQuestionLabStore();
const adminRequestStore = useAdminRequestStore();

const indexedDocumentsCount = computed(
  () =>
    questionLabStore.availableDocuments.filter(
      (doc) => doc.status === 'indexed',
    ).length,
);

const pendingRequestsCount = computed(
  () =>
    adminRequestStore.requests.filter((req) => req.status === 'pending').length,
);

const latestExercise = computed(() => {
  if (!exerciseStore.exercises?.length) return null;
  return exerciseStore.exercises[0] ?? null;
});

const latestExerciseTitle = computed(
  () =>
    latestExercise.value?.title ??
    latestExercise.value?.topic_name ??
    'Sem exercício recente',
);

const latestPathName = computed(
  () => pathStore.paths[0]?.name ?? 'Sem percurso',
);

onMounted(async () => {
  await Promise.all([
    adminRequestStore.loadRequests(),
    exerciseStore.loadExercises(),
    pathStore.loadPaths(),
    questionLabStore.loadDocuments(),
  ]);
});
</script>
