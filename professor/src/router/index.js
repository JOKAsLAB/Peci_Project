import { createRouter, createWebHistory } from 'vue-router';
import { useAuthStore } from '../stores/authStore';

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'Dashboard Docente',
      component: () => import('../views/DashboardView.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/exercises',
      name: 'Exercícios',
      component: () => import('../views/ExercisesView.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/documents',
      name: 'Documentos da UC',
      component: () => import('../views/DocumentsView.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/question',
      name: 'Perguntas com LLM',
      component: () => import('../views/QuestionLabView.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/path-builder',
      name: 'Construtor de Percurso',
      component: () => import('../views/PathBuilderView.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/requests',
      name: 'Pedidos ao Admin',
      component: () => import('../views/RequestsView.vue'),
      meta: { requiresAuth: true },
    },
  ],
});

// Intercetor global para auditoria de permissões (Navigation Guard)
router.beforeEach((to, from, next) => {
  // A instanciação tardia evita erros de inicialização prematura do Pinia
  const authStore = useAuthStore();

  if (to.meta.requiresAuth && !authStore.isAuthenticated) {
    // Na topologia atual (Login Gate condicional no App.vue), a view é bloqueada via v-if.
    // Quando a rota de login for segregada (/login), substituir por next('/login').
    next();
  } else {
    next();
  }
});

export default router;
