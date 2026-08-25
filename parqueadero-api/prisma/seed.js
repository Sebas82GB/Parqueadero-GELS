import bcrypt from 'bcryptjs';
import { prisma } from '../src/config/database.js';

const ZONAS = [
  {
    prefijo: 'A',
    nombre: 'Zona A',
    celdas: [
      { tipo: 'CARRO', cantidad: 10 },
      { tipo: 'MOTO', cantidad: 4 },
      { tipo: 'BICICLETA', cantidad: 1 },
    ],
  },
  {
    prefijo: 'B',
    nombre: 'Zona B',
    celdas: [
      { tipo: 'CARRO', cantidad: 10 },
      { tipo: 'MOTO', cantidad: 4 },
      { tipo: 'BICICLETA', cantidad: 1 },
    ],
  },
];

const TARIFAS_VIGENTES = [
  {
    tipoVehiculo: 'CARRO',
    valorMinuto: 100,
    valorPlena: 20000,
    valorNocturna: 16000,
    valorMes: 180000,
  },
  {
    tipoVehiculo: 'MOTO',
    valorMinuto: 60,
    valorPlena: 10000,
    valorNocturna: 8000,
    valorMes: 90000,
  },
  {
    tipoVehiculo: 'BICICLETA',
    valorMinuto: 10,
    valorPlena: 2000,
    valorNocturna: 1600,
    valorMes: 40000,
  },
  {
    // El operador digita el valor manualmente al registrar la salida
    // (sección 5.4 de CLAUDE.md): no hay tarifa por minuto/plena/nocturna
    // fija para OTRO, de ahí los ceros. Sigue existiendo una fila porque
    // Ticket.tarifaId es obligatorio incluso para estos vehículos.
    tipoVehiculo: 'OTRO',
    valorMinuto: 0,
    valorPlena: 0,
    valorNocturna: 0,
    valorMes: 180000,
  },
];

const VIGENTE_DESDE = new Date('2026-01-01T00:00:00Z');

const HORARIO_VIGENTE = {
  apertura: new Date(Date.UTC(1970, 0, 1, 8, 0, 0)),
  cierre: new Date(Date.UTC(1970, 0, 1, 21, 30, 0)),
};

// Fechas relativas a "ahora" (no fijas como VIGENTE_DESDE) para que la
// mensualidad vigente siga siendo vigente y la vencida siga vencida sin
// importar cuándo se corra el seed.
function sumarMeses(fecha, meses) {
  const resultado = new Date(fecha);
  resultado.setUTCMonth(resultado.getUTCMonth() + meses);
  return resultado;
}

const MENSUALIDADES_EJEMPLO = [
  {
    // Vigente y pagada: cubre "hoy" y tiene una celda reservada, para probar
    // tanto el cobro $0 por mensualidad como el bloqueo de celda reservada.
    placa: 'MEN001',
    tipo: 'CARRO',
    celdaCodigo: 'A-01',
    mesesInicio: -1,
    mesesFin: 1,
    valorMensualidad: 180000,
    estadoPago: 'PAGADA',
    pagada: true,
  },
  {
    // Vencida y sin pagar: para probar el filtro vigencia=VENCIDA.
    placa: 'MEN002',
    tipo: 'MOTO',
    celdaCodigo: null,
    mesesInicio: -2,
    mesesFin: -1,
    valorMensualidad: 90000,
    estadoPago: 'NO_PAGADA',
    pagada: false,
  },
];

async function seedUsuarios() {
  const admin = await prisma.usuario.upsert({
    where: { email: 'admin@example.com' },
    update: {},
    create: {
      nombre: 'Administrador',
      email: 'admin@example.com',
      passwordHash: bcrypt.hashSync('Admin123!', 10),
      rol: 'ADMIN',
    },
  });

  const operador = await prisma.usuario.upsert({
    where: { email: 'operador@example.com' },
    update: {},
    create: {
      nombre: 'Operador Turno 1',
      email: 'operador@example.com',
      passwordHash: bcrypt.hashSync('Operador123!', 10),
      rol: 'OPERADOR',
    },
  });

  return { admin, operador };
}

async function seedCeldas() {
  for (const zona of ZONAS) {
    let numero = 1;
    for (const grupo of zona.celdas) {
      for (let i = 0; i < grupo.cantidad; i += 1) {
        const codigo = `${zona.prefijo}-${String(numero).padStart(2, '0')}`;
        await prisma.celda.upsert({
          where: { codigo },
          update: {},
          create: {
            codigo,
            zona: zona.nombre,
            tipoPermitido: grupo.tipo,
            estado: 'LIBRE',
          },
        });
        numero += 1;
      }
    }
  }
}

async function seedTarifas() {
  for (const tarifa of TARIFAS_VIGENTES) {
    const existente = await prisma.tarifa.findFirst({
      where: { tipoVehiculo: tarifa.tipoVehiculo, vigenteHasta: null },
    });
    if (existente) continue;

    await prisma.tarifa.create({
      data: { ...tarifa, vigenteDesde: VIGENTE_DESDE },
    });
  }
}

async function seedHorarios() {
  const existente = await prisma.horarioOperacion.findFirst({ where: { vigenteHasta: null } });
  if (existente) return;

  await prisma.horarioOperacion.create({
    data: { ...HORARIO_VIGENTE, vigenteDesde: VIGENTE_DESDE },
  });
}

async function seedMensualidades() {
  const ahora = new Date();

  for (const ejemplo of MENSUALIDADES_EJEMPLO) {
    const vehiculo = await prisma.vehiculo.upsert({
      where: { placa: ejemplo.placa },
      update: {},
      create: { placa: ejemplo.placa, tipo: ejemplo.tipo },
    });

    const existente = await prisma.mensualidad.findFirst({ where: { vehiculoId: vehiculo.id } });
    if (existente) continue;

    const celda = ejemplo.celdaCodigo
      ? await prisma.celda.findUnique({ where: { codigo: ejemplo.celdaCodigo } })
      : null;
    const fechaInicio = sumarMeses(ahora, ejemplo.mesesInicio);
    const fechaFin = sumarMeses(ahora, ejemplo.mesesFin);

    await prisma.mensualidad.create({
      data: {
        vehiculoId: vehiculo.id,
        celdaId: celda?.id,
        fechaInicio,
        fechaFin,
        valorMensualidad: ejemplo.valorMensualidad,
        estadoPago: ejemplo.estadoPago,
        fechaPago: ejemplo.pagada ? fechaInicio : null,
      },
    });
  }
}

async function main() {
  const { admin, operador } = await seedUsuarios();
  await seedCeldas();
  await seedTarifas();
  await seedHorarios();
  await seedMensualidades();

  console.log(`Usuarios: ${admin.email} (ADMIN), ${operador.email} (OPERADOR)`);
  console.log('Celdas: 30 (20 CARRO, 8 MOTO, 2 BICICLETA) en Zona A y Zona B');
  console.log('Tarifas vigentes creadas para CARRO, MOTO, BICICLETA y OTRO');
  console.log('Horario de operación vigente: 08:00 a 21:30');
  console.log('Mensualidades: MEN001 (CARRO, vigente y pagada, celda A-01) y MEN002 (MOTO, vencida)');
}

main()
  .then(() => prisma.$disconnect())
  .catch(async (err) => {
    console.error(err);
    await prisma.$disconnect();
    process.exit(1);
  });
