<template>
  <div
    v-if="authChecking || (isAuthenticated && !isRouteReady)"
    class="min-h-screen bg-background font-inter text-text-primary flex items-center justify-center"
  >
    <div class="text-center">
      <i class="pi pi-spin pi-spinner text-3xl text-brand"></i>
      <p class="mt-4 text-text-secondary text-sm">A validar sessão...</p>
    </div>
  </div>

  <RouterView v-else-if="!isAuthenticated" />

  <div
    v-else
    class="min-h-screen bg-background font-inter text-text-primary flex relative overflow-hidden"
  >
    <!-- Background blobs -->
    <div
      class="pointer-events-none absolute -top-28 -left-20 w-80 h-80 rounded-full blur-3xl bg-brand/10"
    ></div>
    <div
      class="pointer-events-none absolute -top-16 right-16 w-64 h-64 rounded-full blur-3xl bg-blue-500/10"
    ></div>

    <!-- Mobile backdrop -->
    <div
      v-if="sidebarOpen"
      class="fixed inset-0 z-30 bg-black/60 backdrop-blur-sm lg:hidden"
      @click="sidebarOpen = false"
    ></div>

    <!-- Sidebar -->
    <aside
      class="fixed lg:static inset-y-0 left-0 w-72 panel-surface border-r border-white/5 flex flex-col shrink-0 z-40 transition-transform duration-300 lg:translate-x-0"
      :class="sidebarOpen ? 'translate-x-0' : '-translate-x-full'"
    >
      <!-- Logo + close button (mobile) -->
      <div
        class="h-20 border-b border-white/5 shrink-0 flex items-center justify-between px-6"
      >
        <img
          src="/logo_horizontal.png"
          alt="LogicStreak"
          class="h-10 w-auto object-contain"
        />
        <button
          class="lg:hidden flex items-center justify-center w-8 h-8 rounded-btn text-text-secondary hover:text-white transition-colors"
          @click="sidebarOpen = false"
        >
          <i class="pi pi-times"></i>
        </button>
      </div>

      <!-- Nav -->
      <div class="p-6 flex-1 overflow-y-auto">
        <nav class="space-y-2">
          <router-link
            v-for="item in navItems"
            :key="item.to"
            :to="item.to"
            class="nav-link"
            @click="sidebarOpen = false"
          >
            <i :class="item.icon"></i>
            {{ item.label }}
          </router-link>
        </nav>
      </div>

      <!-- User footer -->
      <div class="p-6 border-t border-white/5 shrink-0">
        <div class="flex items-center gap-3">
          <div
            class="w-10 h-10 rounded-full bg-gray-800 border border-brand/50 flex items-center justify-center font-bold text-sm shrink-0"
          >
            {{ userInitials }}
          </div>
          <div class="min-w-0">
            <p class="text-sm font-semibold truncate">
              {{ authStore.user?.name || 'Utilizador' }}
            </p>
            <p
              class="text-[10px] text-text-secondary uppercase tracking-widest"
            >
              {{ activeRole === 'Admin' ? 'Administrador' : activeRole === 'Student' ? 'Aluno' : 'Professor' }}
            </p>
          </div>
        </div>
      </div>
    </aside>

    <!-- Main -->
    <main
      class="flex-1 flex flex-col h-screen overflow-hidden z-10 min-w-0"
    >
      <header
        class="h-16 lg:h-20 border-b border-white/5 bg-surface/70 backdrop-blur-md flex items-center justify-between px-4 lg:px-10 shrink-0 gap-3"
      >
        <!-- Hamburger (mobile only) -->
        <button
          class="lg:hidden flex items-center justify-center w-9 h-9 shrink-0 rounded-btn border border-white/10 bg-surface text-text-secondary hover:text-white hover:border-brand/50 transition-all"
          @click="sidebarOpen = true"
        >
          <i class="pi pi-bars"></i>
        </button>

        <h2
          class="text-sm lg:text-lg font-medium text-text-secondary uppercase tracking-widest truncate flex-1 min-w-0"
        >
          {{ String(route.name || 'Dashboard') }}
        </h2>

        <div class="flex items-center gap-2 lg:gap-6 shrink-0">
          <span
            class="hidden sm:inline-flex text-xs px-3 py-1.5 rounded-chip border border-brand/40 text-brand"
          >
            {{ activeRole === 'Admin' ? 'Administrador' : activeRole === 'Student' ? 'Aluno' : 'Professor' }}
          </span>
          <button
            @click="handleLogout"
            class="bg-surface border border-white/10 px-3 py-2 rounded-btn text-xs lg:text-sm hover:border-brand/50 transition-all"
          >
            <i class="pi pi-sign-out lg:hidden"></i>
            <span class="hidden lg:inline">Terminar Sessão</span>
          </button>
        </div>
      </header>

      <section class="flex-1 overflow-y-auto p-4 sm:p-6 lg:p-10">
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
import './App.css';
import { computed, onMounted, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useAuthStore } from './stores/authStore';
import { setupAuthInterceptor } from './services/http';

