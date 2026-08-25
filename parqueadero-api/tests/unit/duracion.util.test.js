import { describe, it, expect } from 'vitest';
import { formatearDuracion } from '../../src/utils/duracion.util.js';

function fecha(iso) {
  return new Date(iso);
}

describe('formatearDuracion', () => {
  it('formatea minutos solos', () => {
    const result = formatearDuracion(
      fecha('2026-01-01T08:00:00.000Z'),
      fecha('2026-01-01T08:45:00.000Z'),
    );
    expect(result).toBe('45min');
  });

  it('formatea horas y minutos', () => {
    const result = formatearDuracion(
      fecha('2026-01-01T08:00:00.000Z'),
      fecha('2026-01-01T09:30:00.000Z'),
    );
    expect(result).toBe('1h 30min');
  });

  it('formatea una duración exacta en horas', () => {
    const result = formatearDuracion(
      fecha('2026-01-01T08:00:00.000Z'),
      fecha('2026-01-01T10:00:00.000Z'),
    );
    expect(result).toBe('2h 0min');
  });

  it('formatea multi-día', () => {
    const result = formatearDuracion(
      fecha('2026-01-01T16:00:00.000Z'),
      fecha('2026-01-03T19:15:00.000Z'),
    );
    expect(result).toBe('2d 3h 15min');
  });

  it('formatea menos de un minuto como 0min', () => {
    const result = formatearDuracion(
      fecha('2026-01-01T08:00:00.000Z'),
      fecha('2026-01-01T08:00:30.000Z'),
    );
    expect(result).toBe('0min');
  });
});
