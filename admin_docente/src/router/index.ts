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
    redirect: () => {
      const auth = useAuthStore()
      if (auth.user?.role === 'Admin') return '/admin'
      if (auth.user?.role === 'Professor') return '/professor'
      if (auth.user?.role === 'Student') return '/aluno'
      return '/login'
    },
  },
  {
    path: '/login',
    name: 'Login',
    component: () => import('../views/LoginView.vue'),
    meta: { requiresAuth: false },
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
    name: 'Construtor de Percurso',
    component: () => import('../modules/professor/views/PathBuilderView.vue'),
    meta: { requiresAuth: true, role: 'Professor' },
  },
  {
    path: '/professor/exercises',
    name: 'Banco de Perguntas',
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
    name: 'Geração de Perguntas',
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
  {
    path: '/professor/quiz',
    name: 'Quizz ao Vivo',
    component: () => import('../modules/professor/views/QuizView.vue'),
    meta: { requiresAuth: true, role: 'Professor' },
  },
  {
    path: '/aluno',
    name: 'Aluno Dashboard',
    component: () => import('../modules/aluno/views/DashboardView.vue'),
    meta: { requiresAuth: true, role: 'Student' },
  },
  {
    path: '/aluno/exercicios',
    name: 'Praticar',
    component: () => import('../modules/aluno/views/ExerciseFeedView.vue'),
    meta: { requiresAuth: true, role: 'Student' },
  },
  {
    path: '/aluno/percursos',
    name: 'Percursos',
    component: () => import('../modules/aluno/views/CoursesView.vue'),
    meta: { requiresAuth: true, role: 'Student' },
  },
  {
    path: '/aluno/quiz',
    name: 'Quiz ao Vivo',
    component: () => import('../modules/aluno/views/QuizView.vue'),
    meta: { requiresAuth: true, role: 'Student' },
  },
  {
    path: '/aluno/perfil',
    name: 'Estatísticas',
    component: () => import('../modules/aluno/views/ProfileView.vue'),
    meta: { requiresAuth: true, role: 'Student' },
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.beforeEach((to) => {
  const authStore = useAuthStore()

  if (!to.meta.requiresAuth) {
    if (to.path === '/login' && authStore.isAuthenticated) {
      const role = authStore.user?.role
      if (role === 'Admin') return '/admin'
      if (role === 'Professor') return '/professor'
      if (role === 'Student') return '/aluno'
    }
    return true
  }

  if (!authStore.isAuthenticated) return '/login'

  const targetRole = to.meta.role
  if (targetRole && authStore.user?.role !== targetRole) {
    const role = authStore.user?.role
    if (role === 'Admin') return '/admin'
    if (role === 'Professor') return '/professor'
    if (role === 'Student') return '/aluno'
    return '/login'
  }

  return true
})

export default router