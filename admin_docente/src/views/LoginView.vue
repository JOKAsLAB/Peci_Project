<template>
  <div class="min-h-screen bg-background font-inter text-text-primary flex items-center justify-center px-4 py-8">
    <div class="w-full max-w-md mx-auto">

      <!-- Card principal -->
      <div class="panel-surface rounded-card p-6 sm:p-10 shadow-2xl">

        <!-- Logo -->
        <div class="flex flex-col items-center mb-8">
          <img
            src="/logo_LogicStreak.png"
            alt="LogicStreak"
            class="w-28 sm:w-44 h-auto object-contain"
          />
          <p class="text-text-secondary text-sm mt-3">Universidade de Aveiro</p>
        </div>

        <!-- Formulário de login -->
        <div v-if="currentView === 'login'" class="space-y-5">

          <!-- Seletor de papel -->
          <div class="flex gap-1 bg-surface rounded-btn p-1 border border-white/10">
            <button
              type="button"
              @click="selectedRole = 'Admin'"
              :class="selectedRole === 'Admin' ? 'bg-brand text-white' : 'text-text-secondary'"
              class="flex-1 py-2.5 rounded-btn text-xs sm:text-sm font-bold transition-all"
            >
              Admin
            </button>
            <button
              type="button"
              @click="selectedRole = 'Professor'"
              :class="selectedRole === 'Professor' ? 'bg-brand text-white' : 'text-text-secondary'"
              class="flex-1 py-2.5 rounded-btn text-xs sm:text-sm font-bold transition-all"
            >
              Professor
            </button>
            <button
              type="button"
              @click="selectedRole = 'Student'"
              :class="selectedRole === 'Student' ? 'bg-brand text-white' : 'text-text-secondary'"
              class="flex-1 py-2.5 rounded-btn text-xs sm:text-sm font-bold transition-all"
            >
              Aluno
            </button>
          </div>

          <!-- Email -->
          <div class="space-y-1.5">
            <label class="text-xs font-bold text-text-secondary uppercase tracking-widest block">Email</label>
            <input
              v-model="email"
              type="email"
              placeholder="nome@ua.pt"
              class="w-full bg-surface p-4 rounded-btn border border-white/10 outline-none focus:border-brand text-sm transition-colors"
              @keyup.enter="login"
            />
          </div>

          <!-- Password -->
          <div class="space-y-1.5">
            <label class="text-xs font-bold text-text-secondary uppercase tracking-widest block">Password</label>
            <div class="relative">
              <input
                v-model="password"
                :type="showPassword ? 'text' : 'password'"
                placeholder="••••••••"
                class="w-full bg-surface p-4 rounded-btn border border-white/10 outline-none focus:border-brand text-sm transition-colors pr-12"
                @keyup.enter="login"
              />
              <button
                type="button"
                @click="showPassword = !showPassword"
                class="absolute right-4 top-1/2 -translate-y-1/2 text-text-secondary hover:text-white transition-colors"
              >
                <i :class="showPassword ? 'pi pi-eye-slash' : 'pi pi-eye'" class="text-sm"></i>
              </button>
            </div>
          </div>

          <!-- Lembrar-me / forgot -->
          <div class="flex items-center justify-between">
            <label class="flex items-center gap-2 text-text-secondary text-sm cursor-pointer">
              <input type="checkbox" v-model="rememberMe" class="accent-brand" />
              Lembrar-me
            </label>
            <button
              type="button"
              @click="startForgotPassword"
              class="text-text-secondary text-sm hover:text-brand transition-colors"
            >
              Esqueceste a password?
            </button>
          </div>

          <!-- Erro -->
          <div
            v-if="errorMessage"
            class="bg-error/10 border border-error/20 text-error text-sm p-3 rounded-btn flex items-center gap-2"
          >
            <i class="pi pi-exclamation-circle"></i>
            {{ errorMessage }}
          </div>

          <!-- Botão entrar -->
          <button
            @click="login"
            :disabled="loading"
            class="w-full bg-brand py-4 rounded-btn font-bold text-white hover:brightness-110 transition-all flex items-center justify-center gap-2 disabled:opacity-50"
          >
            <i v-if="loading" class="pi pi-spin pi-spinner"></i>
            <span>{{ loading ? 'A autenticar...' : `Entrar como ${{ Admin: 'Admin', Professor: 'Professor', Student: 'Aluno' }[selectedRole]}` }}</span>
          </button>

          <!-- Registo (Professor ou Aluno) -->
          <template v-if="selectedRole === 'Professor' || selectedRole === 'Student'">
            <div class="flex items-center gap-4">
              <div class="flex-1 border-t border-white/10"></div>
              <span class="text-text-secondary text-xs">ou</span>
              <div class="flex-1 border-t border-white/10"></div>
            </div>

            <button
              type="button"
              @click="openRegister"
              class="w-full border border-white/10 py-4 rounded-btn font-bold text-text-primary hover:border-brand/50 hover:text-brand transition-all"
            >
              {{ selectedRole === 'Student' ? 'Criar Conta de Aluno' : 'Criar Conta de Professor' }}
            </button>

            <div
              v-if="regSuccess"
              class="bg-green-500/10 border border-green-500/20 text-green-300 text-sm p-3 rounded-btn flex items-center gap-2"
            >
              <i class="pi pi-check-circle"></i>
              {{ regSuccess }}
            </div>
          </template>
        </div>

        <!-- Formulário de registo / verificação -->
        <div v-else-if="currentView === 'register'" class="space-y-4">

          <!-- Passo de verificação de email (aluno) -->
          <template v-if="showVerify">
            <button
              type="button"
              @click="showVerify = false"
              class="flex items-center gap-2 text-text-secondary hover:text-white transition-colors text-sm mb-2"
            >
              <i class="pi pi-arrow-left"></i>
              Voltar ao registo
            </button>

            <h2 class="text-xl font-bold">Verificar Email</h2>
            <p class="text-text-secondary text-sm">
              Enviámos um código de 6 dígitos para <strong class="text-white">{{ regEmail }}</strong>.
              {{ selectedRole === 'Professor' ? 'Introduz o código para enviar o pedido de acesso.' : 'Introduz o código para ativar a tua conta.' }}
            </p>

            <div class="space-y-1.5">
              <label class="text-xs font-bold text-text-secondary uppercase tracking-widest block">Código de Verificação</label>
              <input
                v-model="verifyCode"
                type="text"
                maxlength="6"
                placeholder="000000"
                class="w-full bg-surface p-3.5 rounded-btn border border-white/10 outline-none focus:border-brand text-sm tracking-[0.5em] text-center"
                @keyup.enter="verifyEmail"
              />
            </div>

            <div v-if="verifyError" class="bg-error/10 border border-error/20 text-error text-sm p-3 rounded-btn flex items-center gap-2">
              <i class="pi pi-exclamation-circle"></i>
              {{ verifyError }}
            </div>

            <button
              @click="verifyEmail"
              :disabled="verifyLoading"
              class="w-full bg-brand py-4 rounded-btn font-bold text-white hover:brightness-110 transition-all flex items-center justify-center gap-2 disabled:opacity-50"
            >
              <i v-if="verifyLoading" class="pi pi-spin pi-spinner"></i>
              <span>{{ verifyLoading ? 'A verificar...' : 'Verificar Email' }}</span>
            </button>
          </template>

          <!-- Formulário de registo normal -->
          <template v-else>
            <button
              type="button"
              @click="currentView = 'login'"
              class="flex items-center gap-2 text-text-secondary hover:text-white transition-colors text-sm mb-2"
            >
              <i class="pi pi-arrow-left"></i>
              Voltar ao login
            </button>

            <h2 class="text-xl font-bold">
              {{ selectedRole === 'Student' ? 'Criar Conta de Aluno' : 'Pedir Acesso como Docente' }}
            </h2>
            <p v-if="selectedRole === 'Student'" class="text-text-secondary text-sm">
              Regista-te com o teu email. Terás de verificar o email antes de fazeres login.
            </p>
            <div v-else class="bg-warning/10 border border-warning/30 rounded-btn p-3 flex items-start gap-2">
              <i class="pi pi-info-circle text-warning text-sm mt-0.5 shrink-0"></i>
              <p class="text-warning text-xs leading-relaxed">
                O pedido de acesso fica em análise pelo administrador. Receberás confirmação assim que aprovado.
              </p>
            </div>

            <div class="space-y-1.5">
              <label class="text-xs font-bold text-text-secondary uppercase tracking-widest block">Nome Completo</label>
              <input v-model="regName" type="text" placeholder="Nome completo"
                class="w-full bg-surface p-3.5 rounded-btn border border-white/10 outline-none focus:border-brand text-sm" />
            </div>
            <div class="space-y-1.5">
              <label class="text-xs font-bold text-text-secondary uppercase tracking-widest block">Email</label>
              <input v-model="regEmail" type="email" placeholder="nome@email.com"
                class="w-full bg-surface p-3.5 rounded-btn border border-white/10 outline-none focus:border-brand text-sm" />
            </div>
            <div class="space-y-1.5">
              <label class="text-xs font-bold text-text-secondary uppercase tracking-widest block">Password</label>
              <input v-model="regPassword" type="password" placeholder="Mínimo 6 caracteres"
                class="w-full bg-surface p-3.5 rounded-btn border border-white/10 outline-none focus:border-brand text-sm" />
            </div>
            <div class="space-y-1.5">
              <label class="text-xs font-bold text-text-secondary uppercase tracking-widest block">Confirmar Password</label>
              <input v-model="regConfirm" type="password" placeholder="Repete a password"
                class="w-full bg-surface p-3.5 rounded-btn border border-white/10 outline-none focus:border-brand text-sm"
                @keyup.enter="register" />
            </div>

            <div v-if="regError" class="bg-error/10 border border-error/20 text-error text-sm p-3 rounded-btn flex items-center gap-2">
              <i class="pi pi-exclamation-circle"></i>
              {{ regError }}
            </div>

            <button
              @click="register"
              :disabled="regLoading"
              class="w-full bg-brand py-4 rounded-btn font-bold text-white hover:brightness-110 transition-all flex items-center justify-center gap-2 disabled:opacity-50"
            >
              <i v-if="regLoading" class="pi pi-spin pi-spinner"></i>
              <span>{{ regLoading ? 'A processar...' : selectedRole === 'Student' ? 'Criar Conta' : 'Enviar Pedido' }}</span>
            </button>
          </template>
        </div>

        <!-- Esqueceu a password Step 1: email -->
        <div v-else-if="currentView === 'forgot1'" class="space-y-5">
          <button type="button" @click="currentView = 'login'"
                  class="flex items-center gap-2 text-text-secondary hover:text-white transition-colors text-sm">
            <i class="pi pi-arrow-left"></i> Voltar ao login
          </button>
          <div>
            <h2 class="text-xl font-bold">Recuperar Password</h2>
            <p class="text-text-secondary text-sm mt-1">Insere o teu email para receberes um código de recuperação.</p>
          </div>
          <div class="space-y-1.5">
            <label class="text-xs font-bold text-text-secondary uppercase tracking-widest block">Email</label>
            <input v-model="forgotEmail" type="email" placeholder="nome@ua.pt"
                   class="w-full bg-surface p-4 rounded-btn border border-white/10 outline-none focus:border-brand text-sm transition-colors"
                   @keyup.enter="submitForgotEmail" />
          </div>
          <div v-if="forgotError" class="bg-error/10 border border-error/20 text-error text-sm p-3 rounded-btn flex items-center gap-2">
            <i class="pi pi-exclamation-circle"></i> {{ forgotError }}
          </div>
          <button @click="submitForgotEmail" :disabled="forgotLoading"
                  class="w-full bg-brand py-4 rounded-btn font-bold text-white hover:brightness-110 transition-all flex items-center justify-center gap-2 disabled:opacity-50">
            <i v-if="forgotLoading" class="pi pi-spin pi-spinner"></i>
            <span>{{ forgotLoading ? 'A enviar...' : 'Enviar Código' }}</span>
          </button>
        </div>

        <!-- Esqueceu a password Step 2: código + nova password -->
        <div v-else-if="currentView === 'forgot2'" class="space-y-5">
          <div>
            <h2 class="text-xl font-bold">Nova Password</h2>
            <p class="text-text-secondary text-sm mt-1">
              Código enviado para <span class="text-white">{{ forgotEmail }}</span>. Define a tua nova password.
            </p>
          </div>
          <div class="space-y-1.5">
            <label class="text-xs font-bold text-text-secondary uppercase tracking-widest block">Código de Verificação</label>
            <input v-model="forgotCode" type="text" placeholder="000000" maxlength="6"
                   class="w-full bg-surface p-4 rounded-btn border border-white/10 outline-none focus:border-brand text-sm text-center tracking-widest transition-colors" />
          </div>
          <div class="space-y-1.5">
            <label class="text-xs font-bold text-text-secondary uppercase tracking-widest block">Nova Password</label>
            <div class="relative">
              <input v-model="forgotNewPass" :type="showForgotPass ? 'text' : 'password'" placeholder="Mínimo 6 caracteres"
                     class="w-full bg-surface p-4 rounded-btn border border-white/10 outline-none focus:border-brand text-sm pr-12 transition-colors" />
              <button type="button" @click="showForgotPass = !showForgotPass"
                      class="absolute right-4 top-1/2 -translate-y-1/2 text-text-secondary hover:text-white transition-colors">
                <i :class="showForgotPass ? 'pi pi-eye-slash' : 'pi pi-eye'" class="text-sm"></i>
              </button>
            </div>
          </div>
          <div class="space-y-1.5">
            <label class="text-xs font-bold text-text-secondary uppercase tracking-widest block">Confirmar Nova Password</label>
            <input v-model="forgotConfirmPass" type="password" placeholder="Repete a nova password"
                   class="w-full bg-surface p-4 rounded-btn border border-white/10 outline-none focus:border-brand text-sm transition-colors"
                   @keyup.enter="submitResetPassword" />
          </div>
          <div v-if="forgotError" class="bg-error/10 border border-error/20 text-error text-sm p-3 rounded-btn flex items-center gap-2">
            <i class="pi pi-exclamation-circle"></i> {{ forgotError }}
          </div>
          <button @click="submitResetPassword" :disabled="forgotLoading"
                  class="w-full bg-brand py-4 rounded-btn font-bold text-white hover:brightness-110 transition-all flex items-center justify-center gap-2 disabled:opacity-50">
            <i v-if="forgotLoading" class="pi pi-spin pi-spinner"></i>
            <span>{{ forgotLoading ? 'A alterar...' : 'Alterar Password' }}</span>
          </button>
          <button type="button" @click="currentView = 'forgot1'"
                  class="w-full text-text-secondary text-sm hover:text-white transition-colors py-2">
            Não recebi o código — reenviar
          </button>
        </div>

        <!-- Esqueceu a password — sucesso -->
        <div v-else-if="currentView === 'forgotSuccess'" class="space-y-6 text-center">
          <div class="flex justify-center">
            <div class="w-16 h-16 rounded-full bg-green-500/20 flex items-center justify-center">
              <i class="pi pi-check text-green-400 text-2xl"></i>
            </div>
          </div>
          <div>
            <h2 class="text-xl font-bold">Password Alterada!</h2>
            <p class="text-text-secondary text-sm mt-2">A tua password foi alterada com sucesso.</p>
          </div>
          <button @click="currentView = 'login'"
                  class="w-full bg-brand py-4 rounded-btn font-bold text-white hover:brightness-110 transition-all">
            Entrar
          </button>
        </div>

      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore, type SupportedRole } from '../stores/authStore';

