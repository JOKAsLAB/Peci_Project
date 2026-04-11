<template>
  <div class="space-y-8">
    <!-- Sem Disciplinas Atribuídas -->
    <div v-if="!authStore.hasCourseUnits" class="space-y-8">
      <div>
        <p class="text-brand font-bold text-sm uppercase tracking-widest mb-1">
          Acesso Restrito
        </p>
        <h3 class="text-3xl font-bold">Nenhuma Disciplina Atribuída</h3>
        <p class="text-text-secondary mt-1">
          Ainda não tem unidades curriculares associadas à sua conta para editar
          conteúdo.
        </p>
      </div>

      <div class="bg-surface rounded-card border border-white/5 p-8">
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

    <!-- Dashboard Completo (Com Turmas) -->
    <template v-else>
      <div>
        <p class="text-brand font-bold text-sm uppercase tracking-widest mb-1">
          Visão Geral
        </p>
        <h3 class="text-3xl font-bold">Dashboard Docente</h3>
        <p class="text-text-secondary mt-1">
          Resumo das suas operações de conteúdo e suporte académico.
        </p>
      </div>

      <!-- Métricas principais do novo escopo -->
      <div class="grid grid-cols-4 gap-6">
        <div class="bg-surface p-6 rounded-card border border-white/5">
          <div class="flex items-center gap-3 mb-3">
            <div
              class="w-10 h-10 rounded-btn bg-success/10 flex items-center justify-center"
            >
              <i class="pi pi-check-circle text-success"></i>
            </div>
            <p class="text-text-secondary text-sm">Exercícios Publicados</p>
          </div>
          <p class="text-3xl font-bold text-success">
            {{ exerciseStore.publishedExercises.length }}
          </p>
        </div>

        <div class="bg-surface p-6 rounded-card border border-white/5">
          <div class="flex items-center gap-3 mb-3">
            <div
              class="w-10 h-10 rounded-btn bg-warning/10 flex items-center justify-center"
            >
              <i class="pi pi-pencil text-warning"></i>
            </div>
            <p class="text-text-secondary text-sm">Exercícios em Rascunho</p>
          </div>
          <p class="text-3xl font-bold text-warning">
            {{ exerciseStore.draftExercises.length }}
          </p>
        </div>

        <div class="bg-surface p-6 rounded-card border border-white/5">
          <div class="flex items-center gap-3 mb-3">
            <div
              class="w-10 h-10 rounded-btn bg-brand/10 flex items-center justify-center"
            >
              <i class="pi pi-map text-brand"></i>
            </div>
            <p class="text-text-secondary text-sm">Percursos Publicados</p>
          </div>
          <p class="text-3xl font-bold text-brand">
            {{ pathStore.publishedPaths.length }}
          </p>
        </div>

        <div class="bg-surface p-6 rounded-card border border-white/5">
          <div class="flex items-center gap-3 mb-3">
            <div
              class="w-10 h-10 rounded-btn bg-cyan-400/10 flex items-center justify-center"
            >
              <i class="pi pi-file text-cyan-300"></i>
            </div>
            <p class="text-text-secondary text-sm">Documentos Indexados</p>
          </div>
          <p class="text-3xl font-bold text-cyan-300">
            {{ indexedDocumentsCount }}
          </p>
        </div>
      </div>

      <!-- Blocos operacionais -->
      <div class="grid grid-cols-2 gap-6">
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
              <div class="text-right">
                <p class="text-brand font-bold">{{ latestExerciseDate }}</p>
                <p class="text-text-secondary text-xs">Data de criação</p>
              </div>
            </div>

            <div
              class="flex items-center justify-between bg-background p-4 rounded-btn border border-white/5"
            >
              <div>
                <p class="font-bold">Última atualização de percurso</p>
                <p class="text-text-secondary text-xs">{{ latestPathName }}</p>
              </div>
              <div class="text-right">
                <p class="text-brand font-bold">{{ latestPathDate }}</p>
                <p class="text-text-secondary text-xs">Data de revisão</p>
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

        <div class="bg-surface rounded-card border border-white/5 p-6">
          <h4 class="text-lg font-bold mb-4 flex items-center gap-2">
            <i class="pi pi-compass text-warning"></i> Atalhos de Trabalho
          </h4>
          <div class="grid grid-cols-2 gap-3">
            <router-link
              to="/path-builder"
              class="bg-background p-4 rounded-btn border border-white/5 hover:border-brand/40 transition-all"
            >
              <p class="font-bold text-sm">Percurso Base</p>
              <p class="text-text-secondary text-xs mt-1">
                Organizar módulos por disciplina
              </p>
            </router-link>

            <router-link
              to="/exercises"
              class="bg-background p-4 rounded-btn border border-white/5 hover:border-brand/40 transition-all"
            >
              <p class="font-bold text-sm">Exercícios</p>
              <p class="text-text-secondary text-xs mt-1">
                Criar, editar e publicar conteúdo
              </p>
            </router-link>

            <router-link
              to="/documents"
              class="bg-background p-4 rounded-btn border border-white/5 hover:border-brand/40 transition-all"
            >
              <p class="font-bold text-sm">Documentos da UC</p>
              <p class="text-text-secondary text-xs mt-1">
                Gerir base de conhecimento
              </p>
            </router-link>

            <router-link
              to="/question"
              class="bg-background p-4 rounded-btn border border-white/5 hover:border-brand/40 transition-all"
            >
              <p class="font-bold text-sm">Perguntas com LLM</p>
              <p class="text-text-secondary text-xs mt-1">
                Gerar rascunhos com apoio IA
              </p>
            </router-link>
          </div>

          <div
            class="mt-4 p-4 bg-background rounded-btn border border-white/5 flex items-center justify-between"
          >
            <div>
              <p class="font-bold text-sm">Rascunhos IA Gerados</p>
              <p class="text-text-secondary text-xs">Question Lab</p>
            </div>
            <p class="text-brand text-2xl font-bold">
              {{ questionLabStore.generatedDrafts.length }}
            </p>
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
  if (!exerciseStore.exercises.length) return null;
  return [...exerciseStore.exercises].sort((a, b) =>
    b.createdAt.localeCompare(a.createdAt),
  )[0];
});

const latestPath = computed(() => {
  if (!pathStore.paths.length) return null;
  return [...pathStore.paths].sort((a, b) =>
    b.lastModified.localeCompare(a.lastModified),
  )[0];
});

const latestExerciseTitle = computed(
  () => latestExercise.value?.title ?? 'Sem exercício recente',
);
const latestExerciseDate = computed(
  () => latestExercise.value?.createdAt ?? '--',
);
const latestPathName = computed(
  () => latestPath.value?.disciplineName ?? 'Sem percurso atualizado',
);
const latestPathDate = computed(() => latestPath.value?.lastModified ?? '--');

onMounted(async () => {
  await Promise.all([
    adminRequestStore.loadRequests(),
    exerciseStore.loadExercises(),
    pathStore.loadPaths(),
    questionLabStore.loadDocuments(),
  ]);
});
</script>
