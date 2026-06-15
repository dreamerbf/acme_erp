# ACME ERP — CI3051 Ciberseguridad en la Nube

Infraestructura segura On-Cloud para ACME Limitada (OIV).

## Arquitectura

```
Internet → EC2 (Frontend Node.js) → AWS RDS PostgreSQL
                                  → AWS S3 (Backups)
```

## Requisitos previos

- Docker y Docker Compose instalados
- AWS CLI configurado (`aws configure`)
- Acceso a AWS RDS y S3

## Configuración

1. Clonar el repositorio:
```bash
git clone https://github.com/TU_USUARIO/acme-erp.git /srv/acme-erp
cd /srv/acme-erp
```

2. Configurar variables de entorno:
```bash
cp .env.example .env
# Editar .env con tus datos reales
```

3. Construir y levantar servicios:
```bash
docker compose build
docker compose up -d
```

4. Verificar que corre:
```bash
docker compose ps
docker compose logs frontend
```

5. Acceder al portal:
```
http://localhost:3000
Usuario: admin
Contraseña: Admin1234!
```

## Comandos útiles

```bash
# Ver logs en tiempo real
docker compose logs -f frontend

# Detener servicios
docker compose down

# Ejecutar backup manual
bash scripts/backup.sh

# Ver backups en S3
aws s3 ls s3://acme-erp-backups-2026--use1-az4--x-s3/backups/
```

## Configurar backup automático (cron)

```bash
crontab -e
# Añadir esta línea (backup diario a las 02:00):
0 2 * * * bash /srv/acme-erp/scripts/backup.sh >> /var/log/acme-backup.log 2>&1
```

## Seguridad implementada

- Autenticación con JWT (expiración 2h)
- Acceso condicional a rutas protegidas
- Security Groups EC2 y RDS con mínima exposición
- Fail2ban para protección SSH
- SSL en conexión RDS
- Backups automáticos cifrados en S3

## Leyes aplicadas

- Ley 21.663 — Marco de Ciberseguridad
- Ley 21.719 — Protección de Datos Personales
- Ley 21.449 — Infraestructura Crítica
- Ley 21.628 — OIV
- ISO 27001 — SGSI