const router = useRouter();
const authStore = useAuthStore();

const selectedRole = ref<SupportedRole>('Admin');
const email = ref('');
const password = ref('');
const showPassword = ref(false);
const rememberMe = ref(true);
const loading = ref(false);
const errorMessage = ref('');
const currentView = ref<'login' | 'register' | 'forgot1' | 'forgot2' | 'forgotSuccess'>('login');
const showVerify = ref(false);
const regName = ref('');
const regEmail = ref('');
const regPassword = ref('');
const regConfirm = ref('');
const regLoading = ref(false);
const regError = ref('');
const regSuccess = ref('');
const verifyCode = ref('');
const verifyLoading = ref(false);
const verifyError = ref('');

// Forgot password state
const forgotEmail = ref('');
const forgotCode = ref('');
const forgotNewPass = ref('');
const forgotConfirmPass = ref('');
const forgotLoading = ref(false);
const forgotError = ref('');
const showForgotPass = ref(false);

function openRegister(): void {
  currentView.value = 'register';
  showVerify.value = false;
  regError.value = '';
  verifyError.value = '';
}

function startForgotPassword(): void {
  forgotEmail.value = email.value;
  forgotError.value = '';
  currentView.value = 'forgot1';
}

async function login(): Promise<void> {
  if (!email.value.trim()) {
    errorMessage.value = 'Preenche o email.';
    return;
  }
  if (!password.value.trim()) {
    errorMessage.value = 'Preenche a password.';
    return;
  }

  errorMessage.value = '';
  loading.value = true;

  try {
    await authStore.login(email.value.trim(), password.value, {
      role: selectedRole.value,
      remember: rememberMe.value,
      allowOfflineFallback: true,
    });

    const redirectMap: Record<string, string> = { Admin: '/admin', Professor: '/professor', Student: '/aluno' };
    await router.replace(redirectMap[selectedRole.value] ?? '/admin');
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : 'Falha ao autenticar.';
  } finally {
    loading.value = false;
  }
}

