<template>
  <div class="space-y-8">
    <div class="flex justify-between items-end">
      <div>
        <p class="text-brand font-bold text-sm uppercase tracking-widest mb-1">
          Gestão
        </p>
        <h3 class="text-3xl font-bold">Utilizadores</h3>
        <p class="text-text-secondary mt-1">
          Gestão completa de alunos e docentes da plataforma.
        </p>
      </div>

      <button
        @click="openCreate"
        class="bg-brand text-white px-6 py-3 rounded-btn font-bold hover:brightness-110 transition-all flex items-center gap-2"
      >
        <i class="pi pi-plus"></i>
        Adicionar Utilizador
      </button>
    </div>

    <div
      v-if="userStore.error"
      class="bg-error/10 border border-error/30 text-error px-4 py-3 rounded-card text-sm"
    >
      <i class="pi pi-exclamation-triangle mr-2"></i> {{ userStore.error }}
    </div>

    <!-- Métricas -->
    <div class="grid grid-cols-4 gap-6">
      <div class="bg-surface p-6 rounded-card border border-white/5">
        <div class="flex items-center gap-3 mb-3">
          <div class="w-10 h-10 rounded-btn bg-brand/10 flex items-center justify-center">
            <i class="pi pi-users text-brand"></i>
          </div>
          <p class="text-text-secondary text-sm">Total</p>
        </div>
        <p class="text-3xl font-bold">{{ userStore.users.length }}</p>
      </div>
      <div class="bg-surface p-6 rounded-card border border-white/5">
        <div class="flex items-center gap-3 mb-3">
          <div class="w-10 h-10 rounded-btn bg-success/10 flex items-center justify-center">
            <i class="pi pi-check-circle text-success"></i>
          </div>
          <p class="text-text-secondary text-sm">Ativos</p>
        </div>
        <p class="text-3xl font-bold text-success">{{ userStore.activeUsers.length }}</p>
      </div>
      <div class="bg-surface p-6 rounded-card border border-white/5">
        <div class="flex items-center gap-3 mb-3">
          <div class="w-10 h-10 rounded-btn bg-blue-500/10 flex items-center justify-center">
            <i class="pi pi-graduation-cap text-blue-400"></i>
          </div>
          <p class="text-text-secondary text-sm">Alunos</p>
        </div>
        <p class="text-3xl font-bold text-blue-400">{{ userStore.students.length }}</p>
      </div>
      <div class="bg-surface p-6 rounded-card border border-white/5">
        <div class="flex items-center gap-3 mb-3">
          <div class="w-10 h-10 rounded-btn bg-warning/10 flex items-center justify-center">
            <i class="pi pi-briefcase text-warning"></i>
          </div>
          <p class="text-text-secondary text-sm">Docentes</p>
        </div>
        <p class="text-3xl font-bold text-warning">{{ userStore.professors.length }}</p>
      </div>
    </div>

    <!-- Filtros -->
    <div class="flex items-center gap-3">
      <button
        v-for="f in ['Todos', 'Alunos', 'Docentes', 'Inativos']"
        :key="f"
        @click="roleFilter = f"
        :class="roleFilter === f ? 'bg-brand text-white' : 'bg-surface text-text-secondary border border-white/10'"
        class="px-5 py-2 rounded-chip text-sm font-bold transition-all"
      >
        {{ f }}
      </button>

      <div class="ml-auto flex items-center gap-3">
        <div class="relative">
          <i class="pi pi-search absolute left-3 top-1/2 -translate-y-1/2 text-text-secondary text-sm"></i>
          <input
            v-model="search"
            placeholder="Pesquisar por nome ou email..."
            class="bg-surface border border-white/10 pl-10 pr-4 py-2 rounded-btn text-sm outline-none focus:border-brand w-80"
          />
        </div>
        <select
          v-model="disciplineFilter"
          class="bg-surface border border-white/10 px-4 py-2 rounded-btn text-sm outline-none focus:border-brand"
        >
          <option value="">Todas UCs</option>
          <option v-for="d in disciplineStore.disciplines" :key="d.id" :value="d.acronym">
            {{ d.acronym }} — {{ d.name }}
          </option>
        </select>
      </div>
    </div>

    <!-- Tabela -->
    <div class="bg-surface rounded-card border border-white/5 overflow-hidden">
      <table class="w-full text-left">
        <thead class="bg-black/20 text-text-secondary uppercase text-[10px] tracking-widest">
          <tr>
            <th class="px-6 py-4 font-semibold">Utilizador</th>
            <th class="px-6 py-4 font-semibold">Email</th>
            <th class="px-6 py-4 font-semibold text-center">Papel</th>
            <th class="px-6 py-4 font-semibold text-center">UCs</th>
            <th class="px-6 py-4 font-semibold text-center">Estado</th>
            <th class="px-6 py-4 font-semibold text-center">Registo</th>
            <th class="px-6 py-4 font-semibold text-right">Ações</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-white/5">
          <tr
            v-for="u in filteredUsers"
            :key="u.id"
            class="hover:bg-white/2 transition-colors group"
          >
            <td class="px-6 py-4">
              <div class="flex items-center gap-3">
                <div
                  class="w-9 h-9 rounded-full flex items-center justify-center text-xs font-bold shrink-0"
                  :class="u.role === 'professor' ? 'bg-warning/20 text-warning' : 'bg-brand/20 text-brand'"
                >
                  {{ u.name.split(' ').map((n: string) => n[0]).slice(0, 2).join('') }}
                </div>
                <span class="font-medium text-sm">{{ u.name }}</span>
              </div>
            </td>
            <td class="px-6 py-4 text-text-secondary text-sm">{{ u.email }}</td>
            <td class="px-6 py-4 text-center">
              <span
                class="text-[10px] font-bold uppercase tracking-widest px-3 py-1 rounded-chip"
                :class="
                  u.role === 'professor' ? 'bg-warning/10 text-warning'
                  : u.role === 'admin' ? 'bg-error/10 text-error'
                  : 'bg-brand/10 text-brand'
                "
              >
                {{ u.role === 'professor' ? 'Docente' : u.role === 'admin' ? 'Admin' : 'Aluno' }}
              </span>
            </td>
            <td class="px-6 py-4 text-center">
              <div class="flex flex-wrap justify-center gap-1">
                <span
                  v-for="d in u.disciplines"
                  :key="d"
                  class="bg-gray-800 text-text-secondary text-[10px] px-2 py-0.5 rounded-full"
                >{{ d }}</span>
              </div>
            </td>
            <td class="px-6 py-4 text-center">
              <div
                @click="onToggleStatus(u)"
                class="cursor-pointer inline-flex items-center gap-2 px-3 py-1 rounded-full transition-colors"
                :class="u.active ? 'bg-success/10 hover:bg-success/20' : 'bg-error/10 hover:bg-error/20'"
              >
                <div class="w-1.5 h-1.5 rounded-full" :class="u.active ? 'bg-success' : 'bg-error'"></div>
                <span class="text-xs font-medium" :class="u.active ? 'text-success' : 'text-error'">
                  {{ u.active ? 'Ativo' : 'Inativo' }}
                </span>
              </div>
            </td>
            <td class="px-6 py-4 text-center text-text-secondary text-sm">{{ u.lastLogin }}</td>
            <td class="px-6 py-4 text-right">
              <div class="flex justify-end gap-3 opacity-0 group-hover:opacity-100 transition-opacity">
                <button @click="openEdit(u)" class="text-text-secondary hover:text-white" title="Editar">
                  <i class="pi pi-pencil"></i>
                </button>
                <button @click="onRemoveUser(u)" class="text-text-secondary hover:text-error" title="Remover">
                  <i class="pi pi-trash"></i>
                </button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
      <div v-if="filteredUsers.length === 0" class="p-8 text-center text-text-secondary">
        Nenhum utilizador encontrado com os filtros atuais.
      </div>
      <div class="px-6 py-4 border-t border-white/5 flex justify-between items-center text-text-secondary text-sm">
        <span>{{ filteredUsers.length }} de {{ userStore.users.length }} utilizadores</span>
      </div>
    </div>

    <!-- Modal Criar / Editar -->
    <Teleport to="body">
      <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center">
        <div class="absolute inset-0 bg-black/60 backdrop-blur-sm" @click="showModal = false"></div>
        <div class="relative bg-surface border border-white/10 rounded-card w-full max-w-lg p-8 shadow-2xl z-10">
          <div class="flex justify-between items-center mb-6">
            <h4 class="text-xl font-bold">
              {{ editingId ? 'Editar Utilizador' : 'Adicionar Utilizador' }}
            </h4>
            <button @click="showModal = false" class="text-text-secondary hover:text-white">
              <i class="pi pi-times"></i>
            </button>
          </div>
          <div class="space-y-4">
            <div>
              <label class="text-xs font-bold text-text-secondary uppercase tracking-widest">Nome Completo</label>
              <input
                v-model="form.name"
                type="text"
                placeholder="Nome do utilizador"
                class="w-full bg-background mt-2 p-3 rounded-btn border border-white/10 outline-none focus:border-brand text-sm"
              />
            </div>
            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="text-xs font-bold text-text-secondary uppercase tracking-widest">Papel</label>
                <select
                  v-model="form.role"
                  class="w-full bg-background mt-2 p-3 rounded-btn border border-white/10 outline-none focus:border-brand text-sm"
                >
                  <option value="aluno">Aluno</option>
                  <option value="professor">Docente</option>
                </select>
              </div>
            </div>
            <div>
              <label class="text-xs font-bold text-text-secondary uppercase tracking-widest">Email</label>
              <input
                v-model="form.email"
                type="email"
                placeholder="email@ua.pt"
                class="w-full bg-background mt-2 p-3 rounded-btn border border-white/10 outline-none focus:border-brand text-sm"
              />
            </div>
            <div v-if="!editingId">
              <label class="text-xs font-bold text-text-secondary uppercase tracking-widest">Password</label>
              <input
                v-model="form.password"
                type="text"
                placeholder="Password inicial"
                class="w-full bg-background mt-2 p-3 rounded-btn border border-white/10 outline-none focus:border-brand text-sm"
              />
            </div>
          </div>
          <div class="flex justify-end gap-3 mt-8">
            <button
              @click="showModal = false"
              class="px-6 py-3 rounded-btn text-text-secondary hover:text-white border border-white/10 text-sm font-bold transition-all"
            >
              Cancelar
            </button>
            <button
              @click="save"
              class="bg-brand px-6 py-3 rounded-btn text-white font-bold hover:brightness-110 transition-all text-sm"
            >
              {{ editingId ? 'Guardar' : 'Adicionar' }}
            </button>
          </div>
        </div>
      </div>
    </Teleport>

    <ActionDialog
      :visible="showConfirmDialog"
      :title="confirmDialog.title"
      :message="confirmDialog.message"
      :confirm-text="confirmDialog.confirmText"
      variant="danger"
      @update:visible="showConfirmDialog = $event"
      @confirm="runConfirmedAction"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { useUserStore } from '../stores/userStore'
