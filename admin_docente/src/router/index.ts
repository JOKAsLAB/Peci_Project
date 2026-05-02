import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router'
import { useAuthStore, type SupportedRole } from '../stores/authStore'

declare module 'vue-router' {
  interface RouteMeta {
    requiresAuth?: boolean
    role?: SupportedRole
  }
}

const routes: RouteRecordRaw[] = [
  {
    path: '/',
    redirect: '/admin',
  },
  {
    path: '/admin',
    name: 'Admin Dashboard',
    component: () => import('../modules/admin/views/DashboardView.vue'),
    meta: { requiresAuth: true, role: 'Admin' },
  },
  {
    path: '/admin/disciplines',
    name: 'Disciplinas',
    component: () => import('../modules/admin/views/DisciplinesView.vue'),
    meta: { requiresAuth: true, role: 'Admin' },
  },
  {
    path: '/admin/users',
    name: 'Utilizadores',
    component: () => import('../modules/admin/views/UsersView.vue'),
    meta: { requiresAuth: true, role: 'Admin' },
  },
  {
    path: '/admin/approvals',
    name: 'Aprovações',
    component: () => import('../modules/admin/views/AccountApprovalsView.vue'),
    meta: { requiresAuth: true, role: 'Admin' },
  },
  {
    path: '/admin/requests',
    name: 'Pedidos Admin',
    component: () => import('../modules/admin/views/RequestsView.vue'),
    meta: { requiresAuth: true, role: 'Admin' },
  },
  {
    path: '/professor',
    name: 'Professor Dashboard',
    component: () => import('../modules/professor/views/DashboardView.vue'),
    meta: { requiresAuth: true, role: 'Professor' },
  },
  {
    path: '/professor/path-builder',
    name: 'Percursos',
    component: () => import('../modules/professor/views/PathBuilderView.vue'),
    meta: { requiresAuth: true, role: 'Professor' },
  },
  {
    path: '/professor/exercises',
    name: 'Exercícios',
    component: () => import('../modules/professor/views/ExercisesView.vue'),
    meta: { requiresAuth: true, role: 'Professor' },
  },
  {
    path: '/professor/documents',
    name: 'Documentos',
    component: () => import('../modules/professor/views/DocumentsView.vue'),
    meta: { requiresAuth: true, role: 'Professor' },
  },
  {
    path: '/professor/question',
    name: 'Perguntas com LLM',
    component: () => import('../modules/professor/views/QuestionLabView.vue'),
    meta: { requiresAuth: true, role: 'Professor' },
  },
  {
    path: '/professor/requests',
    name: 'Pedidos ao Admin',
    component: () => import('../modules/professor/views/RequestsView.vue'),
    meta: { requiresAuth: true, role: 'Professor' },
  },
  {
    path: '/professor/reported',
    name: 'Perguntas Reportadas',
    component: () => import('../modules/professor/views/ReportedQuestionsView.vue'),
    meta: { requiresAuth: true, role: 'Professor' },
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.beforeEach((to) => {
  const authStore = useAuthStore()
  if (!to.meta.requiresAuth || !authStore.isAuthenticated) {
    return true
  }

  const targetRole = to.meta.role
  if (targetRole && authStore.user?.role !== targetRole) {
    return authStore.user?.role === 'Admin' ? '/admin' : '/professor'
  }

  return true
})

export default router