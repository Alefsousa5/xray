# SSHPLUS MANAGER + V2RAY/XRAY (Opção 09)

Instalador **SSHPLUS atualizado** com o **V2ray/Xray (VLESS + Reality)** adicionado na **opção 09** do menu principal.

---

## 🎯 DUAS FORMAS DE USAR

### Opção A — Instalar direto (rápido)
Use o `Plus` desta pasta no seu VPS (os links de download continuam no repositório original, mas a opção 09 vem embutida no próprio arquivo):

```bash
wget <LINK_DO_SEU_ARQUIVO>/Plus
chmod +x Plus
./Plus
```

### Opção B — Repositório GitHub seu (todos os links trocados) ⭐
Rode o **`preparar_repo.sh`** para montar um repositório completo com **todos os links de download apontando para o SEU GitHub**:

1. Abra o `preparar_repo.sh` e edite as 3 linhas no topo:
   ```bash
   REPO_USER="SEU-USUARIO-GITHUB"   # ← seu usuário
   REPO_NAME="SSHPLUS-V2RAY"        # ← nome do repositório
   BRANCH="master"                  # ← master ou main (o que o GitHub criar)
   TELEGRAM="@meucanal"             # ← opcional: aparece nas mensagens do script
   ```
2. Rode: `./preparar_repo.sh`
3. Ele baixa os arquivos, aplica a opção 09, **troca todos os links** (Plus, modulos, menu, verificação de versão) e gera a pasta `SSHPLUS-V2RAY/` pronta.
4. Crie o repositório em https://github.com/new e envie:
   ```bash
   cd SSHPLUS-V2RAY
   git init && git add . && git commit -m "SSHPLUS + V2RAY opção 09"
   git branch -M master
   git remote add origin https://github.com/SEU-USUARIO/SSHPLUS-V2RAY.git
   git push -u origin master
   ```
5. Instale no VPS:
   ```bash
   wget https://raw.githubusercontent.com/SEU-USUARIO/SSHPLUS-V2RAY/master/Plus
   chmod +x Plus && ./Plus
   ```
6. Pronto: `menu` → opção **09** → V2RAY/XRAY.

> O `preparar_repo.sh` verifica sozinho: nenhum link original restante, sintaxe dos scripts e integridade do payload.

---

## 🎛️ Módulo v2rayx (opção 09) — funcionalidades

| Opção | Função |
|-------|--------|
| 01 | **INSTALAR XRAY CORE** — instala o Xray oficial (XTLS), gera config VLESS + Reality (porta 443 padrão, SNI configurável) |
| 02 | **CRIAR USUARIO V2RAY** — usa um usuário SSHPLUS existente ou cria um novo (dias, limite, senha) e gera UUID + link + QR Code |
| 03 | **REMOVER USUARIO V2RAY** — remove do Xray (opcional: remove também o usuário SSHPLUS) |
| 04 | **LISTAR USUARIOS V2RAY** — usuários, UUIDs, validade e links |
| 05 | **CONTROLE XRAY** — iniciar / parar / reiniciar + status |
| 06 | **VER CONFIGURAÇÃO** — resumo da config + links de todos + QR |
| 07 | **ALTERAR PORTA** — troca a porta e atualiza os links |
| 08 | **ATUALIZAR CORE XRAY** |
| 09 | **REMOVER XRAY** |
| 00 | Voltar ao menu |

---

## 🔗 Formato do link gerado (VLESS + Reality)

```
vless://UUID@IP:PORTA?encryption=none&flow=xtls-rprx-vision&security=reality&sni=SNI&fp=chrome&pbk=CHAVE_PUBLICA&sid=SHORT_ID&type=tcp&headerType=none#USUARIO
```

**Clientes compatíveis:** v2rayNG (Android), v2rayN (Windows), NekoBox, Shadowrocket (iOS), Hiddify etc.

---

## 🔧 Integração com o SSHPLUS

- **Limite de conexões** → `~/usuarios.db` (o mesmo banco do SSHPLUS)
- **Validade** → `chage` (aparece em "ALTERAR DATA", "RELATORIO", etc.)
- **Senha** → `/etc/SSHPlus/senha/<usuario>`
- **Links salvos** em `/root/v2ray-<usuario>.txt`

---

## 📁 Arquivos do pacote

| Arquivo | Descrição |
|---------|-----------|
| `Plus` | Instalador único (opção 09 embutida) |
| `preparar_repo.sh` | **Gera seu repositório GitHub com todos os links trocados** |
| `Modulos/v2rayx` | Módulo V2RAY/XRAY (fonte) |
| `Install/Skin_Plus/menuV3/menu` | Menu com a opção 09 (fonte) |
| `Install/versao` | Versão 39 + changelog |
| `Install/list` | Lista de módulos (inclui `v2rayx`) |
| `build_payload.sh` | Regenera o `Plus` a partir dos fontes |

---

## ⚠️ Observações

- Requer Debian/Ubuntu com **root**.
- Testado com **Xray v26** (formato novo do `x25519`) e compatível com versões antigas.
- O Xray inicia via `systemd` (com fallback no `/etc/autostart` do SSHPLUS).
- Se o GitHub criar o repositório com branch `main`, use `BRANCH="main"` no `preparar_repo.sh`.
- O módulo original `Modulos/alterarsenha` já vem com um bug no repositório do autor (arquivo sem o `fi` final) — não é alteração nossa.
