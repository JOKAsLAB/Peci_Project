<template>
  <div class="min-h-screen bg-background font-inter text-text-primary flex items-center justify-center px-4 py-8">
    <div class="w-full max-w-md mx-auto">

      <!-- Logo -->
      <div class="text-center mb-8">
        <img
          src="/logo_LogicStreak.png"
          alt="LogicStreak"
          class="mx-auto w-28 sm:w-44 h-auto object-contain"
        />
        <p class="text-text-secondary text-sm mt-3">{{ isAdmin ? 'Admin' : 'Docente' }} · Universidade de Aveiro</p>
      </div>

      <!-- Login Form -->
      <div v-if="currentView === 'login'" class="space-y-5">
        <div>
          <label class="text-xs font-bold text-text-secondary uppercase tracking-widest mb-2 block">Email Institucional</label>
          <input
            v-model="email"
            type="email"
            placeholder="nome@ua.pt"
            class="w-full bg-surface p-4 rounded-btn border border-white/10 outline-none focus:border-brand text-sm transition-colors"
            @keyup.enter="login"
          />
        </div>
        <div>
          <label class="text-xs font-bold text-text-secondary uppercase tracking-widest mb-2 block">Password</label>
          <div class="relative">
            <input
              v-model="password"
              :type="showPassword ? 'text' : 'password'"
              placeholder="••••••••"
              class="w-full bg-surface p-4 rounded-btn border border-white/10 outline-none focus:border-brand text-sm pr-12 transition-colors"
              @keyup.enter="login"
            />
            <button
              @click="showPassword = !showPassword"
              class="absolute right-4 top-1/2 -translate-y-1/2 text-text-secondary hover:text-white transition-colors"
            >
              <i :class="showPassword ? 'pi pi-eye-slash' : 'pi pi-eye'" class="text-sm"></i>
            </button>
          </div>
        </div>

        <div class="flex items-center justify-between">
          <label class="flex items-center gap-2 text-text-secondary text-sm cursor-pointer">
            <input type="checkbox" v-model="rememberMe" class="accent-brand" />
            Lembrar-me
          </label>
          <button
            @click="startForgotPassword"
            class="text-text-secondary text-sm hover:text-brand transition-colors"
          >
            Esqueceste a password?
          </button>
        </div>

        <div v-if="errorMessage" class="bg-error/10 border border-error/20 text-error text-sm p-3 rounded-btn flex items-center gap-2">
          <i class="pi pi-exclamation-circle"></i>
          {{ errorMessage }}
        </div>

        <button
          @click="login"
          :disabled="loading"
          class="w-full bg-brand py-4 rounded-btn font-bold text-white hover:brightness-110 transition-all flex items-center justify-center gap-2 disabled:opacity-50"
        >
          <i v-if="loading" class="pi pi-spin pi-spinner"></i>
          <span>{{ loading ? 'A verificar...' : 'Entrar' }}</span>
        </button>

        <template v-if="!isAdmin">
          <div class="flex items-center gap-4">
            <div class="flex-1 border-t border-white/10"></div>
            <span class="text-text-secondary text-xs">ou</span>
            <div class="flex-1 border-t border-white/10"></div>
          </div>

          <button
            @click="currentView = 'register'"
            class="w-full border border-white/10 py-4 rounded-btn font-bold text-text-primary hover:border-brand/50 hover:text-brand transition-all"
          >
            Criar Conta
          </button>
        </template>
      </div>

      <!-- Register Form (professor only) -->
      <div v-else-if="currentView === 'register'" class="space-y-4">
        <button
          @click="currentView = 'login'"
          class="flex items-center gap-2 text-text-secondary hover:text-white transition-colors text-sm mb-2"
        >
          <i class="pi pi-arrow-left"></i> Voltar ao login
        </button>

        <h2 class="text-xl font-bold">Criar Conta</h2>
        <p class="text-text-secondary text-sm">Regista-te com o teu email institucional da UA.</p>

        <div class="flex gap-2 bg-surface rounded-btn p-1">
          <button
            @click="regRole = 'professor'"
            :class="regRole === 'professor' ? 'bg-brand text-white' : 'text-text-secondary'"
            class="flex-1 py-2.5 rounded-btn text-sm font-bold transition-all"
          >
            Docente
          </button>
          <button
            @click="regRole = 'aluno'"
            :class="regRole === 'aluno' ? 'bg-brand text-white' : 'text-text-secondary'"
            class="flex-1 py-2.5 rounded-btn text-sm font-bold transition-all"
          >
            Aluno
          </button>
        </div>
        <p v-if="regRole === 'professor'" class="text-warning text-xs">
          Contas de docente requerem aprovação do administrador.
        </p>

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

      <!-- Forgot Password Step 1: enter email -->
      <div v-else-if="currentView === 'forgot1'" class="space-y-5">
        <button
          @click="currentView = 'login'"
          class="flex items-center gap-2 text-text-secondary hover:text-white transition-colors text-sm"
        >
          <i class="pi pi-arrow-left"></i> Voltar ao login
        </button>

        <div>
          <h2 class="text-xl font-bold">Recuperar Password</h2>
          <p class="text-text-secondary text-sm mt-1">Insere o teu email para receberes um código de recuperação.</p>
        </div>

        <div>
          <label class="text-xs font-bold text-text-secondary uppercase tracking-widest mb-2 block">Email</label>
          <input
            v-model="forgotEmail"
            type="email"
            placeholder="nome@ua.pt"
            class="w-full bg-surface p-4 rounded-btn border border-white/10 outline-none focus:border-brand text-sm transition-colors"
            @keyup.enter="submitForgotEmail"
          />
        </div>

        <div v-if="forgotError" class="bg-error/10 border border-error/20 text-error text-sm p-3 rounded-btn flex items-center gap-2">
          <i class="pi pi-exclamation-circle"></i>
          {{ forgotError }}
        </div>

        <button
          @click="submitForgotEmail"
          :disabled="forgotLoading"
          class="w-full bg-brand py-4 rounded-btn font-bold text-white hover:brightness-110 transition-all flex items-center justify-center gap-2 disabled:opacity-50"
        >
          <i v-if="forgotLoading" class="pi pi-spin pi-spinner"></i>
          <span>{{ forgotLoading ? 'A enviar...' : 'Enviar Código' }}</span>
        </button>
      </div>

      <!-- Forgot Password Step 2: code + new password -->
      <div v-else-if="currentView === 'forgot2'" class="space-y-5">
        <div>
          <h2 class="text-xl font-bold">Nova Password</h2>
          <p class="text-text-secondary text-sm mt-1">
            Insere o código de 6 dígitos enviado para <span class="text-white">{{ forgotEmail }}</span> e define uma nova password.
          </p>
        </div>

        <div>
          <label class="text-xs font-bold text-text-secondary uppercase tracking-widest mb-2 block">Código de Verificação</label>
          <input
            v-model="forgotCode"
            type="text"
            placeholder="000000"
            maxlength="6"
            class="w-full bg-surface p-4 rounded-btn border border-white/10 outline-none focus:border-brand text-sm text-center tracking-widest transition-colors"
          />
        </div>
        <div>
          <label class="text-xs font-bold text-text-secondary uppercase tracking-widest mb-2 block">Nova Password</label>
          <div class="relative">
            <input
              v-model="forgotNewPass"
              :type="showForgotPass ? 'text' : 'password'"
              placeholder="Mínimo 6 caracteres"
              class="w-full bg-surface p-4 rounded-btn border border-white/10 outline-none focus:border-brand text-sm pr-12 transition-colors"
            />
            <button
              @click="showForgotPass = !showForgotPass"
              class="absolute right-4 top-1/2 -translate-y-1/2 text-text-secondary hover:text-white transition-colors"
            >
              <i :class="showForgotPass ? 'pi pi-eye-slash' : 'pi pi-eye'" class="text-sm"></i>
            </button>
          </div>
        </div>
        <div>
          <label class="text-xs font-bold text-text-secondary uppercase tracking-widest mb-2 block">Confirmar Nova Password</label>
          <input
            v-model="forgotConfirmPass"
            type="password"
            placeholder="Repete a nova password"
            class="w-full bg-surface p-4 rounded-btn border border-white/10 outline-none focus:border-brand text-sm transition-colors"
            @keyup.enter="submitResetPassword"
          />
        </div>

        <div v-if="forgotError" class="bg-error/10 border border-error/20 text-error text-sm p-3 rounded-btn flex items-center gap-2">
          <i class="pi pi-exclamation-circle"></i>
          {{ forgotError }}
        </div>

        <button
          @click="submitResetPassword"
          :disabled="forgotLoading"
          class="w-full bg-brand py-4 rounded-btn font-bold text-white hover:brightness-110 transition-all flex items-center justify-center gap-2 disabled:opacity-50"
        >
          <i v-if="forgotLoading" class="pi pi-spin pi-spinner"></i>
          <span>{{ forgotLoading ? 'A alterar...' : 'Alterar Password' }}</span>
        </button>

        <button
          @click="currentView = 'forgot1'"
          class="w-full text-text-secondary text-sm hover:text-white transition-colors py-2"
        >
          Não recebi o código — reenviar
        </button>
      </div>

      <!-- Forgot Password Success -->
      <div v-else-if="currentView === 'forgotSuccess'" class="space-y-6 text-center">
        <div class="flex justify-center">
          <div class="w-16 h-16 rounded-full bg-green-500/20 flex items-center justify-center">
            <i class="pi pi-check text-green-400 text-2xl"></i>
          </div>
        </div>
        <div>
          <h2 class="text-xl font-bold">Password Alterada!</h2>
          <p class="text-text-secondary text-sm mt-2">A tua password foi alterada com sucesso. Já podes entrar com a nova password.</p>
        </div>
        <button
          @click="currentView = 'login'"
          class="w-full bg-brand py-4 rounded-btn font-bold text-white hover:brightness-110 transition-all"
        >
          Entrar
        </button>
      </div>

    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useAuthStore } from '@/stores/authStore'

