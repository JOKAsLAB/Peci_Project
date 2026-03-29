import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/authStore'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      name: 'Dashboard',
      component: () => import('../views/DashboardView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/disciplines',
      name: 'Disciplinas',
      component: () => import('../views/DisciplinesView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/users',
      name: 'Utilizadores',
      component: () => import('../views/UsersView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/approvals',
      name: 'Aprovações de Contas',
      component: () => import('../views/AccountApprovalsView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/requests',
      name: 'Pedidos Administrativos',
      component: () => import('../views/RequestsView.vue'),
      meta: { requiresAuth: true }
    }
  ]
})

// Intercetor global para auditoria de permissões (Navigation Guard)
router.beforeEach((to, from, next) => {
  // A store deve ser instanciada aqui para evitar erros de "Pinia not active"
  // durante a inicialização do módulo do router.
  const authStore = useAuthStore()
  
  if (to.meta.requiresAuth && !authStore.isAuthenticated) {
    // Na atual topologia (Login Gate no App.vue), a renderização é bloqueada visualmente.
    // Em produção com rotas segregadas, alterar next() para next('/login').
    next() 
  } else {
    next()
  }
})

export default router