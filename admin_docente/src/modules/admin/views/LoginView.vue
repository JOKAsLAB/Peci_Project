<template>
  <div class="min-h-screen bg-background font-inter text-text-primary flex items-center justify-center">
    <div class="w-full max-w-md mx-auto p-8">
      <!-- Logo -->
      <div class="text-center mb-10">
        <img src="/logo_LogicStreak.png" alt="LogicStreak" class="mx-auto rounded-2xl shadow-lg shadow-brand/20" style="width: 200px; height: 200px; object-fit: cover;" />
        <p class="text-text-secondary text-sm mt-3">{{ isAdmin ? 'Admin' : 'Docente' }} · Universidade de Aveiro</p>
      </div>

      <!-- Login Form -->
      <div v-if="!showRegister" class="space-y-5">
        <div>
          <label class="text-xs font-bold text-text-secondary uppercase tracking-widest mb-2 block">Email Institucional</label>
          <input v-model="email" type="email" placeholder="nome@ua.pt"
                 class="w-full bg-surface p-4 rounded-btn border border-white/10 outline-none focus:border-brand text-sm transition-colors"
                 @keyup.enter="login" />
        </div>
        <div>
          <label class="text-xs font-bold text-text-secondary uppercase tracking-widest mb-2 block">Password</label>
          <div class="relative">
            <input v-model="password" :type="showPassword ? 'text' : 'password'" placeholder="••••••••"
                   class="w-full bg-surface p-4 rounded-btn border border-white/10 outline-none focus:border-brand text-sm pr-12 transition-colors"
                   @keyup.enter="login" />
            <button @click="showPassword = !showPassword" class="absolute right-4 top-1/2 -translate-y-1/2 text-text-secondary hover:text-white transition-colors">
              <i :class="showPassword ? 'pi pi-eye-slash' : 'pi pi-eye'" class="text-sm"></i>
            </button>
          </div>
        </div>

        <div class="flex items-center justify-between">
          <label class="flex items-center gap-2 text-text-secondary text-sm cursor-pointer">
            <input type="checkbox" v-model="rememberMe" class="accent-brand" />
            Lembrar-me
          </label>
          <button class="text-text-secondary text-sm hover:text-brand transition-colors">Esqueceste a password?</button>
        </div>

        <div v-if="errorMessage" class="bg-error/10 border border-error/20 text-error text-sm p-3 rounded-btn flex items-center gap-2">
          <i class="pi pi-exclamation-circle"></i>
          {{ errorMessage }}
        </div>

        <button @click="login" :disabled="loading"
                class="w-full bg-brand py-4 rounded-btn font-bold text-white hover:brightness-110 transition-all flex items-center justify-center gap-2 disabled:opacity-50">
          <i v-if="loading" class="pi pi-spin pi-spinner"></i>
          <span>{{ loading ? 'A verificar...' : 'Entrar' }}</span>
        </button>

        <div v-if="!isAdmin" class="flex items-center gap-4">
          <div class="flex-1 border-t border-white/10"></div>
          <span class="text-text-secondary text-xs">ou</span>
          <div class="flex-1 border-t border-white/10"></div>
        </div>

        <button v-if="!isAdmin" @click="showRegister = true"
                class="w-full border border-white/10 py-4 rounded-btn font-bold text-text-primary hover:border-brand/50 hover:text-brand transition-all">
          Criar Conta
        </button>
      </div>

      <!-- Register Form -->
      <div v-else class="space-y-4">
        <button @click="showRegister = false" class="flex items-center gap-2 text-text-secondary hover:text-white transition-colors text-sm mb-2">
          <i class="pi pi-arrow-left"></i> Voltar ao login
        </button>

        <h2 class="text-xl font-bold">Criar Conta</h2>
        <p class="text-text-secondary text-sm">Regista-te com o teu email institucional da UA.</p>

        <!-- Role selector -->
        <div class="flex gap-2 bg-surface rounded-btn p-1">
          <button @click="regRole = 'professor'"
                  :class="regRole === 'professor' ? 'bg-brand text-white' : 'text-text-secondary'"
                  class="flex-1 py-2.5 rounded-btn text-sm font-bold transition-all">
            Docente
          </button>
          <button @click="regRole = 'aluno'"
                  :class="regRole === 'aluno' ? 'bg-brand text-white' : 'text-text-secondary'"
                  class="flex-1 py-2.5 rounded-btn text-sm font-bold transition-all">
            Aluno
          </button>
        </div>
        <p v-if="regRole === 'professor'" class="text-warning text-xs">Contas de docente requerem aprovação do administrador.</p>

        <div>
          <label class="text-xs font-bold text-text-secondary uppercase tracking-widest mb-2 block">Nome Completo</label>
          <input v-model="regName" type="text" placeholder="Nome completo"
                 class="w-full bg-surface p-3.5 rounded-btn border border-white/10 outline-none focus:border-brand text-sm" />
        </div>
        <div>
          <label class="text-xs font-bold text-text-secondary uppercase tracking-widest mb-2 block">N.º Mecanográfico</label>
          <input v-model="regNmec" type="text" placeholder="Ex: 115000"
                 class="w-full bg-surface p-3.5 rounded-btn border border-white/10 outline-none focus:border-brand text-sm" />
        </div>
        <div>
          <label class="text-xs font-bold text-text-secondary uppercase tracking-widest mb-2 block">Email Institucional</label>
          <input v-model="regEmail" type="email" placeholder="nome@ua.pt"
                 class="w-full bg-surface p-3.5 rounded-btn border border-white/10 outline-none focus:border-brand text-sm" />
        </div>
        <div>
          <label class="text-xs font-bold text-text-secondary uppercase tracking-widest mb-2 block">Password</label>
          <input v-model="regPassword" type="password" placeholder="Mínimo 6 caracteres"
                 class="w-full bg-surface p-3.5 rounded-btn border border-white/10 outline-none focus:border-brand text-sm" />
        </div>
        <div>
          <label class="text-xs font-bold text-text-secondary uppercase tracking-widest mb-2 block">Confirmar Password</label>
          <input v-model="regConfirm" type="password" placeholder="Repete a password"
                 class="w-full bg-surface p-3.5 rounded-btn border border-white/10 outline-none focus:border-brand text-sm"
                 @keyup.enter="register" />
        </div>

        <div v-if="regError" class="bg-error/10 border border-error/20 text-error text-sm p-3 rounded-btn flex items-center gap-2">
          <i class="pi pi-exclamation-circle"></i>
          {{ regError }}
        </div>

        <button @click="register" :disabled="regLoading"
                class="w-full bg-brand py-4 rounded-btn font-bold text-white hover:brightness-110 transition-all flex items-center justify-center gap-2 disabled:opacity-50">
          <i v-if="regLoading" class="pi pi-spin pi-spinner"></i>
          <span>{{ regLoading ? 'A processar...' : (regRole === 'professor' ? 'Enviar Pedido' : 'Criar Conta') }}</span>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useAuthStore } from '../stores/authStore'

