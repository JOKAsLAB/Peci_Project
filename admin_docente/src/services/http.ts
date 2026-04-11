import axios from 'axios';

const API_BASE_URL = (
  import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:8000'
).replace(/\/$/, '');
console.log('API Base URL:', API_BASE_URL);
export const http = axios.create({
  baseURL: API_BASE_URL,
  withCredentials: true,
});

// Interceptor para adicionar Content-Type quando necessário (mas permitir FormData)
http.interceptors.request.use((config) => {
  // Se o data é FormData, deixa o navegador definir o Content-Type automaticamente
  if (!(config.data instanceof FormData)) {
    config.headers['Content-Type'] = 'application/json';
  }
  return config;
});

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
