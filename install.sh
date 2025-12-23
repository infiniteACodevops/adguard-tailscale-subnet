#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# AdGuard + Tailscale installer (PRODUÇÃO / SUBNET ROUTER)
# ==========================================================
# - Debian / Ubuntu only
# - Wizard do AdGuard GARANTIDO
# - Subnet routing via Tailscale
# - SEM mexer em iptables
# - SEM SSH tunnel
# - docker-compose (clássico)
# ==========================================================

BASE_DIR="/opt/dns-vpn"
DATA_DIR="$BASE_DIR/data"
CONF_DIR="$BASE_DIR/data/confdir"
WORK_DIR="$BASE_DIR/data/workdir"
COMPOSE_FILE="$BASE_DIR/docker-compose.yml"
AGH_YAML="$CONF_DIR/AdGuardHome.yaml"

ADGUARD_IMAGE="${ADGUARD_IMAGE:-ghcr.io/tarcisiomiranda/scaffold:adguardhome-1.0.0}"
TS_HOSTNAME="${TS_HOSTNAME:-adguard-dns-vpn}"

log() { echo -e "\n=== $* ==="; }
ok()  { echo -e "✅ $*"; }
die() { echo -e "❌ $*"; exit 1; }

# ----------------------------------------------------------
# 1️⃣ Validações iniciais
# ----------------------------------------------------------
[[ $EUID -eq 0 ]] || die "Execute como root"

OS_ID="$(. /etc/os-release && echo "$ID")"
OS_VER="$(. /etc/os-release && echo "$VERSION_ID")"
[[ "$OS_ID" =~ ^(debian|ubuntu)$ ]] || die "SO não suportado: $OS_ID"
ok "OS suportado: $OS_ID $OS_VER"

# ----------------------------------------------------------
# 2️⃣ Detectar subnets IPv4 válidas (ignora lo/docker/veth)
# ----------------------------------------------------------
mapfile -t SUBNETS < <(
  ip -br -4 addr show up | awk '
    !/^lo/ && !/^docker/ && !/^br-/ && !/^veth/ && !/^tailscale/ {
      split($3,a,"/");
      split(a[1],b,".");
      printf "%s.%s.%s.0/%s %s\n",b[1],b[2],b[3],a[2],$1
    }'
)