const props = defineProps({
  isAdmin: { type: Boolean, default: false }
})

const emit = defineEmits(['authenticated'])
const authStore = useAuthStore()

const email = ref('')
const password = ref('')
const showPassword = ref(false)
const rememberMe = ref(true)
const loading = ref(false)
const errorMessage = ref('')

const showRegister = ref(false)
const regName = ref('')
const regNmec = ref('')
const regEmail = ref('')
const regPassword = ref('')
const regConfirm = ref('')
const regRole = ref('professor')
const regLoading = ref(false)
const regError = ref('')

const login = async () => {
  if (!email.value) {
    errorMessage.value = 'Preenche o email.'
    return
  }
  if (!password.value) {
    errorMessage.value = 'Preenche todos os campos.'
    return
  }
  errorMessage.value = ''
  loading.value = true

  try {
    if (props.isAdmin) {
      await authStore.login(email.value, password.value, { remember: rememberMe.value })
      emit('authenticated')
    } else {
      if (email.value.endsWith('@ua.pt') && password.value.length >= 6) {
        emit('authenticated')
      } else {
        errorMessage.value = 'Credenciais inválidas.'
      }
    }
  } catch (error) {
    errorMessage.value = error?.message || 'Falha ao autenticar.'
  } finally {
    loading.value = false
  }
}

const register = () => {
  if (!regName.value || !regNmec.value || !regEmail.value || !regPassword.value) {
    regError.value = 'Preenche todos os campos.'
    return
  }
  if (!regEmail.value.endsWith('@ua.pt')) {
    regError.value = 'Usa o teu email institucional (@ua.pt).'
    return
  }
  if (regPassword.value.length < 6) {
    regError.value = 'A password deve ter pelo menos 6 caracteres.'
    return
  }
  if (regPassword.value !== regConfirm.value) {
    regError.value = 'As passwords não coincidem.'
    return
  }

  regError.value = ''
  regLoading.value = true

  setTimeout(() => {
    showRegister.value = false
    regLoading.value = false
    // Reset fields
    regName.value = ''
    regNmec.value = ''
    regEmail.value = ''
    regPassword.value = ''
    regConfirm.value = ''
  }, 1000)
}
</script>