import { useDisciplineStore } from '../stores/disciplineStore'
import ActionDialog from '../../../components/ActionDialog.vue'

const userStore = useUserStore()
const disciplineStore = useDisciplineStore()

const roleFilter = ref('Todos')
const search = ref('')
const disciplineFilter = ref('')

const showModal = ref(false)
const editingId = ref<string | null>(null)
const form = reactive({
  name: '',
  email: '',
  password: '',
  role: 'aluno' as 'aluno' | 'professor',
})

const showConfirmDialog = ref(false)
const confirmDialog = reactive({ title: '', message: '', confirmText: 'Confirmar' })
const confirmedAction = ref<(() => Promise<void>) | null>(null)

const filteredUsers = computed(() => {
  let list = userStore.users
  if (roleFilter.value === 'Alunos') list = list.filter((u) => u.role === 'aluno')
  else if (roleFilter.value === 'Docentes') list = list.filter((u) => u.role === 'professor')
  else if (roleFilter.value === 'Inativos') list = list.filter((u) => !u.active)
  if (disciplineFilter.value) list = list.filter((u) => u.disciplines?.includes(disciplineFilter.value))
  if (search.value) {
    const q = search.value.toLowerCase()
    list = list.filter((u) => u.name.toLowerCase().includes(q) || u.email.toLowerCase().includes(q))
  }
  return list
})

