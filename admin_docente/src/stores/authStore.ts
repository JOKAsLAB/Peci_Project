import axios from 'axios';
import { defineStore } from 'pinia';
import { computed, ref } from 'vue';
import { getApiErrorMessage, http } from '../services/http';

export type SupportedRole = 'Admin' | 'Professor' | 'Student';

export interface AuthUser {
  id?: string;
  name: string;
  email: string;
  role: 'Admin' | 'Professor' | 'Student';
  status?: string;
  course_units?: Array<{ id: number; name: string; code?: string }>;
}

interface AuthPayload {
  access_token?: string;
  user: AuthUser;
}

interface LoginOptions {
  role: SupportedRole;
  remember?: boolean;
  allowOfflineFallback?: boolean;
}

const AUTH_LOCAL_KEY = 'peci_unified_auth_v1';
const AUTH_SESSION_KEY = 'peci_unified_auth_session_v1';

function isSupportedRole(role: unknown): role is SupportedRole {
  return role === 'Admin' || role === 'Professor' || role === 'Student';
}

export const useAuthStore = defineStore('auth', () => {
  const user = ref<AuthUser | null>(null);
  const token = ref<string | null>(null);
  const persistence = ref<'local' | 'session'>('local');

  const isAuthenticated = computed(() => Boolean(user.value));
  const activeRole = computed<SupportedRole | null>(() => {
    if (!user.value || !isSupportedRole(user.value.role)) return null;
    return user.value.role;
  });
  const hasCourseUnits = computed(() => {
    if (!user.value || user.value.role !== 'Professor') return true;
    return (
      Array.isArray(user.value.course_units) &&
      user.value.course_units.length > 0
    );
  });

  function persistSession(): void {
    const serialized = JSON.stringify({ user: user.value, token: token.value });
    if (persistence.value === 'local') {
      localStorage.setItem(AUTH_LOCAL_KEY, serialized);
      sessionStorage.removeItem(AUTH_SESSION_KEY);
      return;
    }
    sessionStorage.setItem(AUTH_SESSION_KEY, serialized);
    localStorage.removeItem(AUTH_LOCAL_KEY);
  }

  function clearPersisted(): void {
    localStorage.removeItem(AUTH_LOCAL_KEY);
    sessionStorage.removeItem(AUTH_SESSION_KEY);
  }

  function hydrate(): void {
    const localRaw = localStorage.getItem(AUTH_LOCAL_KEY);
    const sessionRaw = sessionStorage.getItem(AUTH_SESSION_KEY);
    const raw = localRaw ?? sessionRaw;
    if (!raw) return;

    persistence.value = localRaw ? 'local' : 'session';
    try {
      const parsed = JSON.parse(raw) as { user?: AuthUser; token?: string };
      user.value = parsed.user ?? null;
      token.value = parsed.token ?? null;
    } catch {
      user.value = null;
      token.value = null;
      clearPersisted();
    }
  }

  function setSession(payload: AuthPayload, remember = true): void {
    user.value = payload.user;
    token.value = payload.access_token ?? 'cookie-session';
    persistence.value = remember ? 'local' : 'session';
    persistSession();
  }

  function setOfflineSession(
    email: string,
    role: SupportedRole,
    remember = true,
  ): AuthUser {
    const nameMap = { Admin: 'Admin Local', Professor: 'Professor Local', Student: 'Aluno Local' };
    const offlineUser: AuthUser = {
      id: 'local-dev-user',
      name: nameMap[role] || 'Utilizador Local',
      email: email || `${role.toLowerCase()}@local.dev`,
      role,
      status: 'Active',
    };

    setSession(
      { access_token: 'local-dev-token', user: offlineUser },
      remember,
    );
    return offlineUser;
  }

  async function login(
    email: string,
    password: string,
    options: LoginOptions,
  ): Promise<AuthUser> {
    const remember = options.remember !== false;
    const allowOfflineFallback = options.allowOfflineFallback !== false;

    try {
      const { data: loginData } = await http.post<AuthPayload>(
        '/api/v1/auth/login',
        {
          email,
          password,
        },
      );

      if (!loginData || !loginData.user) {
        throw new Error('Falha ao autenticar.');
      }

      if (loginData.user?.role !== options.role) {
        throw new Error('Sem permissões de acesso.');
      }

      setSession(loginData, remember);

      if (loginData.user.role === 'Professor') {
        await loadProfessorCourseUnits();
      }

      return loginData.user;
    } catch (error) {
      if (
        allowOfflineFallback &&
        axios.isAxiosError(error) &&
        !error.response
      ) {
        return setOfflineSession(email, options.role, remember);
      }

      throw new Error(getApiErrorMessage(error, 'Falha ao autenticar.'));
    }
  }

  async function loadProfessorCourseUnits(): Promise<void> {
    if (!user.value || user.value.role !== 'Professor') return;

    try {
      const { data } = await http.get<
        Array<{ id_uc: number; name: string; code?: string }>
      >('/api/v1/professors/course-units');

      if (user.value) {
        user.value.course_units = data.map((uc) => ({
          id: uc.id_uc,
          name: uc.name,
          code: uc.code,
        }));
        persistSession();
      }
    } catch (error) {
      console.warn('Erro ao carregar disciplinas do professor:', error);
      // Se falhar, deixa course_units como está
    }
  }

  async function restoreSession(): Promise<boolean> {
    if (token.value === 'local-dev-token') {
      return true;
    }

    try {
      const { data: meData } = await http.get<AuthUser>('/api/v1/auth/me');

      const role = (meData as { role?: unknown }).role;
      if (!isSupportedRole(role)) {
        await logout({ callApi: false });
        return false;
      }

      user.value = meData as AuthUser;
      token.value = token.value || 'cookie-session';
      persistSession();

      if (user.value.role === 'Professor') {
        await loadProfessorCourseUnits();
      }

      return true;
    } catch {
      await logout({ callApi: false });
      return false;
    }
  }

  async function registerStudent(payload: {
    name: string;
    email: string;
    password: string;
  }): Promise<void> {
    try {
      await http.post('/api/v1/auth/register', {
        name: payload.name,
        email: payload.email,
        password: payload.password,
        role: 'Student',
      });
    } catch (error) {
      throw new Error(getApiErrorMessage(error, 'Falha ao registar conta de aluno.'));
    }
  }

  async function registerProfessor(payload: {
    name: string;
    email: string;
    password: string;
    department?: string;
    office?: string;
    shortBio?: string;
  }): Promise<void> {
    try {
      await http.post('/api/v1/auth/register', {
        name: payload.name,
        email: payload.email,
        password: payload.password,
        role: 'Professor',
        department: payload.department,
        office: payload.office,
        short_bio: payload.shortBio,
      });
    } catch (error) {
      throw new Error(
        getApiErrorMessage(error, 'Falha ao registar conta docente.'),
      );
    }
  }

  async function verifyStudentEmail(email: string, code: string): Promise<void> {
    try {
      await http.post('/api/v1/auth/verify-email', { email, code });
    } catch (error) {
      throw new Error(getApiErrorMessage(error, 'Código inválido ou expirado.'));
    }
  }

  async function resendVerification(email: string): Promise<void> {
    try {
      await http.post('/api/v1/auth/resend-verification', { email });
    } catch (error) {
      throw new Error(getApiErrorMessage(error, 'Erro ao reenviar código.'));
    }
  }

  async function forgotPassword(email: string): Promise<void> {
    try {
      await http.post('/api/v1/auth/forgot-password', { email });
    } catch (error) {
      throw new Error(getApiErrorMessage(error, 'Erro ao solicitar recuperação de password.'));
    }
  }

  async function resetPassword(email: string, code: string, newPassword: string): Promise<void> {
    try {
      await http.post('/api/v1/auth/reset-password', { email, code, new_password: newPassword });
    } catch (error) {
      throw new Error(getApiErrorMessage(error, 'Código inválido ou expirado.'));
    }
  }

  async function logout(options: { callApi?: boolean } = {}): Promise<void> {
    const callApi = options.callApi !== false;
    try {
      if (callApi && token.value !== 'local-dev-token') {
        await http.post('/api/v1/auth/logout');
      }
    } catch {
      // Ignore API failures on logout; local session must still be cleared.
    }

    user.value = null;
    token.value = null;
    clearPersisted();
  }

  hydrate();

  return {
    user,
    token,
    isAuthenticated,
    activeRole,
    hasCourseUnits,
    login,
    restoreSession,
    registerStudent,
    registerProfessor,
    verifyStudentEmail,
    resendVerification,
    forgotPassword,
    resetPassword,
    loadProfessorCourseUnits,
    logout,
  };
});
