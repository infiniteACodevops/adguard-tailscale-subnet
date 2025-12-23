# 🛡️ Manifesto de Segurança: Subnet Router vs. Exposição

Este documento apresenta provas técnicas e objetivas de que a utilização do **Tailscale Subnet Router** é uma prática segura e não expõe a rede local à internet pública.

---

## 🏛️ PROVA A — “LAN divulgada” ≠ “LAN exposta”

### ❌ O que NÃO acontece (Mitos)

Ao anunciar sua sub-rede, o sistema **não** se torna vulnerável.

* **Sem abertura de portas:** Não é necessário mexer no NAT/Modem.
* **Invisível ao Shodan:** Seus IPs internos (`192.168.x.x`) não aparecem em buscas de hackers.
* **Sem IP Público:** A LAN não ganha um endereço acessível pela internet comum.

### ✅ O que acontece de verdade (Fato Técnico)

O Tailscale cria um túnel cifrado onde a rota para a rede local
só é instalada após autenticação e descriptografia.

**📌 Prova Objetiva:**

* **Cenário 1 (Sem VPN):** `ping 192.168.50.51` → **Falha.**
* **Cenário 2 (VPN Autenticada):** `ping 192.168.50.51` → **Sucesso.**

> **Conclusão:** O controle de acesso mudou da "Rede" para a "Identidade".

---

## 🔒 PROVA B — As 5 Camadas de Proteção (Regras Duras)

Para que qualquer dispositivo alcance sua LAN, ele deve satisfazer **simultaneamente** estas condições:

1. **Autenticação SSO:** Login válido via Google/Microsoft com **2FA**.
2. **Criptografia WireGuard:** Tráfego cifrado ponta-a-ponta com chaves rotativas.
3. **Autorização de Nó:** O dispositivo precisa ser aprovado manualmente no seu Painel.
4. **Filtro de ACL:** O tráfego deve ser permitido pelas suas regras de controle de acesso.
5. **Estado Conectado:** Se a VPN estiver desligada, a rota para a LAN desaparece do dispositivo.

---

## 📊 PROVA C — Comparação com Alternativas

| Método | Exposição Real | Segurança no Mobile (iOS/Android) |
| --- | --- | --- |
| **Subnet Router** | 🔒 **Zero Exposição** | ✅ Excelente (Nativo/Baixo consumo) |
| **Port-forward** | 🔥 Internet Inteira | ✅ Simples, mas perigoso |
| **Proxy Público** | 🔥 Internet Inteira | ✅ Requer certificados/SSL |
| **SSH SOCKS** | 🔒 Seguro | ❌ Instável (Cai em segundo plano) |

---

## 🕵️ PROVA D — Ataque via Painel? (Inexistente)

> *"Um hacker consegue escanear minha LAN porque ela aparece no painel do Tailscale?"*

**Resposta Técnica: NÃO.**
O painel do Tailscale armazena apenas **metadados** (configurações). O roteamento acontece entre as suas máquinas. É como o Google Drive: você vê o nome do arquivo no seu painel, mas ele é invisível e inacessível para o resto da internet.

---

## ✅ PROVA E — O seu Perímetro de Defesa

No seu cenário específico, a segurança é reforçada por:

* **Identidade:** Google Account com **MFA/2FA** ativo.
* **Privacidade:** Apenas **um usuário** administrador na Tailnet.
* **Isolamento:** Nenhum nó de saída (Exit Node) público ou convidados (Guests).

---

## ⚖️ VEREDITO FINAL

**O Subnet Router NÃO é perigoso.**

Ele é uma ferramenta de rede profissional que garante acesso:

* 🔐 **Criptografado** por WireGuard.
* 🔐 **Autenticado** por Identidade.
* 🔐 **Invisível** fora da sua malha privada (Tailnet).

📌 *O receio de exposição é comum, mas tecnicamente não se aplica ao funcionamento do Tailscale.*

---

### 📌 Escopo de Segurança Considerado

Este veredito assume:

- Host atrás de NAT (sem IP público direto)
- Nenhuma porta WAN exposta manualmente
- Tailnet privada (sem usuários convidados ou nós públicos)

Fora dessas condições, o modelo de ameaça deve ser reavaliado.

---
