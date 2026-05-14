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

  <!-- ─── Onboarding Modal ──────────────────────────────────────────────────── -->
  <div v-if="showOnboarding" class="fixed inset-0 z-50 flex items-center justify-center p-4">
    <div class="absolute inset-0 bg-black/70 backdrop-blur-sm"></div>
    <div class="relative bg-surface border border-white/10 rounded-card w-full max-w-sm shadow-2xl z-10 overflow-hidden">
      <div class="p-7 space-y-5 max-h-[90vh] overflow-y-auto">

        <!-- Andy avatar + título -->
        <div class="flex flex-col items-center text-center gap-3">
          <div class="w-20 h-20 rounded-2xl bg-background border border-brand/40 p-2.5 flex items-center justify-center">
            <img src="/chatbot.png" alt="Andy" class="w-full h-full object-contain" />
          </div>
          <div>
            <h4 class="text-xl font-bold">Olá! Sou o Andy 👋</h4>
            <p class="text-text-secondary text-sm mt-1 leading-relaxed">
              O teu companheiro de estudo com IA.<br>
              Abre-me depois de qualquer exercício para esclarecer dúvidas e aprender melhor.
            </p>
          </div>
        </div>

        <div class="border-t border-white/10"></div>

        <!-- Regra 1: bónus XP -->
        <div class="space-y-2.5">
          <div class="flex items-center gap-2">
            <div class="w-7 h-7 rounded-btn bg-orange-500/15 flex items-center justify-center shrink-0">
              <i class="pi pi-fire text-orange-400 text-sm"></i>
            </div>
            <p class="font-bold text-sm">5 exercícios diários = Bónus XP</p>
          </div>
          <p class="text-text-secondary text-xs leading-relaxed pl-9">
            Os primeiros 5 por dia têm <span class="text-orange-400 font-semibold">1.5× XP de bónus</span> e mantêm o streak:
          </p>
          <!-- Tabela XP -->
          <div class="bg-background rounded-btn p-3 space-y-2 ml-9">
            <div class="flex items-center gap-2 text-xs">
              <span class="w-12 text-center py-0.5 rounded bg-success/15 text-success font-semibold">Fácil</span>
              <span class="text-text-secondary">10 XP</span>
              <i class="pi pi-arrow-right text-text-secondary" style="font-size:9px"></i>
              <span class="text-orange-400 font-bold">15 XP</span>
              <span class="text-text-secondary">com bónus</span>
            </div>
            <div class="flex items-center gap-2 text-xs">
              <span class="w-12 text-center py-0.5 rounded bg-warning/15 text-warning font-semibold">Médio</span>
              <span class="text-text-secondary">20 XP</span>
              <i class="pi pi-arrow-right text-text-secondary" style="font-size:9px"></i>
              <span class="text-orange-400 font-bold">30 XP</span>
              <span class="text-text-secondary">com bónus</span>
            </div>
            <div class="flex items-center gap-2 text-xs">
              <span class="w-12 text-center py-0.5 rounded bg-error/15 text-error font-semibold">Difícil</span>
              <span class="text-text-secondary">35 XP</span>
              <i class="pi pi-arrow-right text-text-secondary" style="font-size:9px"></i>
              <span class="text-orange-400 font-bold">53 XP</span>
              <span class="text-text-secondary">com bónus</span>
            </div>
          </div>
        </div>

        <!-- Regra 2: progressão -->
        <div class="flex items-start gap-2.5">
          <div class="w-7 h-7 rounded-btn bg-success/15 flex items-center justify-center shrink-0 mt-0.5">
            <i class="pi pi-chart-line text-success text-sm"></i>
          </div>
          <div>
            <p class="font-bold text-sm">Progressão por dificuldade</p>
            <p class="text-text-secondary text-xs mt-0.5 leading-relaxed">
              Cada tópico segue Fácil → Médio → Difícil. Após os 5, podes continuar a praticar com XP normal.
            </p>
          </div>
        </div>

        <!-- CTA -->
        <button
          @click="showOnboarding = false"
          class="w-full py-3.5 bg-brand text-white rounded-btn font-bold hover:bg-brand/80 transition-all"
        >
          Vamos começar!
        </button>
      </div>
    </div>
  </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useStudentStore } from '../stores/studentStore'
import { useAuthStore } from '../../../stores/authStore'

const studentStore = useStudentStore()
const authStore = useAuthStore()

const showOnboarding = ref(false)

function checkOnboarding() {
  const userId = authStore.user?.id
  if (!userId) return
  const key = `onboarding_shown_${userId}`
  if (!localStorage.getItem(key)) {
    localStorage.setItem(key, '1')
    showOnboarding.value = true
  }
}

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
  checkOnboarding()
})
</script>