const props = defineProps({
  isAdmin: { type: Boolean, default: false }
})

const emit = defineEmits(['authenticated'])
const authStore = useAuthStore()

const currentView = ref('login')

// Login state
const email = ref('')
const password = ref('')
const showPassword = ref(false)
const rememberMe = ref(true)
const loading = ref(false)
const errorMessage = ref('')

// Register state
const regName = ref('')
const regNmec = ref('')
const regEmail = ref('')
const regPassword = ref('')
const regConfirm = ref('')
const regRole = ref('professor')
const regLoading = ref(false)
const regError = ref('')

// Forgot password state
const forgotEmail = ref('')
const forgotCode = ref('')
const forgotNewPass = ref('')
const forgotConfirmPass = ref('')
const forgotLoading = ref(false)
const forgotError = ref('')
const showForgotPass = ref(false)

const login = async () => {
  if (!email.value || !password.value) {
    errorMessage.value = 'Preenche todos os campos.'
    return
  }
  errorMessage.value = ''
  loading.value = true

  try {
    const role = props.isAdmin ? 'Admin' : 'Professor'
    await authStore.login(email.value, password.value, { role, remember: rememberMe.value })
    emit('authenticated')
  } catch (error) {
    errorMessage.value = error?.message || 'Falha ao autenticar.'
  } finally {
    loading.value = false
  }
}

