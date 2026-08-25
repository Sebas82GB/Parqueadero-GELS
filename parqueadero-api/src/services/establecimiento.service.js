import { env } from '../config/env.js';

// Sin persistencia: los datos del establecimiento viven en variables de
// entorno (ver ESTABLECIMIENTO_* en config/env.js), mismo patrón que
// health.service.js. Única fuente de verdad, reutilizada también por
// recibo.service.js para armar el recibo de salida.
export function obtenerEstablecimiento() {
  return {
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
  };
}
