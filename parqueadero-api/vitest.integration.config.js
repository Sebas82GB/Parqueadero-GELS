import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'node',
    globals: false,
    testTimeout: 20000,
    include: ['tests/integration/**/*.test.js'],
    globalSetup: ['./tests/integration/global-setup.js'],
    setupFiles: ['./tests/integration/setup.js'],
    // Todos los archivos de integración pegan contra la misma BD de test
    // real. Varios ya comparten tabla (usuarios, refresh_tokens, y cada vez
    // más a futuro por las FK del dominio), y sus beforeEach hacen
    // deleteMany({}) de tabla completa: en paralelo, el truncate de un
    // archivo puede borrar filas que otro archivo acaba de crear a mitad de
    // un test. Se corren en serie para que eso no pueda pasar.
    fileParallelism: false,
  },
});