interface NavItem {
  to: string;
  label: string;
  icon: string;
}

const adminNav: NavItem[] = [
  { to: '/admin', label: 'Dashboard', icon: 'pi pi-th-large' },
  { to: '/admin/disciplines', label: 'Disciplinas', icon: 'pi pi-book' },
  { to: '/admin/users', label: 'Utilizadores', icon: 'pi pi-users' },
  { to: '/admin/approvals', label: 'Aprovações', icon: 'pi pi-shield' },
  { to: '/admin/requests', label: 'Pedidos Admin', icon: 'pi pi-inbox' },
];

const professorNav: NavItem[] = [
  { to: '/professor', label: 'Dashboard', icon: 'pi pi-th-large' },
  { to: '/professor/exercises', label: 'Banco de Perguntas', icon: 'pi pi-list' },
  { to: '/professor/path-builder', label: 'Percursos', icon: 'pi pi-map' },
  { to: '/professor/documents', label: 'Documentos', icon: 'pi pi-file-pdf' },
  { to: '/professor/question', label: 'Geração de Perguntas', icon: 'pi pi-sparkles' },
  { to: '/professor/quiz', label: 'Quizz ao Vivo', icon: 'pi pi-bolt' },
  { to: '/professor/requests', label: 'Pedidos ao Admin', icon: 'pi pi-inbox' },
  { to: '/professor/reported', label: 'Perguntas Reportadas', icon: 'pi pi-flag' },
];

const studentNav: NavItem[] = [
  { to: '/aluno', label: 'Dashboard', icon: 'pi pi-th-large' },
  { to: '/aluno/exercicios', label: 'Praticar', icon: 'pi pi-list' },
  { to: '/aluno/percursos', label: 'Percursos', icon: 'pi pi-map' },
  { to: '/aluno/quiz', label: 'Quizz ao Vivo', icon: 'pi pi-bolt' },
  { to: '/aluno/perfil', label: 'Estatísticas', icon: 'pi pi-chart-bar' },
];

const route = useRoute();
const router = useRouter();
const authStore = useAuthStore();
const authChecking = ref(true);
const sidebarOpen = ref(false);

const isAuthenticated = computed(() => authStore.isAuthenticated);
const activeRole = computed(() => authStore.activeRole || 'Professor');
const isRouteReady = computed(() => {
  if (!authStore.isAuthenticated) return false;
  const role = authStore.activeRole;
  if (role === 'Admin') return route.path.startsWith('/admin');
  if (role === 'Professor') return route.path.startsWith('/professor');
  if (role === 'Student') return route.path.startsWith('/aluno');
  return false;
});
const navItems = computed(() => {
  if (activeRole.value === 'Admin') return adminNav;
  if (activeRole.value === 'Student') return studentNav;
  return professorNav;
});
const userInitials = computed(() => {
  const parts = (authStore.user?.name || 'User')
    .split(' ')
    .map((chunk) => chunk[0])
    .slice(0, 2);
  return parts.join('').toUpperCase();
});

onMounted(async () => {
  try {
    setupAuthInterceptor(authStore);
    await authStore.restoreSession();
    if (authStore.isAuthenticated) {
      const roleBaseMap: Record<string, string> = {
        Admin: '/admin',
        Professor: '/professor',
        Student: '/aluno',
      };
      const targetBase = roleBaseMap[authStore.activeRole ?? ''] ?? '/admin';
      if (!route.path.startsWith(targetBase)) {
        await router.replace(targetBase);
      }
    }
  } finally {
    authChecking.value = false;
  }
});

async function handleLogout(): Promise<void> {
  await authStore.logout();
  await router.replace('/login');
}
</script>
