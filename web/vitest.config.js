import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    environment: 'node',
    globals: true,
    include: ['../scripts/test/frontend/admin_docente/**/*.{test,spec}.{js,ts}'],
    clearMocks: true,
    restoreMocks: true,
  },
})