[[ ${#SUBNETS[@]} -gt 0 ]] || die "Nenhuma subnet IPv4 válida encontrada"

if [[ ${#SUBNETS[@]} -eq 1 ]]; then
  LAN_NET="${SUBNETS[0]%% *}"
  LAN_IFACE="${SUBNETS[0]##* }"
  ok "Subnet detectada automaticamente: $LAN_NET ($LAN_IFACE)"
else
  log "Subnets detectadas:"
  select opt in "${SUBNETS[@]}"; do
    LAN_NET="${opt%% *}"
    LAN_IFACE="${opt##* }"
    break
  done
fi

LAN_IP="$(ip -o -4 addr show dev "$LAN_IFACE" | awk '{print $4}' | cut -d/ -f1)"

ok "Interface LAN : $LAN_IFACE"
ok "IP LAN        : $LAN_IP"
ok "Subnet LAN    : $LAN_NET"

# ----------------------------------------------------------
# 3️⃣ Docker + Docker Compose (plugin OU clássico)
# ----------------------------------------------------------
log "Instalando Docker (se necessário)"

if ! command -v docker >/dev/null; then
  apt update
  apt install -y docker.io
fi

systemctl enable docker --now
ok "Docker pronto"

# Detectar docker compose (plugin) ou docker-compose (clássico)
if docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD="docker compose"
  ok "Compose command: docker compose (plugin)"
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD="docker-compose"
  ok "Compose command: docker-compose (clássico)"
else
  log "Instalando docker-compose clássico"
  apt update
  apt install -y docker-compose
  COMPOSE_CMD="docker-compose"
  ok "Compose command: docker-compose (instalado)"
fi

# ----------------------------------------------------------
# 4️⃣ Tailscale
# ----------------------------------------------------------
log "Instalando Tailscale (se necessário)"
if ! command -v tailscale >/dev/null; then
  curl -fsSL https://tailscale.com/install.sh | sh
fi
systemctl enable tailscaled --now
ok "Tailscale pronto"

# ----------------------------------------------------------
# 5️⃣ IP Forward
# ----------------------------------------------------------
log "Habilitando IP forwarding"
cat <<EOF >/etc/sysctl.d/99-tailscale-forwarding.conf
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1
EOF
sysctl --system >/dev/null
ok "IP forwarding ativo"

# ----------------------------------------------------------
# 6️⃣ Estrutura
# ----------------------------------------------------------
mkdir -p "$CONF_DIR" "$WORK_DIR"
ok "Diretórios garantidos"

# ----------------------------------------------------------
# 7️⃣ docker-compose.yml (MODO WIZARD)
# ----------------------------------------------------------
log "Gerando docker-compose.yml"
cat >"$COMPOSE_FILE" <<EOF
services:
  adguardhome:
    image: ${ADGUARD_IMAGE}
    container_name: adguardhome
    restart: unless-stopped
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "3000:3000"
    volumes:
      - ./data/workdir:/opt/adguardhome/work
      - ./data/confdir:/opt/adguardhome/conf
    environment:
      - AGH_CONFIG=/opt/adguardhome/conf/AdGuardHome.yaml
EOF
ok "docker-compose.yml escrito"

# ----------------------------------------------------------
# 8️⃣ AdGuardHome.yaml mínimo
# ----------------------------------------------------------
log "Gerando AdGuardHome.yaml"
cat >"$AGH_YAML" <<'EOF'
dns:
  upstream_dns:
    - https://dns10.quad9.net/dns-query
    - https://1.1.1.1/dns-query
EOF
ok "AdGuardHome.yaml escrito"

# ----------------------------------------------------------
# 9️⃣ Subir AdGuard (primeira vez)
# ----------------------------------------------------------
log "Subindo AdGuard (primeira vez)"
cd "$BASE_DIR"
$COMPOSE_CMD up -d
ok "AdGuard iniciado"

# ----------------------------------------------------------
# 🔟 Tailscale subnet routing
# ----------------------------------------------------------
log "Configurando Tailscale (subnet router)"
tailscale up \
  --hostname="$TS_HOSTNAME" \
  --advertise-routes="$LAN_NET" \
  --accept-dns=false
ok "tailscale up concluído"

# ----------------------------------------------------------
# 🔥 11️⃣ RESET FINAL — WIZARD GARANTIDO (BYTE A BYTE)
# ----------------------------------------------------------
log "Reset final do AdGuard (wizard garantido)"

cd "$BASE_DIR"
$COMPOSE_CMD down
rm -rf "$DATA_DIR"/*
$COMPOSE_CMD up -d

ok "Reset concluído — wizard garantido"

# ----------------------------------------------------------
# ✅ FINAL
# ----------------------------------------------------------
cat <<EOF

============================================================
INSTALAÇÃO CONCLUÍDA — WIZARD GARANTIDO
============================================================

🌐 Abra o wizard do AdGuard:
   http://$LAN_IP:3000

📁 docker-compose.yml:
   $COMPOSE_FILE

============================================================
APÓS FINALIZAR O WIZARD
============================================================

1) Edite o compose:
   $COMPOSE_FILE

2) Troque:
   - "3000:3000"
   por:
   - "3000:80"

3) Aplique:
   docker compose up -d
   ou
   docker-compose up -d

Painel final:
   http://$LAN_IP:3000/login.html

============================================================
REGRAS DE OURO
============================================================
- NÃO mexa em iptables
- NÃO use SSH tunnel
- Subnet routing deve ser aprovado no Admin do Tailscale:
  $LAN_NET
============================================================
EOF
