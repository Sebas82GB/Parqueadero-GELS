-- CreateSequence (agregado a mano: Prisma no tiene "secuencia" como
-- concepto de schema. El consecutivo de recibo se asigna con
-- nextval('recibo_consecutivo_seq') dentro de la transacción de
-- registrarSalidaTransaccional; al ser una secuencia real de Postgres,
-- nextval() es atómica e independiente del rollback de la transacción que
-- la invoca, así que dos salidas concurrentes nunca reciben el mismo valor)
CREATE SEQUENCE "recibo_consecutivo_seq";

-- AlterTable
ALTER TABLE "tickets" ADD COLUMN     "recibo_consecutivo" INTEGER;

-- CreateIndex
CREATE UNIQUE INDEX "tickets_recibo_consecutivo_key" ON "tickets"("recibo_consecutivo");

-- AttachSequence (agregado a mano: liga el ciclo de vida de la secuencia a
-- la columna, para que se elimine sola si la columna se llega a eliminar)
ALTER SEQUENCE "recibo_consecutivo_seq" OWNED BY "tickets"."recibo_consecutivo";
