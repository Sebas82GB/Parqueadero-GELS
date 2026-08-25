import { describe, it, expect } from 'vitest';
import { calcularTarifa, previsualizarTarifa } from '../../src/services/tarifa-calculo.service.js';
import { UnprocessableEntityError } from '../../src/errors/index.js';

function bogota(y, m, d, h, mi = 0, s = 0) {
  return new Date(Date.UTC(y, m - 1, d, h + 5, mi, s));
}

const TARIFA_CARRO = {
  tipoVehiculo: 'CARRO',
  valorMinuto: 100,
  valorPlena: 20000,
  valorNocturna: 16000,
};

const TARIFA_MOTO = {
  tipoVehiculo: 'MOTO',
  valorMinuto: 60,
  valorPlena: 10000,
  valorNocturna: 8000,
};

const TARIFA_OTRO = {
  tipoVehiculo: 'OTRO',
};

// Horario viejo (fijo antes de que existiera HorarioOperacion): apertura
// 6:00 AM, cierre 9:00 PM. Se mantiene como fixture de regresión para la
// tabla de referencia histórica de la sección 5.4.
const HORARIO_FIJO = { apertura: '06:00', cierre: '21:00' };

// Horario del caso de verificación obligatorio nuevo: apertura 8:00 AM,
// cierre 9:30 PM.
const HORARIO_NUEVO = { apertura: '08:00', cierre: '21:30' };

