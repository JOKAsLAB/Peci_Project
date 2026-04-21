<template>
  <div class="min-h-screen bg-background font-inter text-text-primary flex items-center justify-center px-6 py-12">
    <div class="w-full max-w-md mx-auto">

      <!-- Card principal -->
      <div class="panel-surface rounded-card p-10 shadow-2xl">

        <!-- Logo -->
        <div class="flex flex-col items-center mb-8">
          <img
            src="/logo_LogicStreak.png"
            alt="LogicStreak"
            class="rounded-2xl shadow-lg"
            style="width: 200px; height: 200px; object-fit: contain;"
          />
          <p class="text-text-secondary text-sm mt-3">Painel de Gestão · Universidade de Aveiro</p>
        </div>

        <!-- Formulário de login -->
        <div v-if="!showRegister" class="space-y-5">

          <!-- Seletor de papel -->
          <div class="flex gap-2 bg-surface rounded-btn p-1 border border-white/10">
            <button
              type="button"
              @click="selectedRole = 'Admin'"
              :class="selectedRole === 'Admin' ? 'bg-brand text-white' : 'text-text-secondary'"
              class="flex-1 py-2.5 rounded-btn text-sm font-bold transition-all"
            >
              Admin
            </button>
            <button
              type="button"
              @click="selectedRole = 'Professor'"
              :class="selectedRole === 'Professor' ? 'bg-brand text-white' : 'text-text-secondary'"
              class="flex-1 py-2.5 rounded-btn text-sm font-bold transition-all"
            >
              Professor
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

          <!-- Lembrar-me -->
          <label class="flex items-center gap-2 text-text-secondary text-sm cursor-pointer">
            <input type="checkbox" v-model="rememberMe" class="accent-brand" />
            Lembrar-me
          </label>

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
            <span>{{ loading ? 'A autenticar...' : `Entrar como ${selectedRole}` }}</span>
          </button>

          <!-- Registo (apenas Professor) -->
          <template v-if="selectedRole === 'Professor'">
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
              Criar Conta de Professor
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

        <!-- Formulário de registo -->
        <div v-else class="space-y-4">
          <button
            type="button"
            @click="showRegister = false"
            class="flex items-center gap-2 text-text-secondary hover:text-white transition-colors text-sm mb-2"
          >
            <i class="pi pi-arrow-left"></i>
            Voltar ao login
          </button>

          <h2 class="text-xl font-bold">Criar Conta de Professor</h2>
          <p class="text-text-secondary text-sm">Regista-te com o teu email institucional da UA.</p>
          <p class="text-warning text-xs">Contas de docente requerem aprovação do administrador.</p>

          <div class="space-y-1.5">
            <label class="text-xs font-bold text-text-secondary uppercase tracking-widest block">Nome Completo</label>
            <input v-model="regName" type="text" placeholder="Nome completo"
              class="w-full bg-surface p-3.5 rounded-btn border border-white/10 outline-none focus:border-brand text-sm" />
          </div>
          <div class="space-y-1.5">
            <label class="text-xs font-bold text-text-secondary uppercase tracking-widest block">Email Institucional</label>
            <input v-model="regEmail" type="email" placeholder="nome@ua.pt"
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
            <span>{{ regLoading ? 'A processar...' : 'Enviar Pedido' }}</span>
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
const showRegister = ref(false);
const regName = ref('');
const regEmail = ref('');
const regPassword = ref('');
const regConfirm = ref('');
const regLoading = ref(false);
const regError = ref('');
const regSuccess = ref('');

function openRegister(): void {
  selectedRole.value = 'Professor';
  showRegister.value = true;
  regError.value = '';
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

    await router.replace(selectedRole.value === 'Admin' ? '/admin' : '/professor');
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Falha ao autenticar.';
    errorMessage.value =
      message === 'Account pending admin approval'
        ? 'Conta em análise. Aguarda aprovação do administrador.'
        : message;
  } finally {
    loading.value = false;
  }
}

async function register(): Promise<void> {
  if (!regName.value.trim() || !regEmail.value.trim() || !regPassword.value.trim()) {
    regError.value = 'Preenche todos os campos.';
    return;
  }
  if (!regEmail.value.toLowerCase().endsWith('@ua.pt')) {
    regError.value = 'Usa o teu email institucional (@ua.pt).';
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
    await authStore.registerProfessor({
      name: regName.value.trim(),
      email: regEmail.value.trim().toLowerCase(),
      password: regPassword.value,
      department: 'DETI',
      shortBio: 'Conta criada a partir do login unificado',
    });

    regSuccess.value = 'Pedido enviado. A tua conta ficará disponível após aprovação do administrador.';
    showRegister.value = false;
    regName.value = '';
    regEmail.value = '';
    regPassword.value = '';
    regConfirm.value = '';
  } catch (error) {
    regError.value = error instanceof Error ? error.message : 'Falha ao registar conta docente.';
  } finally {
    regLoading.value = false;
  }
}
</script>
