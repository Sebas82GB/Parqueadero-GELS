import { describe, it, expect } from 'vitest';
import { env } from '../../src/config/env.js';
import { obtenerEstablecimiento } from '../../src/services/establecimiento.service.js';

describe('establecimiento.service', () => {
  describe('obtenerEstablecimiento', () => {
    it('mapea los 11 campos desde las variables de entorno', () => {
      const establecimiento = obtenerEstablecimiento();

      expect(establecimiento).toEqual({
        nombre: env.ESTABLECIMIENTO_NOMBRE,
        nit: env.ESTABLECIMIENTO_NIT,
        direccion: env.ESTABLECIMIENTO_DIRECCION,
        telefono: env.ESTABLECIMIENTO_TELEFONO,
        ciudad: env.ESTABLECIMIENTO_CIUDAD,
        regimenTributario: env.ESTABLECIMIENTO_REGIMEN_TRIBUTARIO,
        numeroResolucion: env.ESTABLECIMIENTO_NUMERO_RESOLUCION,
        textoResponsabilidad: env.ESTABLECIMIENTO_TEXTO_RESPONSABILIDAD,
        textoSeguro: env.ESTABLECIMIENTO_TEXTO_SEGURO,
        textoHorario: env.ESTABLECIMIENTO_TEXTO_HORARIO,
        textoReclamos: env.ESTABLECIMIENTO_TEXTO_RECLAMOS,
      });
    });
  });
});