describe('tarifa-calculo.service', () => {
  describe('calcularTarifa - tabla de referencia CARRO (sección 5.4, horario 6:00 AM/9:00 PM)', () => {
    it('8:00 AM a 9:30 AM: 90 min sin topar', () => {
      const { valorTotal } = calcularTarifa({
        horaEntrada: bogota(2026, 1, 5, 8, 0),
        horaSalida: bogota(2026, 1, 5, 9, 30),
        tarifa: TARIFA_CARRO,
        horario: HORARIO_FIJO,
      });

      expect(valorTotal).toBe(9000);
    });

    it('8:00 AM a 12:00 PM: bloque 1 topado en plena', () => {
      const { valorTotal } = calcularTarifa({
        horaEntrada: bogota(2026, 1, 5, 8, 0),
        horaSalida: bogota(2026, 1, 5, 12, 0),
        tarifa: TARIFA_CARRO,
        horario: HORARIO_FIJO,
      });

      expect(valorTotal).toBe(20000);
    });

    it('8:00 AM a 3:00 PM: plena + 60 min del bloque 2', () => {
      const { valorTotal } = calcularTarifa({
        horaEntrada: bogota(2026, 1, 5, 8, 0),
        horaSalida: bogota(2026, 1, 5, 15, 0),
        tarifa: TARIFA_CARRO,
        horario: HORARIO_FIJO,
      });

      expect(valorTotal).toBe(26000);
    });

    it('8:00 AM a 8:30 PM: 2 plenas, tope de bloques del día', () => {
      const { valorTotal } = calcularTarifa({
        horaEntrada: bogota(2026, 1, 5, 8, 0),
        horaSalida: bogota(2026, 1, 5, 20, 30),
        tarifa: TARIFA_CARRO,
        horario: HORARIO_FIJO,
      });

      expect(valorTotal).toBe(40000);
    });

    it('Día 1 4:00 PM a Día 2 12:00 PM: nocturna + plena del día 2', () => {
      const { valorTotal } = calcularTarifa({
        horaEntrada: bogota(2026, 1, 5, 16, 0),
        horaSalida: bogota(2026, 1, 6, 12, 0),
        tarifa: TARIFA_CARRO,
        horario: HORARIO_FIJO,
      });

      expect(valorTotal).toBe(36000);
    });

    it('Día 1 4:00 PM a Día 3 12:00 PM: nocturna + (plena + nocturna) + plena', () => {
      const { valorTotal } = calcularTarifa({
        horaEntrada: bogota(2026, 1, 5, 16, 0),
        horaSalida: bogota(2026, 1, 7, 12, 0),
        tarifa: TARIFA_CARRO,
        horario: HORARIO_FIJO,
      });

      expect(valorTotal).toBe(72000);
    });
  });

  describe('calcularTarifa - bordes (sección 7, horario 6:00 AM/9:00 PM)', () => {
    it('salida exactamente a las 6:00 AM: el día siguiente no genera cobro', () => {
      const { valorTotal } = calcularTarifa({
        horaEntrada: bogota(2026, 1, 5, 8, 0),
        horaSalida: bogota(2026, 1, 6, 6, 0),
        tarifa: TARIFA_CARRO,
        horario: HORARIO_FIJO,
      });

      expect(valorTotal).toBe(36000);
    });

    it('entrada 8:55 PM, salida al día siguiente 10:00 AM', () => {
      const { valorTotal } = calcularTarifa({
        horaEntrada: bogota(2026, 1, 5, 20, 55),
        horaSalida: bogota(2026, 1, 6, 10, 0),
        tarifa: TARIFA_CARRO,
        horario: HORARIO_FIJO,
      });

      expect(valorTotal).toBe(36000);
    });

    it('estadía de menos de un minuto: se redondea hacia arriba a 1 minuto', () => {
      const { valorTotal } = calcularTarifa({
        horaEntrada: bogota(2026, 1, 5, 8, 0, 0),
        horaSalida: bogota(2026, 1, 5, 8, 0, 20),
        tarifa: TARIFA_CARRO,
        horario: HORARIO_FIJO,
      });

      expect(valorTotal).toBe(100);
    });

    it('moto en el minuto 166: no topa todavía', () => {
      const { valorTotal } = calcularTarifa({
        horaEntrada: bogota(2026, 1, 5, 8, 0),
        horaSalida: bogota(2026, 1, 5, 10, 46),
        tarifa: TARIFA_MOTO,
        horario: HORARIO_FIJO,
      });

      expect(valorTotal).toBe(9960);
    });

    it('moto en el minuto 167: topa en 10.000 exactos, no 10.020', () => {
      const { valorTotal } = calcularTarifa({
        horaEntrada: bogota(2026, 1, 5, 8, 0),
        horaSalida: bogota(2026, 1, 5, 10, 47),
        tarifa: TARIFA_MOTO,
        horario: HORARIO_FIJO,
      });

      expect(valorTotal).toBe(10000);
    });

    it('moto en el minuto 168: sigue topada en 10.000', () => {
      const { valorTotal } = calcularTarifa({
        horaEntrada: bogota(2026, 1, 5, 8, 0),
        horaSalida: bogota(2026, 1, 5, 10, 48),
        tarifa: TARIFA_MOTO,
        horario: HORARIO_FIJO,
      });

      expect(valorTotal).toBe(10000);
    });

    it('mensualidad vigente que cubre toda la estadía: total 0', () => {
      const { valorTotal } = calcularTarifa({
        horaEntrada: bogota(2026, 1, 5, 8, 0),
        horaSalida: bogota(2026, 1, 5, 12, 0),
        tarifa: TARIFA_CARRO,
        horario: HORARIO_FIJO,
        mensualidad: {
          fechaInicio: bogota(2026, 1, 1, 0, 0),
          fechaFin: bogota(2026, 1, 31, 23, 59),
          estadoPago: 'PAGADA',
        },
      });

      expect(valorTotal).toBe(0);
    });

    it('mensualidad que vence entre la entrada y la salida: total 0 igual', () => {
      const { valorTotal } = calcularTarifa({
        horaEntrada: bogota(2026, 1, 5, 8, 0),
        horaSalida: bogota(2026, 1, 5, 12, 0),
        tarifa: TARIFA_CARRO,
        horario: HORARIO_FIJO,
        mensualidad: {
          fechaInicio: bogota(2026, 1, 1, 0, 0),
          fechaFin: bogota(2026, 1, 5, 9, 0),
          estadoPago: 'PAGADA',
        },
      });

      expect(valorTotal).toBe(0);
    });

    it('mensualidad NO_PAGADA pero dentro de sus fechas: no bloquea, total 0', () => {
      const { valorTotal } = calcularTarifa({
        horaEntrada: bogota(2026, 1, 5, 8, 0),
        horaSalida: bogota(2026, 1, 5, 12, 0),
        tarifa: TARIFA_CARRO,
        horario: HORARIO_FIJO,
        mensualidad: {
          fechaInicio: bogota(2026, 1, 1, 0, 0),
          fechaFin: bogota(2026, 1, 31, 23, 59),
          estadoPago: 'NO_PAGADA',
        },
      });

      expect(valorTotal).toBe(0);
    });

    it('mensualidad con celdaId distinto al de la estadía: no exime, cobra el valor real', () => {
      const { valorTotal, desglose } = calcularTarifa({
        horaEntrada: bogota(2026, 1, 5, 8, 0),
        horaSalida: bogota(2026, 1, 5, 9, 30),
        tarifa: TARIFA_CARRO,
        horario: HORARIO_FIJO,
        celdaId: 'celda-b',
        mensualidad: {
          celdaId: 'celda-a',
          fechaInicio: bogota(2026, 1, 1, 0, 0),
          fechaFin: bogota(2026, 1, 31, 23, 59),
          estadoPago: 'PAGADA',
        },
      });

      expect(valorTotal).toBe(9000);
      expect(desglose[0].tipoCobro).not.toBe('MENSUALIDAD');
    });

    it('mensualidad con celdaId igual al de la estadía: sí exime, total 0', () => {
      const { valorTotal } = calcularTarifa({
        horaEntrada: bogota(2026, 1, 5, 8, 0),
        horaSalida: bogota(2026, 1, 5, 9, 30),
        tarifa: TARIFA_CARRO,
        horario: HORARIO_FIJO,
        celdaId: 'celda-a',
        mensualidad: {
          celdaId: 'celda-a',
          fechaInicio: bogota(2026, 1, 1, 0, 0),
          fechaFin: bogota(2026, 1, 31, 23, 59),
          estadoPago: 'PAGADA',
        },
      });

      expect(valorTotal).toBe(0);
    });

    it('mensualidad sin celdaId (no reservada): exime sin importar la celda de la estadía', () => {
      const { valorTotal } = calcularTarifa({
        horaEntrada: bogota(2026, 1, 5, 8, 0),
        horaSalida: bogota(2026, 1, 5, 9, 30),
        tarifa: TARIFA_CARRO,
        horario: HORARIO_FIJO,
        celdaId: 'celda-cualquiera',
        mensualidad: {
          celdaId: null,
          fechaInicio: bogota(2026, 1, 1, 0, 0),
          fechaFin: bogota(2026, 1, 31, 23, 59),
          estadoPago: 'PAGADA',
        },
      });

      expect(valorTotal).toBe(0);
    });

    it('DIAGNÓSTICO bug: 8 minutos de estadía, tarifa CARRO real, sin mensualidad → $800', () => {
      const { valorTotal } = calcularTarifa({
        horaEntrada: bogota(2026, 1, 5, 8, 0, 0),
        horaSalida: bogota(2026, 1, 5, 8, 8, 0),
        tarifa: TARIFA_CARRO,
        horario: HORARIO_FIJO,
      });

      expect(valorTotal).toBe(800);
    });

    it('vehículo OTRO: no calcula, devuelve el valor que aporta el operador', () => {
      const { valorTotal, desglose } = calcularTarifa({
        horaEntrada: bogota(2026, 1, 5, 8, 0),
        horaSalida: bogota(2026, 1, 5, 12, 0),
        tarifa: TARIFA_OTRO,
        horario: HORARIO_FIJO,
        valorManual: 15000,
      });

      expect(valorTotal).toBe(15000);
      expect(desglose).toEqual([{ tipo: 'MANUAL', valor: 15000 }]);
    });
  });

  describe('calcularTarifa - horario dinámico (HorarioOperacion, apertura 8:00 AM/cierre 9:30 PM)', () => {
    it('caso obligatorio: entrada día 1 11:14 a.m., salida día 2 9:28 a.m. → $44.800', () => {
      const { valorTotal, desglose } = calcularTarifa({
        horaEntrada: bogota(2026, 1, 5, 11, 14),
        horaSalida: bogota(2026, 1, 6, 9, 28),
        tarifa: TARIFA_CARRO,
        horario: HORARIO_NUEVO,
      });

      expect(valorTotal).toBe(44800);
      expect(desglose).toEqual([
        expect.objectContaining({ dia: 1, bloqueNumero: 1, minutos: 360, tipoCobro: 'PLENA', valor: 20000 }),
        expect.objectContaining({ dia: 1, bloqueNumero: 2, minutos: 256, tipoCobro: 'NOCTURNA', valor: 16000 }),
        expect.objectContaining({ dia: 2, bloqueNumero: 1, minutos: 88, tipoCobro: 'PARCIAL', valor: 8800 }),
      ]);
    });

    // La nocturna es un valor plano (tarifa.valorNocturna), no proporcional a
    // los minutos del bloque truncado: por eso 90 min de estadía nocturna
    // cuestan lo mismo que una noche entera, igual que hoy con la tarifa fija.
    it('entrada 8:00 p.m., salida 11:00 p.m. (antes de la apertura siguiente): solo nocturna', () => {
      const { valorTotal, desglose } = calcularTarifa({
        horaEntrada: bogota(2026, 1, 5, 20, 0),
        horaSalida: bogota(2026, 1, 5, 23, 0),
        tarifa: TARIFA_CARRO,
        horario: HORARIO_NUEVO,
      });

      expect(valorTotal).toBe(16000);
      expect(desglose).toEqual([
        expect.objectContaining({ minutos: 90, tipoCobro: 'NOCTURNA', valor: 16000 }),
      ]);
    });

    it('entrada 8:00 p.m., salida día siguiente 9:15 a.m. (después de la apertura): nocturna + bloque del día 2', () => {
      const { valorTotal, desglose } = calcularTarifa({
        horaEntrada: bogota(2026, 1, 5, 20, 0),
        horaSalida: bogota(2026, 1, 6, 9, 15),
        tarifa: TARIFA_CARRO,
        horario: HORARIO_NUEVO,
      });

      expect(valorTotal).toBe(23500);
      expect(desglose).toEqual([
        expect.objectContaining({ dia: 1, minutos: 90, tipoCobro: 'NOCTURNA', valor: 16000 }),
        expect.objectContaining({ dia: 2, minutos: 75, tipoCobro: 'PARCIAL', valor: 7500 }),
      ]);
    });
  });

  describe('previsualizarTarifa', () => {
    it('8:00 AM a 9:30 AM: mismo total por bloques que calcularTarifa', () => {
      const { valorTotal } = previsualizarTarifa({
        horaEntrada: bogota(2026, 1, 5, 8, 0),
        horaSalida: bogota(2026, 1, 5, 9, 30),
        tarifa: TARIFA_CARRO,
        horario: HORARIO_FIJO,
      });

      expect(valorTotal).toBe(9000);
    });

    it('mensualidad vigente: total 0 con desglose MENSUALIDAD explícito', () => {
      const { valorTotal, desglose } = previsualizarTarifa({
        horaEntrada: bogota(2026, 1, 5, 8, 0),
        horaSalida: bogota(2026, 1, 5, 12, 0),
        tarifa: TARIFA_CARRO,
        horario: HORARIO_FIJO,
        mensualidad: {
          fechaInicio: bogota(2026, 1, 1, 0, 0),
          fechaFin: bogota(2026, 1, 31, 23, 59),
          estadoPago: 'PAGADA',
        },
      });

      expect(valorTotal).toBe(0);
      expect(desglose).toEqual([{ tipo: 'MENSUALIDAD', valor: 0 }]);
    });

    it('mensualidad con celdaId distinto al de la estadía: no exime, muestra el cobro real', () => {
      const { valorTotal, desglose } = previsualizarTarifa({
        horaEntrada: bogota(2026, 1, 5, 8, 0),
        horaSalida: bogota(2026, 1, 5, 9, 30),
        tarifa: TARIFA_CARRO,
        horario: HORARIO_FIJO,
        celdaId: 'celda-b',
        mensualidad: {
          celdaId: 'celda-a',
          fechaInicio: bogota(2026, 1, 1, 0, 0),
          fechaFin: bogota(2026, 1, 31, 23, 59),
          estadoPago: 'PAGADA',
        },
      });

      expect(valorTotal).toBe(9000);
      expect(desglose.some((b) => b.tipoCobro === 'MENSUALIDAD')).toBe(false);
    });

    it('mensualidad con celdaId igual al de la estadía: sí exime, total 0', () => {
      const { valorTotal } = previsualizarTarifa({
        horaEntrada: bogota(2026, 1, 5, 8, 0),
        horaSalida: bogota(2026, 1, 5, 9, 30),
        tarifa: TARIFA_CARRO,
        horario: HORARIO_FIJO,
        celdaId: 'celda-a',
        mensualidad: {
          celdaId: 'celda-a',
          fechaInicio: bogota(2026, 1, 1, 0, 0),
          fechaFin: bogota(2026, 1, 31, 23, 59),
          estadoPago: 'PAGADA',
        },
      });

      expect(valorTotal).toBe(0);
    });

    it('vehículo OTRO sin mensualidad: no exige valorManual, indica que lo digita el operador', () => {
      const { valorTotal, desglose } = previsualizarTarifa({
        horaEntrada: bogota(2026, 1, 5, 8, 0),
        horaSalida: bogota(2026, 1, 5, 12, 0),
        tarifa: TARIFA_OTRO,
        horario: HORARIO_FIJO,
      });

      expect(valorTotal).toBeNull();
      expect(desglose).toEqual([
        { tipo: 'MANUAL', valor: null, motivo: expect.any(String) },
      ]);
    });

    it('rango inválido: lanza UnprocessableEntityError RANGO_FECHAS_INVALIDO', () => {
      const error = () =>
        previsualizarTarifa({
          horaEntrada: bogota(2026, 1, 5, 12, 0),
          horaSalida: bogota(2026, 1, 5, 8, 0),
          tarifa: TARIFA_CARRO,
          horario: HORARIO_FIJO,
        });

      expect(error).toThrow(UnprocessableEntityError);
      try {
        error();
      } catch (err) {
        expect(err.code).toBe('RANGO_FECHAS_INVALIDO');
      }
    });
  });
});