async function register(): Promise<void> {
  if (!regName.value.trim() || !regEmail.value.trim() || !regPassword.value.trim()) {
    regError.value = 'Preenche todos os campos.';
    return;
  }
  if (regPassword.value.length < 6) {
    regError.value = 'A password deve ter pelo menos 6 caracteres.';
    return;
  }
  if (regPassword.value !== regConfirm.value) {
    regError.value = 'As passwords não coincidem.';
    return;
  }

  regError.value = '';
  regLoading.value = true;

  try {
    if (selectedRole.value === 'Student') {
      await authStore.registerStudent({
        name: regName.value.trim(),
        email: regEmail.value.trim().toLowerCase(),
        password: regPassword.value,
      });
      showVerify.value = true;
    } else {
      await authStore.registerProfessor({
        name: regName.value.trim(),
        email: regEmail.value.trim().toLowerCase(),
        password: regPassword.value,
        department: 'DETI',
        shortBio: 'Conta criada a partir do login unificado',
      });
      showVerify.value = true;
    }
  } catch (error) {
    regError.value = error instanceof Error ? error.message : 'Falha ao registar.';
  } finally {
    regLoading.value = false;
  }
}

async function verifyEmail(): Promise<void> {
  if (verifyCode.value.trim().length !== 6) {
    verifyError.value = 'Introduz o código de 6 dígitos.';
    return;
  }

  verifyError.value = '';
  verifyLoading.value = true;

  try {
    await authStore.verifyStudentEmail(regEmail.value.trim().toLowerCase(), verifyCode.value.trim());
    regSuccess.value = selectedRole.value === 'Professor'
      ? 'Pedido enviado! A tua conta ficará disponível após aprovação do administrador.'
      : 'Email verificado! Podes fazer login agora.';
    currentView.value = 'login';
    showVerify.value = false;
    regName.value = '';
    regEmail.value = '';
    regPassword.value = '';
    regConfirm.value = '';
    verifyCode.value = '';
  } catch (error) {
    verifyError.value = error instanceof Error ? error.message : 'Código inválido ou expirado.';
  } finally {
    verifyLoading.value = false;
  }
}

