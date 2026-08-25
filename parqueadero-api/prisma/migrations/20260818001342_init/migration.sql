-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateEnum
CREATE TYPE "Rol" AS ENUM ('ADMIN', 'OPERADOR');

-- CreateEnum
CREATE TYPE "TipoVehiculo" AS ENUM ('CARRO', 'MOTO', 'BICICLETA', 'OTRO');

-- CreateEnum
CREATE TYPE "EstadoCelda" AS ENUM ('LIBRE', 'OCUPADA', 'MANTENIMIENTO');

-- CreateEnum
CREATE TYPE "EstadoTicket" AS ENUM ('ABIERTO', 'PAGADO', 'ENTREGADO', 'ANULADO');

-- CreateEnum
CREATE TYPE "EstadoMensualidad" AS ENUM ('ACTIVA', 'VENCIDA', 'CANCELADA');

-- CreateEnum
CREATE TYPE "EstadoTurno" AS ENUM ('ABIERTO', 'CERRADO');

-- CreateEnum
CREATE TYPE "EstadoPago" AS ENUM ('VALIDO', 'ANULADO');

-- CreateEnum
CREATE TYPE "MetodoPago" AS ENUM ('EFECTIVO', 'TARJETA', 'TRANSFERENCIA');

-- CreateTable
CREATE TABLE "usuarios" (
    "id" UUID NOT NULL,
    "nombre" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "password_hash" TEXT NOT NULL,
    "rol" "Rol" NOT NULL,
    "activo" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "usuarios_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "vehiculos" (
    "id" UUID NOT NULL,
    "placa" TEXT NOT NULL,
    "tipo" "TipoVehiculo" NOT NULL,
    "propietario_nombre" TEXT,
    "propietario_telefono" TEXT,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "vehiculos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "celdas" (
    "id" UUID NOT NULL,
    "codigo" TEXT NOT NULL,
    "zona" TEXT NOT NULL,
    "tipo_permitido" "TipoVehiculo" NOT NULL,
    "estado" "EstadoCelda" NOT NULL DEFAULT 'LIBRE',
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "celdas_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tarifas" (
    "id" UUID NOT NULL,
    "tipo_vehiculo" "TipoVehiculo" NOT NULL,
    "valor_fraccion" INTEGER NOT NULL,
    "minutos_fraccion" INTEGER NOT NULL,
    "valor_dia" INTEGER NOT NULL,
    "valor_mes" INTEGER NOT NULL,
    "vigente_desde" TIMESTAMPTZ(3) NOT NULL,
    "vigente_hasta" TIMESTAMPTZ(3),
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "tarifas_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tickets" (
    "id" UUID NOT NULL,
    "codigo" TEXT NOT NULL,
    "vehiculo_id" UUID NOT NULL,
    "celda_id" UUID NOT NULL,
    "hora_entrada" TIMESTAMPTZ(3) NOT NULL,
    "hora_salida" TIMESTAMPTZ(3),
    "tarifa_id" UUID NOT NULL,
    "valor_total" INTEGER,
    "estado" "EstadoTicket" NOT NULL DEFAULT 'ABIERTO',
    "operador_entrada_id" UUID NOT NULL,
    "operador_salida_id" UUID,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "tickets_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "mensualidades" (
    "id" UUID NOT NULL,
    "vehiculo_id" UUID NOT NULL,
    "celda_id" UUID,
    "fecha_inicio" TIMESTAMPTZ(3) NOT NULL,
    "fecha_fin" TIMESTAMPTZ(3) NOT NULL,
    "valor_pagado" INTEGER NOT NULL,
    "estado" "EstadoMensualidad" NOT NULL DEFAULT 'ACTIVA',
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "mensualidades_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "turnos" (
    "id" UUID NOT NULL,
    "operador_id" UUID NOT NULL,
    "apertura" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "cierre" TIMESTAMPTZ(3),
    "base_inicial" INTEGER NOT NULL,
    "total_recaudado" INTEGER,
    "estado" "EstadoTurno" NOT NULL DEFAULT 'ABIERTO',
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "turnos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "pagos" (
    "id" UUID NOT NULL,
    "ticket_id" UUID,
    "mensualidad_id" UUID,
    "monto" INTEGER NOT NULL,
    "metodo" "MetodoPago" NOT NULL,
    "turno_id" UUID NOT NULL,
    "fecha" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "estado" "EstadoPago" NOT NULL DEFAULT 'VALIDO',
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "pagos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "anulaciones" (
    "id" UUID NOT NULL,
    "ticket_id" UUID,
    "pago_id" UUID,
    "motivo" TEXT NOT NULL,
    "usuario_id" UUID NOT NULL,
    "fecha" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "anulaciones_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "usuarios_email_key" ON "usuarios"("email");

-- CreateIndex
CREATE UNIQUE INDEX "vehiculos_placa_key" ON "vehiculos"("placa");

-- CreateIndex
CREATE UNIQUE INDEX "celdas_codigo_key" ON "celdas"("codigo");

-- CreateIndex
CREATE INDEX "celdas_tipo_permitido_estado_idx" ON "celdas"("tipo_permitido", "estado");

-- CreateIndex
CREATE INDEX "celdas_estado_idx" ON "celdas"("estado");

-- CreateIndex
CREATE INDEX "tarifas_tipo_vehiculo_vigente_desde_idx" ON "tarifas"("tipo_vehiculo", "vigente_desde");

-- CreateIndex
CREATE UNIQUE INDEX "tickets_codigo_key" ON "tickets"("codigo");

-- CreateIndex
CREATE INDEX "tickets_vehiculo_id_estado_idx" ON "tickets"("vehiculo_id", "estado");

-- CreateIndex
CREATE INDEX "tickets_estado_idx" ON "tickets"("estado");

-- CreateIndex
CREATE INDEX "tickets_celda_id_idx" ON "tickets"("celda_id");

-- CreatePartialIndex (agregado a mano: Prisma no soporta índices únicos
-- parciales en schema.prisma; esto impone "una placa no puede tener dos
-- tickets ABIERTO simultáneos" a nivel de BD, no solo en TicketService)
CREATE UNIQUE INDEX "tickets_vehiculo_id_abierto_key" ON "tickets"("vehiculo_id") WHERE "estado" = 'ABIERTO';

-- CreateIndex
CREATE INDEX "mensualidades_vehiculo_id_estado_fecha_inicio_fecha_fin_idx" ON "mensualidades"("vehiculo_id", "estado", "fecha_inicio", "fecha_fin");

-- CreateIndex
CREATE INDEX "turnos_operador_id_estado_idx" ON "turnos"("operador_id", "estado");

-- CreateIndex
CREATE UNIQUE INDEX "pagos_ticket_id_key" ON "pagos"("ticket_id");

-- CreateIndex
CREATE INDEX "pagos_mensualidad_id_idx" ON "pagos"("mensualidad_id");

-- CreateIndex
CREATE INDEX "pagos_turno_id_idx" ON "pagos"("turno_id");

-- CreateIndex
CREATE UNIQUE INDEX "anulaciones_ticket_id_key" ON "anulaciones"("ticket_id");

-- CreateIndex
CREATE UNIQUE INDEX "anulaciones_pago_id_key" ON "anulaciones"("pago_id");

-- AddForeignKey
ALTER TABLE "tickets" ADD CONSTRAINT "tickets_vehiculo_id_fkey" FOREIGN KEY ("vehiculo_id") REFERENCES "vehiculos"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tickets" ADD CONSTRAINT "tickets_celda_id_fkey" FOREIGN KEY ("celda_id") REFERENCES "celdas"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tickets" ADD CONSTRAINT "tickets_tarifa_id_fkey" FOREIGN KEY ("tarifa_id") REFERENCES "tarifas"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tickets" ADD CONSTRAINT "tickets_operador_entrada_id_fkey" FOREIGN KEY ("operador_entrada_id") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tickets" ADD CONSTRAINT "tickets_operador_salida_id_fkey" FOREIGN KEY ("operador_salida_id") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mensualidades" ADD CONSTRAINT "mensualidades_vehiculo_id_fkey" FOREIGN KEY ("vehiculo_id") REFERENCES "vehiculos"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mensualidades" ADD CONSTRAINT "mensualidades_celda_id_fkey" FOREIGN KEY ("celda_id") REFERENCES "celdas"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "turnos" ADD CONSTRAINT "turnos_operador_id_fkey" FOREIGN KEY ("operador_id") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "pagos" ADD CONSTRAINT "pagos_ticket_id_fkey" FOREIGN KEY ("ticket_id") REFERENCES "tickets"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "pagos" ADD CONSTRAINT "pagos_mensualidad_id_fkey" FOREIGN KEY ("mensualidad_id") REFERENCES "mensualidades"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "pagos" ADD CONSTRAINT "pagos_turno_id_fkey" FOREIGN KEY ("turno_id") REFERENCES "turnos"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddCheckConstraint (agregado a mano: Prisma no soporta CHECK arbitrarios en
-- schema.prisma; obliga a que un Pago pertenezca a un Ticket O a una
-- Mensualidad, nunca a ambos ni a ninguno)
ALTER TABLE "pagos" ADD CONSTRAINT "pagos_ticket_xor_mensualidad_check" CHECK (num_nonnulls("ticket_id", "mensualidad_id") = 1);

-- AddForeignKey
ALTER TABLE "anulaciones" ADD CONSTRAINT "anulaciones_ticket_id_fkey" FOREIGN KEY ("ticket_id") REFERENCES "tickets"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "anulaciones" ADD CONSTRAINT "anulaciones_pago_id_fkey" FOREIGN KEY ("pago_id") REFERENCES "pagos"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "anulaciones" ADD CONSTRAINT "anulaciones_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddCheckConstraint (agregado a mano, mismo patrón que pagos: una Anulacion
-- es de un Ticket O de un Pago, nunca de ambos ni de ninguno)
ALTER TABLE "anulaciones" ADD CONSTRAINT "anulaciones_ticket_xor_pago_check" CHECK (num_nonnulls("ticket_id", "pago_id") = 1);
