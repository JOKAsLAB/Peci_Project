<template>
  <div class="space-y-8">
    <div>
      <p class="text-brand font-bold text-sm uppercase tracking-widest mb-1">
        Visão Geral
      </p>
      <h3 class="text-3xl font-bold">Dashboard</h3>
      <p class="text-text-secondary mt-1">
        Resumo geral da plataforma de aprendizagem.
      </p>
    </div>

    <div class="grid grid-cols-4 gap-6">
      <div class="bg-surface p-6 rounded-card border border-white/5">
        <div class="flex items-center gap-3 mb-3">
          <div
            class="w-10 h-10 rounded-btn bg-brand/10 flex items-center justify-center"
          >
            <i class="pi pi-book text-brand"></i>
          </div>
          <p class="text-text-secondary text-sm">Disciplinas Ativas</p>
        </div>
        <p class="text-3xl font-bold text-brand">
          {{ disciplineStore.activeDisciplines.length }}
        </p>
      </div>
      <div class="bg-surface p-6 rounded-card border border-white/5">
        <div class="flex items-center gap-3 mb-3">
          <div
            class="w-10 h-10 rounded-btn bg-success/10 flex items-center justify-center"
          >
            <i class="pi pi-users text-success"></i>
          </div>
          <p class="text-text-secondary text-sm">Alunos Registados</p>
        </div>
        <p class="text-3xl font-bold text-success">
          {{ userStore.students.length }}
        </p>
      </div>
      <div class="bg-surface p-6 rounded-card border border-white/5">
        <div class="flex items-center gap-3 mb-3">
          <div
            class="w-10 h-10 rounded-btn bg-warning/10 flex items-center justify-center"
          >
            <i class="pi pi-briefcase text-warning"></i>
          </div>
          <p class="text-text-secondary text-sm">Docentes</p>
        </div>
        <p class="text-3xl font-bold text-warning">
          {{ userStore.professors.length }}
        </p>
      </div>
      <div class="bg-surface p-6 rounded-card border border-white/5">
        <div class="flex items-center gap-3 mb-3">
          <div
            class="w-10 h-10 rounded-btn bg-error/10 flex items-center justify-center"
          >
            <i class="pi pi-ban text-error"></i>
          </div>
          <p class="text-text-secondary text-sm">Utilizadores Inativos</p>
        </div>
        <p class="text-3xl font-bold text-error">
          {{ userStore.inactiveUsers.length }}
        </p>
      </div>
    </div>

    <!-- Disciplinas recentes -->
    <div class="grid grid-cols-2 gap-6">
      <div class="bg-surface rounded-card border border-white/5 p-6">
        <h4 class="text-lg font-bold mb-4 flex items-center gap-2">
          <i class="pi pi-book text-brand"></i> Disciplinas Ativas
        </h4>
        <div class="space-y-3">
          <div
            v-for="d in disciplineStore.activeDisciplines"
            :key="d.id"
            class="flex items-center justify-between bg-background p-4 rounded-btn border border-white/5"
          >
            <div>
              <p class="font-bold text-sm">{{ d.acronym }} — {{ d.name }}</p>
              <p class="text-text-secondary text-xs">
                {{ (d.professors || []).join(', ') }} · {{ d.semester }}
              </p>
            </div>
            <div class="text-right">
              <p class="text-brand font-bold text-sm">
                {{ d.students }} alunos
              </p>
              <p class="text-text-secondary text-xs">{{ d.code }}</p>
            </div>
          </div>
        </div>
      </div>

      <div class="bg-surface rounded-card border border-white/5 p-6">
        <h4 class="text-lg font-bold mb-4 flex items-center gap-2">
          <i class="pi pi-chart-bar text-success"></i> Resumo por Papel
        </h4>
        <div class="space-y-4">
          <div class="space-y-2">
            <div class="flex justify-between text-sm">
              <span class="text-text-secondary">Alunos</span>
              <span class="text-brand font-bold">{{
                userStore.students.length
              }}</span>
            </div>
            <div class="h-3 bg-background rounded-full overflow-hidden">
              <div
                class="h-full bg-brand rounded-full"
                :style="{
                  width:
                    (userStore.students.length / userStore.users.length) * 100 +
                    '%',
                }"
              ></div>
            </div>
          </div>
          <div class="space-y-2">
            <div class="flex justify-between text-sm">
              <span class="text-text-secondary">Docentes</span>
              <span class="text-warning font-bold">{{
                userStore.professors.length
              }}</span>
            </div>
            <div class="h-3 bg-background rounded-full overflow-hidden">
              <div
                class="h-full bg-warning rounded-full"
                :style="{
                  width:
                    (userStore.professors.length / userStore.users.length) *
                      100 +
                    '%',
                }"
              ></div>
            </div>
          </div>
          <div class="space-y-2">
            <div class="flex justify-between text-sm">
              <span class="text-text-secondary">Inativos</span>
              <span class="text-error font-bold">{{
                userStore.inactiveUsers.length
              }}</span>
            </div>
            <div class="h-3 bg-background rounded-full overflow-hidden">
              <div
                class="h-full bg-error rounded-full"
                :style="{
                  width:
                    (userStore.inactiveUsers.length / userStore.users.length) *
                      100 +
                    '%',
                }"
              ></div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { onMounted } from 'vue';
import { useDisciplineStore } from '../stores/disciplineStore';
import { useUserStore } from '../stores/userStore';

const disciplineStore = useDisciplineStore();
const userStore = useUserStore();

onMounted(async () => {
  await Promise.all([
    disciplineStore.loadDisciplines(),
    userStore.loadUsers(),
  ]);
});
</script>