const register = async () => {
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

  try {
    if (regRole.value !== 'professor') {
      regError.value = 'Nesta fase, o painel docente aceita apenas registo de contas de docente.'
      return
    }
    await authStore.registerProfessor({
      name: regName.value,
      email: regEmail.value,
      password: regPassword.value,
      department: 'DETI',
      office: `NMEC-${regNmec.value}`,
      shortBio: 'Conta criada a partir do painel docente',
    })
    currentView.value = 'login'
  } catch (error) {
    regError.value = error?.message || 'Falha ao registar conta.'
  } finally {
    regLoading.value = false
    regName.value = ''
    regNmec.value = ''
    regEmail.value = ''
    regPassword.value = ''
    regConfirm.value = ''
  }
}

const startForgotPassword = () => {
  forgotEmail.value = email.value
  forgotError.value = ''
  currentView.value = 'forgot1'
}

const submitForgotEmail = async () => {
  if (!forgotEmail.value) {
    forgotError.value = 'Insere o teu email.'
    return
  }
  forgotError.value = ''
  forgotLoading.value = true

  try {
    await authStore.forgotPassword(forgotEmail.value)
    currentView.value = 'forgot2'
  } catch (error) {
    forgotError.value = error?.message || 'Erro ao enviar código.'
  } finally {
    forgotLoading.value = false
  }
}

const submitResetPassword = async () => {
  if (!forgotCode.value || forgotCode.value.length !== 6) {
    forgotError.value = 'Insere o código de 6 dígitos.'
    return
  }
  if (!forgotNewPass.value || forgotNewPass.value.length < 6) {
    forgotError.value = 'A nova password deve ter pelo menos 6 caracteres.'
    return
  }
  if (forgotNewPass.value !== forgotConfirmPass.value) {
    forgotError.value = 'As passwords não coincidem.'
    return
  }

  forgotError.value = ''
  forgotLoading.value = true

  try {
    await authStore.resetPassword(forgotEmail.value, forgotCode.value, forgotNewPass.value)
    currentView.value = 'forgotSuccess'
  } catch (error) {
    forgotError.value = error?.message || 'Código inválido ou expirado.'
  } finally {
    forgotLoading.value = false
  }
}
</script>
