<template>
  <div class="space-y-8">
    <div>
      <h3 class="text-2xl sm:text-3xl font-bold">Estatísticas</h3>
      <p class="text-text-secondary mt-1">Estatísticas e progresso da tua aprendizagem.</p>
    </div>

    <div v-if="studentStore.isLoading" class="flex items-center justify-center py-20">
      <i class="pi pi-spinner pi-spin text-brand text-4xl"></i>
    </div>

    <template v-else>
      <!-- Card do perfil -->
      <div class="bg-surface rounded-card border border-white/5 p-6 sm:p-8">
        <div class="flex flex-col sm:flex-row items-center sm:items-start gap-6">
          <div class="w-20 h-20 rounded-full bg-brand/10 border-2 border-brand/40 flex items-center justify-center text-2xl font-bold text-brand shrink-0">
            {{ userInitials }}
          </div>
          <div class="text-center sm:text-left flex-1 min-w-0">
            <h4 class="text-xl font-bold truncate">{{ authStore.user?.name || 'Aluno' }}</h4>
            <p class="text-text-secondary text-sm mt-1">{{ authStore.user?.email }}</p>
            <div class="flex flex-wrap justify-center sm:justify-start gap-2 mt-4">
              <span class="text-xs px-3 py-1.5 rounded-chip bg-brand/10 border border-brand/30 text-brand font-semibold">
                Nível {{ studentStore.profile?.current_level || 1 }}
              </span>
              <span class="text-xs px-3 py-1.5 rounded-chip bg-warning/10 border border-warning/30 text-warning font-semibold">
                <i class="pi pi-sun mr-1"></i>{{ studentStore.profile?.streak_days || 0 }} dias
              </span>
              <span class="text-xs px-3 py-1.5 rounded-chip bg-success/10 border border-success/30 text-success font-semibold">
                {{ studentStore.profile?.total_xp || 0 }} XP
              </span>
            </div>
          </div>
        </div>

        <!-- Barra de XP -->
        <div class="mt-6 pt-6 border-t border-white/5" v-if="studentStore.profile">
          <div class="flex justify-between text-sm mb-2">
            <span class="text-text-secondary">Progresso para Nível {{ (studentStore.profile.current_level || 1) + 1 }}</span>
            <span>{{ studentStore.profile.xp_in_current_level || 0 }} / {{ studentStore.profile.xp_for_next_level || 100 }} XP</span>
          </div>
          <div class="w-full bg-background rounded-full h-2.5 overflow-hidden">
            <div class="h-full bg-brand rounded-full transition-all duration-700" :style="{ width: xpPercentage + '%' }"></div>
          </div>
        </div>
      </div>

      <!-- Stats grid -->
      <div class="grid grid-cols-2 sm:grid-cols-4 gap-3 sm:gap-6">
        <div class="bg-surface p-4 sm:p-6 rounded-card border border-white/5 text-center">
          <i class="pi pi-star text-brand text-2xl mb-2 block"></i>
          <p class="text-2xl sm:text-3xl font-bold text-brand">{{ studentStore.profile?.current_level || 1 }}</p>
          <p class="text-text-secondary text-xs sm:text-sm mt-1">Nível</p>
        </div>
        <div class="bg-surface p-4 sm:p-6 rounded-card border border-white/5 text-center">
          <i class="pi pi-bolt text-success text-2xl mb-2 block"></i>
          <p class="text-2xl sm:text-3xl font-bold text-success">{{ studentStore.profile?.total_xp || 0 }}</p>
          <p class="text-text-secondary text-xs sm:text-sm mt-1">XP Total</p>
        </div>
        <div class="bg-surface p-4 sm:p-6 rounded-card border border-white/5 text-center">
          <i class="pi pi-sun text-warning text-2xl mb-2 block"></i>
          <p class="text-2xl sm:text-3xl font-bold text-warning">{{ studentStore.profile?.streak_days || 0 }}</p>
          <p class="text-text-secondary text-xs sm:text-sm mt-1">Dias seguidos</p>
        </div>
        <div class="bg-surface p-4 sm:p-6 rounded-card border border-white/5 text-center">
          <i class="pi pi-chart-bar text-info text-2xl mb-2 block"></i>
          <p class="text-2xl sm:text-3xl font-bold text-info">{{ studentStore.topicStats.length }}</p>
          <p class="text-text-secondary text-xs sm:text-sm mt-1">Tópicos estudados</p>
        </div>
      </div>

      <!-- Estatísticas por cadeira → tópico -->
      <div v-if="statsByUnit.length > 0" class="space-y-4">
        <div
          v-for="group in statsByUnit"
          :key="group.name"
          class="bg-surface rounded-card border border-white/5 p-6"
        >
          <!-- Cadeira header -->
          <div class="flex items-center justify-between gap-3 mb-4">
            <div class="flex items-center gap-2 min-w-0">
              <div class="w-7 h-7 shrink-0 rounded-btn bg-brand/10 flex items-center justify-center">
                <i class="pi pi-book text-brand text-xs"></i>
              </div>
              <h4 class="font-bold truncate">{{ group.name }}</h4>
            </div>
            <span
              class="text-sm font-bold shrink-0"
              :class="unitAccuracy(group) >= 70 ? 'text-success' : unitAccuracy(group) >= 40 ? 'text-warning' : 'text-error'"
            >{{ unitAccuracy(group) }}% médio</span>
          </div>

          <!-- Tópicos -->
          <div class="space-y-3">
            <div v-for="stat in group.stats" :key="stat.topic_name + stat.id_uc">
              <div class="flex items-center justify-between mb-1 gap-3">
                <span class="text-sm font-medium truncate">{{ stat.topic_name }}</span>
                <div class="flex items-center gap-2 shrink-0">
                  <span class="text-xs text-text-secondary">{{ stat.correct_count }}/{{ stat.total_answered }}</span>
                  <span
                    class="text-sm font-bold w-11 text-right"
                    :class="stat.accuracy >= 70 ? 'text-success' : stat.accuracy >= 40 ? 'text-warning' : 'text-error'"
                  >{{ stat.accuracy }}%</span>
                </div>
              </div>
              <div class="w-full bg-background rounded-full h-1.5 overflow-hidden">
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

      <div v-if="statsByUnit.length === 0" class="bg-surface rounded-card border border-white/5 p-10 text-center">
        <i class="pi pi-chart-bar text-3xl text-text-secondary/40 mb-3 block"></i>
        <p class="text-text-secondary mb-4">Ainda não há estatísticas. Começa a praticar!</p>
        <router-link
          to="/aluno/exercicios"
          class="inline-block px-6 py-3 bg-brand text-white rounded-btn font-semibold hover:bg-brand/80 transition-all"
        >
          Começar a Praticar
        </router-link>
      </div>
    </template>
  </div>
</template>

<script setup>
import { computed, onMounted } from 'vue'
import { useStudentStore } from '../stores/studentStore'
import { useAuthStore } from '../../../stores/authStore'

const studentStore = useStudentStore()
const authStore = useAuthStore()

const userInitials = computed(() =>
  (authStore.user?.name || 'A')
    .split(' ')
    .map(p => p[0])
    .slice(0, 2)
    .join('')
    .toUpperCase()
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
    studentStore.loadTopicStats(),
  ])
})
</script>
