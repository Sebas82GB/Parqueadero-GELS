-- AlterEnum
ALTER TYPE "EstadoTurno" ADD VALUE 'CERRADO_PENDIENTE_ARQUEO';

-- AlterTable
ALTER TABLE "turnos" ADD COLUMN     "validado_en" TIMESTAMPTZ(3),
ADD COLUMN     "validado_por_id" UUID;

-- AlterTable
ALTER TABLE "usuarios" ADD COLUMN     "base_inicial_turno" INTEGER;

-- AddForeignKey
ALTER TABLE "turnos" ADD CONSTRAINT "turnos_validado_por_id_fkey" FOREIGN KEY ("validado_por_id") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
