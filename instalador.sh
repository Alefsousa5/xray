#!/bin/bash
#====================================================
#   INSTALADOR.SH — INSTALADOR GERAL DO REPOSITORIO
#   Ponto unico de entrada: baixa e instala os
#   pacotes direto do SEU repositorio GitHub.
#
#   USO NO VPS (uma linha):
#   bash <(curl -sL https://raw.githubusercontent.com/Alefsousa5/xray/main/instalador.sh)
#
#   OU:
#   wget -qO- https://raw.githubusercontent.com/Alefsousa5/xray/main/instalador.sh | bash
#====================================================

# >>>>>>>>>>>>>> EDITE AQUI SE MUDAR O REPO <<<<<<<<<<<<<<
REPO_USER="Alefsousa5"
REPO_NAME="xray"
BRANCH="main"
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

cor0='\033[0m'
cor1='\033[1;31m'
cor2='\033[1;32m'
cor3='\033[1;33m'
cor6='\033[1;36m'
cor7='\033[1;37m'

RAW="https://raw.githubusercontent.com/$REPO_USER/$REPO_NAME/$BRANCH"

linha () { echo -e "${cor7}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${cor0}"; }

# --- precisa rodar como root ---
[[ "$(whoami)" != "root" ]] && {
  echo -e " ${cor1}ERRO: execute como root!${cor0}"
  exit 1
}

# --- dependencias ---
for c in curl wget; do
  command -v "$c" >/dev/null 2>&1 || {
    echo -e " ${cor3}Instalando dependencia: ${c}...${cor0}"
    apt-get update -y >/dev/null 2>&1
    apt-get install -y "$c" >/dev/null 2>&1
  }
done
command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1 || {
  echo -e " ${cor1}ERRO: precisa do curl ou wget!${cor0}"
  exit 1
}

# --- download (curl com fallback p/ wget) ---
dl () {
  if command -v curl >/dev/null 2>&1; then
    curl -sL --max-time 300 -o "$1" "$2"
  else
    wget -q -T 300 -O "$1" "$2"
  fi
}

inst_sshplus () {
  echo ""
  echo -e " ${cor3}Baixando o instalador ${cor7}Plus${cor3} do seu repositório...${cor0}"
  echo -e " ${cor7}${RAW}/Plus${cor0}"
  dl "$HOME/Plus" "$RAW/Plus"
  [[ -s "$HOME/Plus" ]] || {
    echo -e " ${cor1}ERRO: falha no download do Plus! Verifique sua internet.${cor0}"
    sleep 2
    return 1
  }
  chmod +x "$HOME/Plus"
  echo ""
  echo -e " ${cor2}Iniciando a instalacao do SSHPLUS + XRAY...${cor0}"
  echo ""
  exec "$HOME/Plus"
}

inst_xray () {
  echo ""
  echo -e " ${cor3}Baixando o instalador ${cor7}xray.sh${cor3} do seu repositório...${cor0}"
  echo -e " ${cor7}${RAW}/xray.sh${cor0}"
  dl /tmp/xray.sh "$RAW/xray.sh"
  [[ -s /tmp/xray.sh ]] || {
    echo -e " ${cor1}ERRO: falha no download do xray.sh! Verifique sua internet.${cor0}"
    sleep 2
    return 1
  }
  echo ""
  echo -e " ${cor2}Iniciando a instalacao do XRAY standalone...${cor0}"
  echo ""
  exec bash /tmp/xray.sh
}

# --- menu ---
while true; do
  clear
  echo ""
  linha
  echo -e "  ${cor7}INSTALADOR DO REPOSITORIO ${cor3}• ${cor7}github.com/${REPO_USER}/${REPO_NAME}${cor0}"
  linha
  echo ""
  echo -e " ${cor1}[${cor6}01${cor1}] ${cor7}• ${cor3}SSHPLUS COMPLETO + XRAY ${cor7}(menu, opcao 09)${cor0}"
  echo -e " ${cor1}[${cor6}02${cor1}] ${cor7}• ${cor3}SO O XRAY ${cor7}(standalone, sem SSHPLUS)${cor0}"
  echo -e " ${cor1}[${cor6}00${cor1}] ${cor7}• ${cor3}SAIR${cor0}"
  echo ""
  linha
  echo -ne " ${cor2}OQUE DESEJA INSTALAR ${cor3}? ${cor7}: ${cor0}"
  read _op
  case "$_op" in
    1|01) inst_sshplus ;;
    2|02) inst_xray ;;
    0|00) echo -e " ${cor1}Encerrando...${cor0}"; sleep 1; exit 0 ;;
    *) echo -e " ${cor1}Opcao invalida!${cor0}"; sleep 1 ;;
  esac
done
