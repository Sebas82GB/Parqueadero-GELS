/*
  Warnings:

  - You are about to drop the column `ticket_id` on the `anulaciones` table. All the data in the column will be lost.
  - You are about to drop the column `estado` on the `mensualidades` table. All the data in the column will be lost.
  - You are about to drop the column `valor_pagado` on the `mensualidades` table. All the data in the column will be lost.
  - You are about to drop the column `minutos_fraccion` on the `tarifas` table. All the data in the column will be lost.
  - You are about to drop the column `valor_dia` on the `tarifas` table. All the data in the column will be lost.
  - You are about to drop the column `valor_fraccion` on the `tarifas` table. All the data in the column will be lost.
  - Made the column `pago_id` on table `anulaciones` required. This step will fail if there are existing NULL values in that column.
  - Added the required column `valor_mensualidad` to the `mensualidades` table without a default value. This is not possible if the table is not empty.
  - Added the required column `valor_minuto` to the `tarifas` table without a default value. This is not possible if the table is not empty.
  - Added the required column `valor_nocturna` to the `tarifas` table without a default value. This is not possible if the table is not empty.
  - Added the required column `valor_plena` to the `tarifas` table without a default value. This is not possible if the table is not empty.

*/
-- CreateEnum
CREATE TYPE "EstadoPagoMensualidad" AS ENUM ('PAGADA', 'NO_PAGADA', 'CANCELADA');

-- DropCheckConstraint (agregado a mano: la XOR ticket/pago de anulaciones ya
-- no aplica. Anulacion pasa a ser exclusiva de Pago; la anulación de un
-- Ticket ahora vive en tickets.motivo_anulacion/anulado_por_id/anulado_en)
ALTER TABLE "anulaciones" DROP CONSTRAINT "anulaciones_ticket_xor_pago_check";

-- DropForeignKey
ALTER TABLE "anulaciones" DROP CONSTRAINT "anulaciones_ticket_id_fkey";

-- DropIndex
DROP INDEX "anulaciones_ticket_id_key";

-- DropIndex
DROP INDEX "mensualidades_vehiculo_id_estado_fecha_inicio_fecha_fin_idx";

-- AlterTable
ALTER TABLE "anulaciones" DROP COLUMN "ticket_id",
ALTER COLUMN "pago_id" SET NOT NULL;

-- AlterTable
ALTER TABLE "mensualidades" DROP COLUMN "estado",
DROP COLUMN "valor_pagado",
ADD COLUMN     "estado_pago" "EstadoPagoMensualidad" NOT NULL DEFAULT 'NO_PAGADA',
ADD COLUMN     "fecha_pago" TIMESTAMPTZ(3),
ADD COLUMN     "valor_mensualidad" INTEGER NOT NULL;

-- AlterTable
ALTER TABLE "tarifas" DROP COLUMN "minutos_fraccion",
DROP COLUMN "valor_dia",
DROP COLUMN "valor_fraccion",
ADD COLUMN     "valor_minuto" INTEGER NOT NULL,
ADD COLUMN     "valor_nocturna" INTEGER NOT NULL,
ADD COLUMN     "valor_plena" INTEGER NOT NULL;

-- AlterTable
ALTER TABLE "tickets" ADD COLUMN     "anulado_en" TIMESTAMPTZ(3),
ADD COLUMN     "anulado_por_id" UUID,
ADD COLUMN     "desglose" JSONB,
ADD COLUMN     "motivo_anulacion" TEXT;

-- DropEnum
DROP TYPE "EstadoMensualidad";

-- CreateIndex
CREATE INDEX "mensualidades_vehiculo_id_estado_pago_fecha_inicio_fecha_fi_idx" ON "mensualidades"("vehiculo_id", "estado_pago", "fecha_inicio", "fecha_fin");

-- AddForeignKey
ALTER TABLE "tickets" ADD CONSTRAINT "tickets_anulado_por_id_fkey" FOREIGN KEY ("anulado_por_id") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
