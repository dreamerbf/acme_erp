#!/bin/bash
# ─────────────────────────────────────────────
# ACME ERP — Script de Backup RDS → S3
# CI3051 Ciberseguridad en la Nube
# Frecuencia: 1 backup diario (cron cada 24h)
# ─────────────────────────────────────────────

# Cargar variables de entorno
set -a
source /srv/acme-erp/.env
set +a

FECHA=$(date +%Y%m%d_%H%M%S)
ARCHIVO="backup_acmedb_${FECHA}.sql"
RUTA_LOCAL="/tmp/${ARCHIVO}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🗄️  ACME ERP — Backup RDS PostgreSQL"
echo "📅 Fecha: $(date '+%d/%m/%Y %H:%M:%S')"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. Generar dump de la BD
echo "⏳ Generando dump de ${DB_NAME}..."
PGPASSWORD="${DB_PASSWORD}" pg_dump \
  -h "${DB_HOST}" \
  -p "${DB_PORT}" \
  -U "${DB_USER}" \
  -d "${DB_NAME}" \
  -F p \
  > "${RUTA_LOCAL}"

if [ $? -ne 0 ]; then
  echo "❌ Error al generar el dump. Abortando."
  exit 1
fi

echo "✅ Dump generado: ${RUTA_LOCAL} ($(du -sh ${RUTA_LOCAL} | cut -f1))"

# 2. Subir a S3
echo "⏳ Subiendo a S3: s3://${AWS_BUCKET}/backups/${ARCHIVO}..."
aws s3 cp "${RUTA_LOCAL}" "s3://${AWS_BUCKET}/backups/${ARCHIVO}" \
  --region "${AWS_REGION}"

if [ $? -ne 0 ]; then
  echo "❌ Error al subir a S3."
  exit 1
fi

echo "✅ Backup subido exitosamente a S3"

# 3. Verificar en S3
echo "📋 Verificando en S3..."
aws s3 ls "s3://${AWS_BUCKET}/backups/" --region "${AWS_REGION}"

# 4. Limpiar archivo local
rm -f "${RUTA_LOCAL}"
echo "🧹 Archivo temporal eliminado"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Backup completado exitosamente"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
