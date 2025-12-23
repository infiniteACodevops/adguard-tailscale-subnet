---

# 🛡️ AdGuard Home + Tailscale Subnet Router
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)
![AdGuard Home](https://img.shields.io/badge/AdGuard-Home-68BC71)
![Tailscale](https://img.shields.io/badge/Tailscale-WireGuard-000000?logo=tailscale)

![Security](https://img.shields.io/badge/Security-Zero%20Exposure-success)
![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen)

Este projeto entrega uma instalação **limpa, previsível e segura** de **AdGuard Home** com **Tailscale Subnet Routing**, configurada especificamente para ambientes de produção estáveis.

> ⚠️ **Aviso de operação segura:** Este projeto assume que o host **não possui portas expostas diretamente na internet (WAN)**.  
> O roteamento da sub-rede funciona com segurança apenas em ambientes protegidos por NAT, sem portas abertas para a internet pública.


---

## 🎯 Objetivos do Projeto

| Meta | Status |
| --- | --- |
| AdGuard operando na **LAN** | ✅ |
| Acesso externo seguro via **4G / 5G** (Tailscale) | ✅ |
| **Subnet Routing** configurado sem conflitos | ✅ |
| DNS-over-HTTPS (**DoH**) nativo | ✅ |
| Instalação **Zero Gambiarra** (Sem SSH Tunnel) | ✅ |

---

## 🧠 Princípios Inegociáveis

❌ **NUNCA execute comandos de limpeza de iptables:**

```bash
sudo iptables -F
sudo iptables -t nat -F

```

> **Atenção:** Executar esses comandos apaga as regras dinâmicas do Tailscale, quebrando o roteamento da sub-rede imediatamente.

---

## 📋 Pré-requisitos

| Item | Requisito Mínimo |
| --- | --- |
| **Sistema** | Debian 11+ ou Ubuntu 20.04+ |
| **Privilégios** | Acesso Root ou Sudo |
| **Infra** | Interface LAN com IPv4 |
| **VPN** | Conta ativa no [Tailscale](https://tailscale.com) |
| **Pacotes** | git (para clone), curl, ca-certificates |

 ### Instalar dependências básicas (se necessário)

```bash
apt update && apt install -y git curl ca-certificates
```

### ⚠️ Pré-requisito adicional — Cloud Images (Debian / Ubuntu / Proxmox)

Em **cloud images** (Debian ou Ubuntu), o serviço **systemd-resolved** vem **ativo por padrão** e ocupa a **porta 53 (DNS)**.

Como este projeto implementa **um servidor DNS próprio (AdGuard Home)**, é **obrigatório** desativar o DNS do sistema **antes de executar o script**, caso contrário o container não conseguirá iniciar.


#### Quando este passo é necessário

- ✅ Debian cloud-image  
- ✅ Ubuntu cloud-image  
- ✅ VMs no Proxmox usando cloud-image  

#### Quando pode não ser necessário

- ℹ️ Instalação via ISO tradicional  
- ℹ️ Hosts que não utilizam `systemd-resolved` como DNS local  

#### Execute **uma única vez**, antes da instalação:

```bash

systemctl stop systemd-resolved
systemctl disable systemd-resolved
systemctl mask systemd-resolved

```

> ⚠️ **Observação:** Este passo altera o comportamento de resolução DNS do sistema.  
> Ele é um **pré-requisito do ambiente**, não uma automação do script.
> ❗ O script **não desativa automaticamente** o systemd-resolved por segurança.

> ⚠️ **Modelo de ameaça considerado:** O host deve estar **atrás de NAT**, sem portas WAN expostas diretamente.  
> Este projeto **não é seguro** se a máquina tiver portas DNS/HTTP abertas para a internet pública.


---

## 🚀 Quick start (recomendado)

```bash

git clone https://github.com/infiniteACodevops/adguard-tailscale-subnet.git && cd adguard-tailscale-subnet && chmod +x install.sh && sudo ./install.sh

```

## 📥 Instalação Passo a Passo

1️⃣ **Clonar o Repositório**

```bash
git clone https://github.com/SEU_USUARIO/adguard-tailscale-subnet.git
cd adguard-tailscale-subnet

```

2️⃣ **Permissões e Execução**

```bash
chmod +x install.sh
sudo ./install.sh

```

**Automações incluídas:**

* Cálculo automático de Subnet via interface LAN.
* Ativação de **IP Forwarding** no Kernel.
* Deploy do stack Docker (AdGuard Home).
* Registro do host como **Subnet Router** na Tailnet.

---

## 🌐 Configuração Inicial (Wizard)

Após o script terminar, acesse o painel de configuração:
👉 `http://IP_DA_MAQUINA:3000`

Finalize o assistente do AdGuard criando seu usuário e senha.

---

## 🔁 Ajuste Pós-Wizard (Crítico)

Após o Wizard, o AdGuard migra para a porta 80 internamente. Ajuste o Docker para manter o acesso na porta 3000:

1️⃣ **Edite o arquivo:**

```bash
nano /opt/dns-vpn/docker-compose.yml

```

2️⃣ **Ajuste a seção de portas:**
Troque `- "3000:3000"` por `- "3000:80"`.

3️⃣ **Reinicie o container:**

```bash
cd /opt/dns-vpn && (docker compose up -d || docker-compose up -d) 

```

---

## ✅ Validação do Ambiente

### 🔐 No Painel do Tailscale

Acesse o [Admin Console](https://login.tailscale.com/admin/machines), localize o servidor e em **Edit route settings**, aprove a rota da sua rede local (ex: `192.168.x.0/24`).

### 🧪 Testes de Conectividade

* **Local:** `dig @localhost google.com +short`
* **Remoto (4G):** Ative o Tailscale no celular e acesse o IP da LAN pelo navegador.

---

## 📁 Estrutura do Sistema

```text
/opt/dns-vpn
├── docker-compose.yml
└── data
    ├── confdir/   # Configurações AdGuardHome.yaml
    └── workdir/   # Filtros e Logs

```

---

## 🧩 Notas de Produção

* **Separação de Poderes:** O Tailscale gerencia o roteamento, o Docker a infraestrutura e o AdGuard a resolução DNS.
* **Segurança:** Consulte o arquivo [`SECURITY.md`](SECURITY.md) para detalhes sobre a proteção da sua malha de rede.

---