async function submitForgotEmail(): Promise<void> {
  if (!forgotEmail.value.trim()) {
    forgotError.value = 'Insere o teu email.';
    return;
  }
  forgotError.value = '';
  forgotLoading.value = true;
  try {
    await authStore.forgotPassword(forgotEmail.value.trim());
    currentView.value = 'forgot2';
  } catch (error) {
    forgotError.value = error instanceof Error ? error.message : 'Erro ao enviar código.';
  } finally {
    forgotLoading.value = false;
  }
}

async function submitResetPassword(): Promise<void> {
  if (!forgotCode.value || forgotCode.value.length !== 6) {
    forgotError.value = 'Insere o código de 6 dígitos.';
    return;
  }
  if (!forgotNewPass.value || forgotNewPass.value.length < 6) {
    forgotError.value = 'A nova password deve ter pelo menos 6 caracteres.';
    return;
  }
  if (forgotNewPass.value !== forgotConfirmPass.value) {
    forgotError.value = 'As passwords não coincidem.';
    return;
  }
  forgotError.value = '';
  forgotLoading.value = true;
  try {
    await authStore.resetPassword(forgotEmail.value.trim(), forgotCode.value, forgotNewPass.value);
    currentView.value = 'forgotSuccess';
  } catch (error) {
    forgotError.value = error instanceof Error ? error.message : 'Código inválido ou expirado.';
  } finally {
    forgotLoading.value = false;
  }
}
</script>
