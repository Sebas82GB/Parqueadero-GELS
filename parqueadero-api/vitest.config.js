import { defineConfig, configDefaults } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'node',
    globals: false,
    testTimeout: 10000,
    // Los tests de integración corren bajo vitest.integration.config.js, que
    // carga .env.test y aplica su propio aislamiento de base de datos. Se
    // excluyen aquí para que un `vitest run` genérico no pueda tocarlos
    // usando el entorno equivocado.
    exclude: [...configDefaults.exclude, 'tests/integration/**'],
  },
});
