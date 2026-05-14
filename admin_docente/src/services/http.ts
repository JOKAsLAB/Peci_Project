import axios from 'axios';

const API_BASE_URL = (
  import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:8000'
).replace(/\/$/, '');
console.log('API Base URL:', API_BASE_URL);
export const http = axios.create({
  baseURL: API_BASE_URL,
  withCredentials: true,
});

// Referência global ao authStore (será definida em setupAuthInterceptor)
let authStoreRef: any = null;

// Sliding session — renova token a cada 30 min de atividade
const REFRESH_INTERVAL_MS = 30 * 60 * 1000;
let lastRefreshTime = Date.now();

// Interceptor de pedidos — Content-Type + Auth header
http.interceptors.request.use((config) => {
  if (!(config.data instanceof FormData)) {
    config.headers['Content-Type'] = 'application/json';
  }
  config.headers['ngrok-skip-browser-warning'] = 'true';

  if (authStoreRef?.token && authStoreRef.token !== 'cookie-session') {
    config.headers['Authorization'] = `Bearer ${authStoreRef.token}`;
  }

  return config;
});

// Interceptor de respostas — auto-refresh silencioso + logout em 401
http.interceptors.response.use(
  (response) => {
    if (authStoreRef?.isAuthenticated && Date.now() - lastRefreshTime > REFRESH_INTERVAL_MS) {
      lastRefreshTime = Date.now();
      http.post<{ access_token: string }>('/api/v1/auth/refresh')
        .then(({ data }) => {
          if (authStoreRef && data.access_token) {
            authStoreRef.token = data.access_token;
          }
        })
        .catch(() => {});
    }
    return response;
  },
  async (error) => {
    if (error.response?.status === 401 && authStoreRef?.isAuthenticated) {
      await authStoreRef.logout({ callApi: false });
      window.location.href = '/login';
    }
    return Promise.reject(error);
  },
);

// Setup de interceptor de autenticação
export function setupAuthInterceptor(authStore: any) {
  authStoreRef = authStore;
}

export function getApiErrorMessage(error: unknown, fallback: string): string {
  if (axios.isAxiosError(error)) {
    const detail = (error.response?.data as { detail?: unknown } | undefined)
      ?.detail;
    if (typeof detail === 'string') {
      return detail;
    }

    if (Array.isArray(detail)) {
      const message = detail
        .map((item) =>
          item && typeof item === 'object' && 'msg' in item
            ? (item as { msg?: unknown }).msg
            : null,
        )
        .filter(
          (value): value is string =>
            typeof value === 'string' && value.length > 0,
        )
        .join('; ');

      if (message) {
        return message;
      }
    }

    if (typeof error.message === 'string' && error.message.length > 0) {
      return error.message;
    }
  }

  if (error instanceof Error && error.message) {
    return error.message;
  }

  return fallback;
}
