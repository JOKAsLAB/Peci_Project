<template>
  <div v-if="authChecking" class="min-h-screen bg-background font-inter text-text-primary flex items-center justify-center">
    <div class="text-center">
      <i class="pi pi-spin pi-spinner text-3xl text-brand"></i>
      <p class="mt-4 text-text-secondary text-sm">A validar sessão...</p>
    </div>
  </div>

  <!-- Login Gate -->
  <LoginView v-else-if="!isAuthenticated" />

  <!-- Main App -->
  <div
    v-else
    class="min-h-screen bg-background font-inter text-text-primary flex relative overflow-hidden"
  >
    <div
      class="pointer-events-none absolute -top-28 -left-20 w-80 h-80 rounded-full blur-3xl bg-brand/10"
    ></div>
    <div
      class="pointer-events-none absolute -top-16 right-16 w-64 h-64 rounded-full blur-3xl bg-blue-500/10"
    ></div>

    <aside
      class="w-72 panel-surface border-r border-white/5 flex flex-col shrink-0 z-10"
    >
      <div class="p-8">
        <div class="flex items-center gap-3 mb-10">
          <div
            class="w-10 h-10 bg-brand rounded-xl flex items-center justify-center shadow-lg shadow-brand/20"
          >
            <span class="font-bold text-white text-xl">P</span>
          </div>
          <h1 class="text-xl font-bold tracking-tight">
            Docente<span class="text-brand">Panel</span>
          </h1>
        </div>

        <nav class="space-y-1">
          <p
            class="text-[10px] text-text-secondary uppercase tracking-widest font-semibold mb-2 mt-2 px-4"
          >
            Geral
          </p>
          <router-link to="/" class="nav-link">
            <i class="pi pi-th-large"></i> Dashboard
          </router-link>

          <p
            class="text-[10px] text-text-secondary uppercase tracking-widest font-semibold mb-2 mt-6 px-4"
          >
            Académico
          </p>
          <router-link to="/path-builder" class="nav-link">
            <i class="pi pi-map"></i> Percurso Base
          </router-link>
          <router-link to="/exercises" class="nav-link">
            <i class="pi pi-list"></i> Exercícios
          </router-link>

          <p
            class="text-[10px] text-text-secondary uppercase tracking-widest font-semibold mb-2 mt-6 px-4"
          >
            Ferramentas
          </p>
          <router-link to="/documents" class="nav-link">
            <i class="pi pi-file-pdf"></i> Documentos da UC
          </router-link>
          <router-link to="/question" class="nav-link">
            <i class="pi pi-sparkles"></i> Perguntas com LLM
          </router-link>
          <router-link to="/requests" class="nav-link">
            <i class="pi pi-inbox"></i> Pedidos ao Admin
          </router-link>
        </nav>
      </div>

      <div class="mt-auto p-8 border-t border-white/5">
        <div class="flex items-center gap-3">
          <div
            class="w-10 h-10 rounded-full bg-gray-800 border border-brand/50 flex items-center justify-center"
          >
            <i class="pi pi-user text-text-secondary"></i>
          </div>
          <div>
            <p class="text-sm font-semibold">
              {{ professorUser?.name || 'Prof' }}
            </p>
            <p
              class="text-[10px] text-text-secondary uppercase tracking-widest"
            >
              Docente LECI
            </p>
          </div>
        </div>
      </div>
    </aside>

    <main class="flex-1 flex flex-col h-screen overflow-hidden z-10">
      <header
        class="h-20 border-b border-white/5 bg-surface/70 backdrop-blur-md flex items-center justify-between px-10 shrink-0"
      >
        <h2
          class="text-lg font-medium text-text-secondary uppercase tracking-widest"
        >
          {{ $route.name }}
        </h2>
        <div class="flex items-center gap-6">
          <button
            class="text-text-secondary hover:text-white transition-colors"
          >
            <i class="pi pi-bell text-xl"></i>
          </button>
          <button
            @click="handleLogout"
            class="bg-surface border border-white/10 px-4 py-2 rounded-btn text-sm hover:border-brand/50 transition-all"
          >
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

<script setup>
import { computed, onMounted, ref } from 'vue';
import LoginView from './views/LoginView.vue';
import { useAuthStore } from './stores/authStore';

const authStore = useAuthStore();
const authChecking = ref(true)

const isAuthenticated = computed(() => authStore.isAuthenticated);
const professorUser = computed(() => authStore.user);

onMounted(async () => {
  try {
    await authStore.restoreSession()
  } finally {
    authChecking.value = false
  }
})

function handleLogout() {
  authStore.logout();
}
</script>

<style scoped>
@reference "./style.css";

.nav-link {
  @apply flex items-center gap-4 px-4 py-3 rounded-btn text-text-secondary hover:text-white hover:bg-white/8 border border-transparent hover:border-white/10 transition-all font-medium text-sm;
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
