<template>
  <div>
  <div class="space-y-8">
    <div>
      <h3 class="text-2xl sm:text-3xl font-bold">
        Olá, {{ firstName }}!
      </h3>
      <p class="text-text-secondary mt-1">Continua a aprender e a ganhar pontos.</p>
    </div>

    <div v-if="studentStore.isLoading" class="flex items-center justify-center py-20">
      <i class="pi pi-spinner pi-spin text-brand text-4xl"></i>
    </div>

    <template v-else>
      <!-- Stats -->
      <div class="grid grid-cols-2 sm:grid-cols-4 gap-3 sm:gap-6">
        <div class="bg-surface p-4 sm:p-6 rounded-card border border-white/5">
          <div class="flex items-center gap-2 mb-3">
            <div class="w-8 h-8 sm:w-10 sm:h-10 shrink-0 rounded-btn bg-brand/10 flex items-center justify-center">
              <i class="pi pi-star text-brand text-sm sm:text-base"></i>
            </div>
            <p class="text-text-secondary text-xs sm:text-sm leading-tight">Nível</p>
          </div>
          <p class="text-2xl sm:text-3xl font-bold text-brand">{{ studentStore.profile?.current_level || 1 }}</p>
        </div>

        <div class="bg-surface p-4 sm:p-6 rounded-card border border-white/5">
          <div class="flex items-center gap-2 mb-3">
            <div class="w-8 h-8 sm:w-10 sm:h-10 shrink-0 rounded-btn bg-success/10 flex items-center justify-center">
              <i class="pi pi-bolt text-success text-sm sm:text-base"></i>
            </div>
            <p class="text-text-secondary text-xs sm:text-sm leading-tight">XP Total</p>
          </div>
          <p class="text-2xl sm:text-3xl font-bold text-success">{{ studentStore.profile?.total_xp || 0 }}</p>
        </div>

        <div class="bg-surface p-4 sm:p-6 rounded-card border border-white/5">
          <div class="flex items-center gap-2 mb-3">
            <div class="w-8 h-8 sm:w-10 sm:h-10 shrink-0 rounded-btn bg-warning/10 flex items-center justify-center">
              <i class="pi pi-sun text-warning text-sm sm:text-base"></i>
            </div>
            <p class="text-text-secondary text-xs sm:text-sm leading-tight">Sequência</p>
          </div>
          <p class="text-2xl sm:text-3xl font-bold text-warning">
            {{ studentStore.profile?.streak_days || 0 }}<span class="text-sm ml-1">dias</span>
          </p>
        </div>

        <div class="bg-surface p-4 sm:p-6 rounded-card border border-white/5">
          <div class="flex items-center gap-2 mb-3">
            <div class="w-8 h-8 sm:w-10 sm:h-10 shrink-0 rounded-btn bg-info/10 flex items-center justify-center">
              <i class="pi pi-chart-bar text-info text-sm sm:text-base"></i>
            </div>
            <p class="text-text-secondary text-xs sm:text-sm leading-tight">Hoje</p>
          </div>
          <p class="text-2xl sm:text-3xl font-bold text-info">
            {{ studentStore.dailyStatus?.done_today || 0 }}<span class="text-sm text-text-secondary ml-1">/{{ studentStore.dailyStatus?.daily_limit || 5 }}</span>
          </p>
        </div>
      </div>

      <!-- XP progress bar -->
      <div class="bg-surface rounded-card border border-white/5 p-6" v-if="studentStore.profile">
        <div class="flex items-center justify-between mb-3">
          <p class="font-semibold">Progresso para o Nível {{ (studentStore.profile.current_level || 1) + 1 }}</p>
          <p class="text-text-secondary text-sm">
            {{ studentStore.profile.xp_in_current_level || 0 }} / {{ studentStore.profile.xp_for_next_level || 100 }} XP
          </p>
        </div>
        <div class="w-full bg-background rounded-full h-3 overflow-hidden">
          <div
            class="h-full bg-brand rounded-full transition-all duration-700"
            :style="{ width: xpPercentage + '%' }"
          ></div>
        </div>
      </div>

      <!-- Ações rápidas -->
      <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <router-link
          to="/aluno/exercicios"
          class="bg-surface rounded-card border border-white/5 p-6 hover:border-brand/40 transition-all group"
        >
          <div class="flex items-center gap-4">
            <div class="w-12 h-12 rounded-btn bg-brand/10 flex items-center justify-center group-hover:bg-brand/20 transition-all shrink-0">
              <i class="pi pi-list text-brand text-xl"></i>
            </div>
            <div class="min-w-0">
              <p class="font-bold">Praticar</p>
              <p class="text-text-secondary text-sm">Exercícios de escolha múltipla e V/F</p>
            </div>
            <i class="pi pi-arrow-right ml-auto text-text-secondary group-hover:text-brand transition-colors shrink-0"></i>
          </div>
        </router-link>

        <router-link
          to="/aluno/percursos"
          class="bg-surface rounded-card border border-white/5 p-6 hover:border-blue-400/40 transition-all group"
        >
          <div class="flex items-center gap-4">
            <div class="w-12 h-12 rounded-btn bg-blue-500/10 flex items-center justify-center group-hover:bg-blue-500/20 transition-all shrink-0">
              <i class="pi pi-map text-blue-400 text-xl"></i>
            </div>
            <div class="min-w-0">
              <p class="font-bold">Percursos</p>
              <p class="text-text-secondary text-sm">Aprende por tópicos estruturados</p>
            </div>
            <i class="pi pi-arrow-right ml-auto text-text-secondary group-hover:text-blue-400 transition-colors shrink-0"></i>
          </div>
        </router-link>

        <router-link
          to="/aluno/quiz"
          class="bg-surface rounded-card border border-white/5 p-6 hover:border-warning/40 transition-all group"
        >
          <div class="flex items-center gap-4">
            <div class="w-12 h-12 rounded-btn bg-warning/10 flex items-center justify-center group-hover:bg-warning/20 transition-all shrink-0">
              <i class="pi pi-bolt text-warning text-xl"></i>
            </div>
            <div class="min-w-0">
              <p class="font-bold">Quiz em Direto</p>
              <p class="text-text-secondary text-sm">Compete com os teus colegas</p>
            </div>
            <i class="pi pi-arrow-right ml-auto text-text-secondary group-hover:text-warning transition-colors shrink-0"></i>
          </div>
        </router-link>

        <router-link
          to="/aluno/perfil"
          class="bg-surface rounded-card border border-white/5 p-6 hover:border-purple-400/40 transition-all group"
        >
          <div class="flex items-center gap-4">
            <div class="w-12 h-12 rounded-btn bg-purple-500/10 flex items-center justify-center group-hover:bg-purple-500/20 transition-all shrink-0">
              <i class="pi pi-user text-purple-400 text-xl"></i>
            </div>
            <div class="min-w-0">
              <p class="font-bold">O Meu Perfil</p>
              <p class="text-text-secondary text-sm">Estatísticas e progresso</p>
            </div>
            <i class="pi pi-arrow-right ml-auto text-text-secondary group-hover:text-purple-400 transition-colors shrink-0"></i>
          </div>
        </router-link>
      </div>

      <!-- Performance por cadeira -->
      <div class="bg-surface rounded-card border border-white/5 p-6" v-if="statsByUnit.length > 0">
        <h4 class="text-lg font-bold mb-4 flex items-center gap-2">
          <i class="pi pi-chart-bar text-brand"></i> Performance
        </h4>
        <div class="space-y-5">
          <div v-for="group in statsByUnit" :key="group.name">
            <!-- Cadeira header -->
            <div class="flex items-center gap-2 mb-2">
              <i class="pi pi-book text-brand text-xs"></i>
              <p class="text-xs font-bold text-brand uppercase tracking-widest truncate">{{ group.name }}</p>
              <div class="flex-1 border-t border-white/10"></div>
              <span class="text-xs text-text-secondary shrink-0">{{ unitAccuracy(group) }}% médio</span>
            </div>
            <!-- Tópicos da cadeira -->
            <div class="space-y-2 pl-4">
              <div
                v-for="stat in group.stats"
                :key="stat.topic_name + stat.id_uc"
                class="bg-background rounded-btn px-3 py-2.5 border border-white/5"
              >
                <div class="flex items-center justify-between gap-3 mb-1.5">
                  <p class="font-medium text-sm truncate">{{ stat.topic_name }}</p>
                  <span
                    class="text-sm font-bold shrink-0"
                    :class="stat.accuracy >= 70 ? 'text-success' : stat.accuracy >= 40 ? 'text-warning' : 'text-error'"
                  >{{ stat.accuracy }}%</span>
                </div>
                <div class="w-full bg-surface rounded-full h-1 overflow-hidden">
                  <div
                    class="h-full rounded-full transition-all"
                    :class="stat.accuracy >= 70 ? 'bg-success' : stat.accuracy >= 40 ? 'bg-warning' : 'bg-error'"
                    :style="{ width: stat.accuracy + '%' }"
                  ></div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </template>
  </div>
  </div>
