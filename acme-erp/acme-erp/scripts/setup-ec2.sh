#!/bin/bash
# ─────────────────────────────────────────────
# ACME ERP — Setup EC2 Ubuntu 22.04
# Ejecutar como: bash setup-ec2.sh
# ─────────────────────────────────────────────

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 ACME ERP — Configuración EC2"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. Actualizar sistema
echo "⏳ Actualizando sistema..."
sudo apt update -y && sudo apt upgrade -y

# 2. Instalar Docker
echo "⏳ Instalando Docker..."
sudo apt install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update -y
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER

# 3. Instalar AWS CLI
echo "⏳ Instalando AWS CLI..."
sudo apt install -y awscli

# 4. Instalar PostgreSQL client (para backups)
echo "⏳ Instalando cliente PostgreSQL..."
sudo apt install -y postgresql-client

# 5. Instalar Git
echo "⏳ Instalando Git..."
sudo apt install -y git

# 6. Instalar Fail2ban
echo "⏳ Instalando Fail2ban..."
sudo apt install -y fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Configurar Fail2ban para SSH
sudo tee /etc/fail2ban/jail.local > /dev/null <<EOF
[DEFAULT]
bantime  = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port    = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s
EOF

sudo systemctl restart fail2ban

# 7. Clonar repositorio
echo "⏳ Clonando repositorio..."
sudo mkdir -p /srv/acme-erp
sudo chown ubuntu:ubuntu /srv/acme-erp
# REEMPLAZA con tu repo real:
# git clone https://github.com/TU_USUARIO/acme-erp.git /srv/acme-erp

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Setup completado. Reinicia sesión SSH"
echo "   para aplicar permisos de Docker."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
