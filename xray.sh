#!/bin/bash
#====================================================
#   XRAY.SH — INSTALADOR DO MODULO XRAY VIA GITHUB
#   (UMA LINHA) Baixa o modulo XRAY do SEU
#   repositorio, instala/atualiza e abre o menu.
#
#   USO NO VPS (uma linha):
#   bash <(curl -sL https://raw.githubusercontent.com/Alefsousa5/xray/main/xray.sh)
#
#   OU:
#   wget -qO- https://raw.githubusercontent.com/Alefsousa5/xray/main/xray.sh | bash
#
#   Para rodar de novo depois (atualiza o modulo):
#   xray
#====================================================

# >>>>>>>>>>>>>>> EDITE AQUI SE MUDAR O REPO <<<<<<<<<<<<<<<<
REPO_USER="Alefsousa5"
REPO_NAME="xray"
BRANCH="main"
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

cor0='\033[0m'
cor1='\033[1;31m'
cor2='\033[1;32m'
cor3='\033[1;33m'
cor7='\033[1;37m'

RAW="https://raw.githubusercontent.com/$REPO_USER/$REPO_NAME/$BRANCH"
LIB="/usr/local/lib/sshplus-xray"
MOD="$LIB/xray"
PATCH="$LIB/patch_menu.sh"
BIN="/bin/xray"
TMPD=$(mktemp -d)
trap 'rm -rf "$TMPD"' EXIT

linha () { echo -e "${cor7}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${cor0}"; }

echo ""
linha
echo -e " ${cor7}MODULO XRAY (VLESS/REALITY) ${cor3}• github.com/${REPO_USER}/${REPO_NAME}${cor0}"
linha
echo ""

# --- precisa rodar como root ---
[[ "$(whoami)" != "root" ]] && {
  echo -e " ${cor1}ERRO: execute como root!${cor0}"
  exit 1
}

# --- dependencias ---
for c in jq unzip; do
  command -v "$c" >/dev/null 2>&1 || {
    echo -e "${cor3}Instalando dependencia: ${c}...${cor0}"
    apt-get update -y >/dev/null 2>&1
    apt-get install -y "$c" >/dev/null 2>&1
  }
done
command -v jq >/dev/null 2>&1 || { echo -e "${cor1}ERRO: jq nao instalou!${cor0}"; exit 1; }
command -v unzip >/dev/null 2>&1 || { echo -e "${cor1}ERRO: unzip nao instalou!${cor0}"; exit 1; }
command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1 || {
  echo -e "${cor1}ERRO: precisa do curl ou wget!${cor0}"; exit 1
}

# --- download do xray.zip do proprio repositorio ---
dl () {
  if command -v curl >/dev/null 2>&1; then
    curl -sL --max-time 120 -o "$1" "$2"
  else
    wget -q -T 120 -O "$1" "$2"
  fi
}

echo -e "${cor3}Baixando o modulo do seu repositório...${cor0}"
echo -e "${cor7}${RAW}/xray.zip${cor0}"
dl "$TMPD/xray.zip" "$RAW/xray.zip"
[[ -s "$TMPD/xray.zip" ]] || {
  echo -e " ${cor1}ERRO: falha no download! Verifique sua internet.${cor0}"
  exit 1
}
unzip -t "$TMPD/xray.zip" >/dev/null 2>&1 || {
  echo -e " ${cor1}ERRO: o arquivo baixado esta corrompido!${cor0}"
  exit 1
}

# --- extrair e instalar ---
unzip -o -q "$TMPD/xray.zip" "sshplus/xray" "sshplus/patch_menu.sh" -d "$TMPD/ext"
[[ -f "$TMPD/ext/sshplus/xray" ]] || {
  echo -e " ${cor1}ERRO: o modulo xray nao foi encontrado no zip!${cor0}"
  exit 1
}
mkdir -p "$LIB"
UPD="atualizado"
[[ -e "$MOD" ]] || UPD="instalado"
install -m 755 "$TMPD/ext/sshplus/xray" "$MOD"
[[ -f "$TMPD/ext/sshplus/patch_menu.sh" ]] && install -m 755 "$TMPD/ext/sshplus/patch_menu.sh" "$PATCH"
echo -e " ${cor2}Modulo $UPD em ${MOD}${cor0}"

# --- atalho /bin/xray (rode de novo quando quiser: atualiza e abre o menu) ---
cat > "$BIN" <<'EOF_ATALHO'
#!/bin/bash
# Atalho gerado pelo xray.sh — atualiza o modulo do GitHub e executa
if [[ "$(whoami)" = "root" ]]; then
  TMPD_X=$(mktemp -d)
  ( curl -sL --max-time 60 -o "$TMPD_X/xray.zip" "https://raw.githubusercontent.com/Alefsousa5/xray/main/xray.zip" \
      || wget -q -T 60 -O "$TMPD_X/xray.zip" "https://raw.githubusercontent.com/Alefsousa5/xray/main/xray.zip" ) >/dev/null 2>&1
  if unzip -t "$TMPD_X/xray.zip" >/dev/null 2>&1; then
    unzip -o -q "$TMPD_X/xray.zip" "sshplus/xray" "sshplus/patch_menu.sh" -d "$TMPD_X/ext" >/dev/null 2>&1
    [[ -f "$TMPD_X/ext/sshplus/xray" ]] && install -m 755 "$TMPD_X/ext/sshplus/xray" /usr/local/lib/sshplus-xray/xray
    [[ -f "$TMPD_X/ext/sshplus/patch_menu.sh" ]] && install -m 755 "$TMPD_X/ext/sshplus/patch_menu.sh" /usr/local/lib/sshplus-xray/patch_menu.sh
  fi
  rm -rf "$TMPD_X"
fi
exec /usr/local/lib/sshplus-xray/xray "$@"
EOF_ATALHO
chmod +x "$BIN"

# --- integra ao menu SSHPLUS, se existir (idempotente) ---
if [[ -e /bin/menu && -e "$PATCH" ]]; then
  bash "$PATCH" >/dev/null 2>&1 && echo -e " ${cor3}Menu SSHPLUS integrado (opcao 31).${cor0}"
fi

echo ""
exec "$MOD" "$@"
