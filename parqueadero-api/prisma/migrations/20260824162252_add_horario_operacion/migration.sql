-- CreateTable
CREATE TABLE "horarios_operacion" (
    "id" UUID NOT NULL,
    "apertura" TIME NOT NULL,
    "cierre" TIME NOT NULL,
    "vigente_desde" TIMESTAMPTZ(3) NOT NULL,
    "vigente_hasta" TIMESTAMPTZ(3),
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "horarios_operacion_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "horarios_operacion_vigente_desde_idx" ON "horarios_operacion"("vigente_desde");

-- Horario por defecto para que la migración pueda cerrar en NOT NULL incluso
-- si "tickets" ya tiene filas. vigente_desde queda en el pasado a propósito
-- para cubrir cualquier ticket histórico; el seed (prisma/seed.js) usa los
-- mismos valores 08:00/21:30 y no duplica esta fila porque busca por
-- vigente_hasta IS NULL antes de crear.
INSERT INTO "horarios_operacion" ("id", "apertura", "cierre", "vigente_desde", "vigente_hasta", "created_at", "updated_at")
VALUES (gen_random_uuid(), '08:00:00', '21:30:00', '2020-01-01T00:00:00Z', NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- AlterTable (nullable primero para poder rellenar los tickets existentes)
ALTER TABLE "tickets" ADD COLUMN "horario_id" UUID;

-- Backfill: todo ticket existente queda apuntando al horario por defecto
-- recién insertado.
UPDATE "tickets" SET "horario_id" = (SELECT "id" FROM "horarios_operacion" LIMIT 1) WHERE "horario_id" IS NULL;

-- AlterTable
ALTER TABLE "tickets" ALTER COLUMN "horario_id" SET NOT NULL;

-- AddForeignKey
ALTER TABLE "tickets" ADD CONSTRAINT "tickets_horario_id_fkey" FOREIGN KEY ("horario_id") REFERENCES "horarios_operacion"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
