-- AlterTable
ALTER TABLE "tickets" ADD COLUMN     "entregado_en" TIMESTAMPTZ(3),
ADD COLUMN     "entregado_por_id" UUID;

-- AddForeignKey
ALTER TABLE "tickets" ADD CONSTRAINT "tickets_entregado_por_id_fkey" FOREIGN KEY ("entregado_por_id") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