function resetForm() {
  form.name = ''
  form.email = ''
  form.password = ''
  form.role = 'aluno'
}

function openCreate() {
  editingId.value = null
  resetForm()
  showModal.value = true
}

function openEdit(u: any) {
  editingId.value = u.id
  form.name = u.name
  form.email = u.email
  form.password = ''
  form.role = u.role
  showModal.value = true
}

function ask(title: string, message: string, confirmText: string, action: () => Promise<void>) {
  confirmDialog.title = title
  confirmDialog.message = message
  confirmDialog.confirmText = confirmText
  confirmedAction.value = action
  showConfirmDialog.value = true
}

async function runConfirmedAction() {
  await confirmedAction.value?.()
  showConfirmDialog.value = false
  confirmedAction.value = null
}

async function save() {
  if (editingId.value) {
    await userStore.updateUser(editingId.value, { name: form.name })
  } else {
    await userStore.addUser({ name: form.name, email: form.email, password: form.password, role: form.role })
  }
  if (!userStore.error) showModal.value = false
}

function onRemoveUser(u: any) {
  ask(
    'Remover utilizador',
    `Vais remover ${u.name} (${u.email}) da plataforma. Esta ação é irreversível.`,
    'Remover',
    () => userStore.removeUser(u.id),
  )
}

function onToggleStatus(u: any) {
  const next = u.active ? 'Inativo' : 'Ativo'
  ask(
    `${u.active ? 'Desativar' : 'Ativar'} utilizador`,
    `Queres alterar o estado de ${u.name} para ${next}?`,
    'Confirmar',
    () => userStore.toggleStatus(u.id),
  )
}

onMounted(async () => {
  await Promise.all([userStore.loadUsers(), disciplineStore.loadDisciplines()])
})
</script>