</template>

<script setup>
import { computed, onMounted } from 'vue'
import { useStudentStore } from '../stores/studentStore'
import { useAuthStore } from '../../../stores/authStore'

const studentStore = useStudentStore()
const authStore = useAuthStore()

const firstName = computed(() =>
  (authStore.user?.name || 'Aluno').split(' ')[0]
)

const xpPercentage = computed(() => {
  if (!studentStore.profile) return 0
  const xpIn = studentStore.profile.xp_in_current_level || 0
  const xpFor = studentStore.profile.xp_for_next_level || 100
  return Math.min(100, Math.round((xpIn / xpFor) * 100))
})

const statsByUnit = computed(() => {
  const groups = {}
  for (const stat of studentStore.topicStats) {
    const key = stat.course_unit_name || 'Sem cadeira'
    if (!groups[key]) groups[key] = []
    groups[key].push(stat)
  }
  return Object.entries(groups).map(([name, stats]) => ({ name, stats }))
})

function unitAccuracy(group) {
  const total = group.stats.reduce((s, t) => s + t.accuracy, 0)
  return Math.round(total / group.stats.length)
}

onMounted(async () => {
  await Promise.all([
    studentStore.loadProfile(),
    studentStore.loadDailyStatus(),
    studentStore.loadTopicStats(),
  ])

})
</script>
