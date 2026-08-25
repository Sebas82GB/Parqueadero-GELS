import { describe, it, expect } from 'vitest';
import { construirRecibo } from '../../src/services/recibo.service.js';
import { obtenerEstablecimiento } from '../../src/services/establecimiento.service.js';

function buildTicket(overrides = {}) {
  return {
    reciboConsecutivo: 42,
    horaEntrada: new Date('2026-01-05T13:00:00.000Z'),
    horaSalida: new Date('2026-01-05T14:30:00.000Z'),
    desglose: [{ dia: 1, bloqueNumero: 1, tipoCobro: 'PARCIAL', valor: 9000 }],
    valorTotal: 9000,
    vehiculo: { placa: 'ABC123', tipo: 'CARRO' },
    celda: { codigo: 'A-01' },
    pago: { metodo: 'EFECTIVO' },
    operadorSalida: { nombre: 'Carlos Pérez' },
    ...overrides,
  };
}

describe('recibo.service', () => {
  describe('construirRecibo', () => {
    it('devuelve null si el ticket sigue ABIERTO', () => {
      const ticket = buildTicket({ horaSalida: null });

      expect(construirRecibo(ticket)).toBeNull();
    });

    it('arma el recibo completo con pago', () => {
      const ticket = buildTicket();

      const recibo = construirRecibo(ticket);

      expect(recibo).toEqual({
        consecutivo: 42,
        fechaEmision: ticket.horaSalida,
        establecimiento: obtenerEstablecimiento(),
        placa: 'ABC123',
        tipoVehiculo: 'CARRO',
        celda: 'A-01',
        horaEntrada: ticket.horaEntrada,
        horaSalida: ticket.horaSalida,
        tiempoTotal: '1h 30min',
        desglose: ticket.desglose,
        total: 9000,
        metodoPago: 'EFECTIVO',
        operador: 'Carlos Pérez',
      });
    });

    it('metodoPago y desglose reflejan una salida cubierta por mensualidad, sin pago', () => {
      const ticket = buildTicket({
        pago: null,
        valorTotal: 0,
        desglose: [{ tipo: 'MENSUALIDAD', valor: 0 }],
      });

      const recibo = construirRecibo(ticket);

      expect(recibo.metodoPago).toBeNull();
      expect(recibo.total).toBe(0);
      expect(recibo.desglose).toEqual([{ tipo: 'MENSUALIDAD', valor: 0 }]);
    });

    it('operador queda null si no hay operadorSalida', () => {
      const ticket = buildTicket({ operadorSalida: undefined });

      expect(construirRecibo(ticket).operador).toBeNull();
    });
  });
});
