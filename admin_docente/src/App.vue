<template>
  <div v-if="authChecking" class="min-h-screen bg-background font-inter text-text-primary flex items-center justify-center">
    <div class="text-center">
      <i class="pi pi-spin pi-spinner text-3xl text-brand"></i>
      <p class="mt-4 text-text-secondary text-sm">A validar sessão...</p>
    </div>
  </div>

  <LoginView v-else-if="!isAuthenticated" />

  <div v-else class="min-h-screen bg-background font-inter text-text-primary flex relative overflow-hidden">
    <div class="pointer-events-none absolute -top-28 -left-20 w-80 h-80 rounded-full blur-3xl bg-brand/10"></div>
    <div class="pointer-events-none absolute -top-16 right-16 w-64 h-64 rounded-full blur-3xl bg-blue-500/10"></div>

    <aside class="w-72 panel-surface border-r border-white/5 flex flex-col shrink-0 z-10">
      <div class="p-8">
        <div class="flex items-center gap-3 mb-10">
          <div class="w-10 h-10 bg-brand rounded-xl flex items-center justify-center shadow-lg shadow-brand/20">
            <span class="font-bold text-white text-xl">{{ activeRole === 'Admin' ? 'A' : 'P' }}</span>
          </div>
          <h1 class="text-xl font-bold tracking-tight">
            {{ activeRole === 'Admin' ? 'Admin' : 'Docente' }}<span class="text-brand">Hub</span>
          </h1>
        </div>

        <nav class="space-y-2">
          <router-link v-for="item in navItems" :key="item.to" :to="item.to" class="nav-link">
            <i :class="item.icon"></i>
            {{ item.label }}
          </router-link>
        </nav>
      </div>

      <div class="mt-auto p-8 border-t border-white/5">
        <div class="flex items-center gap-3">
          <div class="w-10 h-10 rounded-full bg-gray-800 border border-brand/50 flex items-center justify-center font-bold text-sm">
            {{ userInitials }}
          </div>
          <div>
            <p class="text-sm font-semibold">{{ authStore.user?.name || 'Utilizador' }}</p>
            <p class="text-[10px] text-text-secondary uppercase tracking-widest">
              {{ activeRole === 'Admin' ? 'Administrador' : 'Professor' }}
            </p>
          </div>
        </div>
      </div>
    </aside>

    <main class="flex-1 flex flex-col h-screen overflow-hidden z-10">
      <header class="h-20 border-b border-white/5 bg-surface/70 backdrop-blur-md flex items-center justify-between px-10 shrink-0">
        <h2 class="text-lg font-medium text-text-secondary uppercase tracking-widest">
          {{ String(route.name || 'Dashboard') }}
        </h2>

        <div class="flex items-center gap-6">
          <span class="text-xs px-3 py-1.5 rounded-chip border border-brand/40 text-brand">
            {{ activeRole }}
          </span>
          <button @click="handleLogout" class="bg-surface border border-white/10 px-4 py-2 rounded-btn text-sm hover:border-brand/50 transition-all">
            Terminar Sessão
          </button>
        </div>
      </header>

      <section class="flex-1 overflow-y-auto p-10">
        <router-view v-slot="{ Component }">
          <transition name="fade" mode="out-in">
            <component :is="Component" />
          </transition>
        </router-view>
      </section>
    </main>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import LoginView from './views/LoginView.vue'
import { useAuthStore } from './stores/authStore'

interface NavItem {
  to: string
  label: string
  icon: string
}

const adminNav: NavItem[] = [
  { to: '/admin', label: 'Dashboard', icon: 'pi pi-th-large' },
  { to: '/admin/disciplines', label: 'Disciplinas', icon: 'pi pi-book' },
  { to: '/admin/users', label: 'Utilizadores', icon: 'pi pi-users' },
  { to: '/admin/approvals', label: 'Aprovações', icon: 'pi pi-shield' },
  { to: '/admin/requests', label: 'Pedidos Admin', icon: 'pi pi-inbox' },
]

const professorNav: NavItem[] = [
  { to: '/professor', label: 'Dashboard', icon: 'pi pi-th-large' },
  { to: '/professor/path-builder', label: 'Percursos', icon: 'pi pi-map' },
  { to: '/professor/exercises', label: 'Exercícios', icon: 'pi pi-list' },
  { to: '/professor/documents', label: 'Documentos', icon: 'pi pi-file-pdf' },
  { to: '/professor/question', label: 'Perguntas com LLM', icon: 'pi pi-sparkles' },
  { to: '/professor/requests', label: 'Pedidos ao Admin', icon: 'pi pi-inbox' },
]

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const authChecking = ref(true)

const isAuthenticated = computed(() => authStore.isAuthenticated)
const activeRole = computed(() => authStore.activeRole || 'Professor')
const navItems = computed(() => (activeRole.value === 'Admin' ? adminNav : professorNav))
const userInitials = computed(() => {
  const parts = (authStore.user?.name || 'User').split(' ').map((chunk) => chunk[0]).slice(0, 2)
  return parts.join('').toUpperCase()
})

onMounted(async () => {
  try {
    await authStore.restoreSession()
    if (authStore.isAuthenticated && route.path === '/') {
      await router.replace(authStore.activeRole === 'Admin' ? '/admin' : '/professor')
    }
  } finally {
    authChecking.value = false
  }
})

async function handleLogout(): Promise<void> {
  await authStore.logout()
  await router.replace('/')
}
</script>

<style scoped>
@reference "./style.css";

.nav-link {
  @apply flex items-center gap-4 px-4 py-3.5 rounded-btn text-text-secondary hover:text-white hover:bg-white/8 border border-transparent hover:border-white/10 transition-all font-medium;
}
.nav-link.router-link-active {
  @apply bg-brand/10 text-brand border-brand/40;
}
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>