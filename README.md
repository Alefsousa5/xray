#!/bin/bash
#====================================================
#   MODULO XRAY - SSHPLUS MANAGER (XRAY EDITION)
#   GERENCIADOR XRAY-CORE INTEGRADO AO PAINEL
#   PROTOCOLOS: VLESS + WEBSOCKET / VLESS + REALITY
#====================================================
cor0='\033[0m'
cor1='\033[1;31m'
cor2='\033[1;32m'
cor3='\033[1;33m'
cor4='\033[0;34m'
cor6='\033[1;36m'
cor7='\033[1;37m'

XBIN='/usr/local/bin/xray'
XDIR='/usr/local/etc/xray'
CONF="$XDIR/config.json"
INFO='/etc/SSHPlus/xray.info'

fun_bar () {
comando="$1"
(
[[ -e $HOME/fim ]] && rm $HOME/fim
$comando > /dev/null 2>&1
touch $HOME/fim
) > /dev/null 2>&1 &
 tput civis
echo -ne "  ${cor3}AGUARDE ${cor7}- ${cor3}["
while true; do
   for((i=0; i<18; i++)); do
   echo -ne "${cor1}#"
   sleep 0.05s
   done
   [[ -e $HOME/fim ]] && rm $HOME/fim && break
   echo -e "${cor3}]"
   sleep 1s
   tput cuu1
   tput dl1
   echo -ne "  ${cor3}AGUARDE ${cor7}- ${cor3}["
done
echo -e "${cor3}]${cor7} -${cor2} OK !${cor7}"
tput cnorm
}

linha () { echo -e "${cor4}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${cor0}"; }

get_ip () {
[[ -e /etc/IP ]] && IP=$(cat /etc/IP) || IP=$(curl -s4 https://ipv4.icanhazip.com)
[[ -z "$IP" ]] && IP=$(curl -s4 http://whatismyip.akamai.com)
}

chk_dep () {
for _p in jq curl unzip; do
  command -v $_p > /dev/null 2>&1 || {
    echo -e "${cor3}INSTALANDO DEPENDENCIA: ${_p}${cor0}"
    apt-get update -y > /dev/null 2>&1
    apt-get install -y $_p > /dev/null 2>&1
  }
done
}

xray_ok () { [[ -e "$XBIN" && -e "$CONF" ]]; }

gen_uuid () {
local _u
_u=$($XBIN uuid 2>/dev/null | tail -n 1)
[[ -z "$_u" ]] && _u=$(cat /proc/sys/kernel/random/uuid)
echo "$_u"
}

save_info () {
mkdir -p /etc/SSHPlus
cat > "$INFO" <<EOF_INFO
PROTO=$PROTO
PORT=$PORT
CAMINHO=$CAMINHO
SNI=$SNI
PUB=$PUB
PRIV=$PRIV
SID=$SID
EOF_INFO
chmod 600 "$INFO"
}

load_info () { [[ -e "$INFO" ]] && source "$INFO"; }

mk_service () {
cat > /etc/systemd/system/xray.service <<EOF_SRVC
[Unit]
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=$XBIN run -config $CONF
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF_SRVC
systemctl daemon-reload > /dev/null 2>&1
}

gen_link () {
load_info
local _n="$1" _id="$2" _enc
if [[ "$PROTO" = "ws" ]]; then
  _enc=$(echo "$CAMINHO" | sed 's#/#%2F#g')
  echo "vless://${_id}@${IP}:${PORT}?type=ws&security=none&encryption=none&path=${_enc}#${_n}@${IP}"
else
  echo "vless://${_id}@${IP}:${PORT}?security=reality&encryption=none&pbk=${PUB}&fp=chrome&sni=${SNI}&sid=${SID}&type=tcp&flow=xtls-rprx-vision#${_n}@${IP}"
fi
}

show_dados () {
local _n="$1" _id="$2"
echo ""
linha
echo -e "${cor2}DADOS DA CONEXAO${cor0}"
echo -e "${cor3}USUARIO : ${cor7}$_n"
echo -e "${cor3}IP/PORTA: ${cor7}$IP:$PORT"
echo -e "${cor3}UUID    : ${cor7}$_id"
[[ "$PROTO" = "ws" ]] && {
  echo -e "${cor3}REDE    : ${cor7}WEBSOCKET (ws)"
  echo -e "${cor3}CAMINHO : ${cor7}$CAMINHO"
  echo -e "${cor3}SEGUR.  : ${cor7}none"
} || {
  echo -e "${cor3}REDE    : ${cor7}TCP + REALITY"
  echo -e "${cor3}SNI     : ${cor7}$SNI"
  echo -e "${cor3}FLOW    : ${cor7}xtls-rprx-vision"
}
linha
echo -e "${cor6}LINK DE COMPARTILHAMENTO:${cor0}"
echo -e "${cor7}$(gen_link "$_n" "$_id")${cor0}"
linha
}

inst_core () {
curl -sL "https://github.com/XTLS/Xray-install/raw/main/install-release.sh" -o /tmp/xray-install.sh
bash /tmp/xray-install.sh install > /dev/null 2>&1
[[ ! -e "$XBIN" ]] && {
  local _arch _a _tag
  _arch=$(uname -m)
  case "$_arch" in
    x86_64|amd64) _a='64' ;;
    aarch64|arm64) _a='arm64-v8a' ;;
    armv7l) _a='arm32-v7a' ;;
    *) _a='64' ;;
  esac
  _tag=$(curl -s "https://api.github.com/repos/XTLS/Xray-core/releases/latest" | jq -r '.tag_name')
  [[ -z "$_tag" || "$_tag" = "null" ]] && _tag="v1.8.10"
  wget -q "https://github.com/XTLS/Xray-core/releases/download/${_tag}/Xray-linux-${_a}.zip" -O /tmp/xray.zip
  mkdir -p /tmp/xraypkg "$XDIR" /usr/local/share/xray
  unzip -o /tmp/xray.zip -d /tmp/xraypkg > /dev/null 2>&1
  [[ -e /tmp/xraypkg/xray ]] && cp /tmp/xraypkg/xray "$XBIN" && chmod +x "$XBIN"
  [[ -e /tmp/xraypkg/geoip.dat ]] && cp /tmp/xraypkg/geoip.dat /usr/local/share/xray/
  [[ -e /tmp/xraypkg/geosite.dat ]] && cp /tmp/xraypkg/geosite.dat /usr/local/share/xray/
  mk_service
  rm -rf /tmp/xray.zip /tmp/xraypkg
}
[[ ! -e /etc/systemd/system/xray.service ]] && mk_service
mkdir -p "$XDIR"
}

inst_xray () {
clear
linha
echo -e "${cor3}                 • INSTALAR XRAY-CORE •${cor0}"
linha
echo ""
PROTO=""
PORT=""
CAMINHO="/sshplus"
SNI="www.microsoft.com"
PUB=""
PRIV=""
SID=""
xray_ok && {
  echo -e "${cor3}UMA INSTALACAO DO XRAY JA EXISTE!${cor0}"
  echo -ne "${cor2}REINSTALAR E SUBSTITUIR A CONFIG ${cor3}? ${cor7}[s/n]: ${cor0}"
  read _re
  [[ "$_re" != @(s|S) ]] && return
  systemctl stop xray > /dev/null 2>&1
  echo ""
}
echo -e "${cor1}[${cor6}01${cor1}] ${cor7}• ${cor3}VLESS + WEBSOCKET ${cor7}(sem TLS)${cor1}"
echo -e "${cor1}[${cor6}02${cor1}] ${cor7}• ${cor3}VLESS + TCP + REALITY ${cor7}(com camuflagem)${cor1}"
echo -e "${cor1}[${cor6}00${cor1}] ${cor7}• ${cor3}VOLTAR${cor1}"
echo ""
echo -ne "${cor2}QUAL PROTOCOLO ${cor3}?${cor1}?${cor7} : ${cor0}"; read _proto
[[ -z "$_proto" || "$_proto" = @(0|00) ]] && return
if [[ "$_proto" = @(1|01) ]]; then
  PROTO='ws'; _dport='8080'
elif [[ "$_proto" = @(2|02) ]]; then
  PROTO='reality'; _dport='443'
else
  echo -e "\n${cor1}Opcao invalida !${cor0}"; sleep 2; return
fi
echo ""
echo -ne "${cor2}PORTA DE ESCUTA ${cor3}[padrao ${_dport}]${cor7} : ${cor0}"; read _prt
PORT=${_prt:-$_dport}
[[ "$PORT" =~ ^[0-9]+$ && $PORT -ge 1 && $PORT -le 65535 ]] || {
  echo -e "\n${cor1}Porta invalida !${cor0}"; sleep 2; return
}
ss -nplt 2>/dev/null | grep -q -w ":$PORT" && {
  echo -e "\n${cor3}ATENCAO: a porta $PORT ja esta em uso por outro servico!${cor0}"
  echo -ne "${cor2}CONTINUAR MESMO ASSIM ${cor3}? ${cor7}[s/n]: ${cor0}"
  read _cnt
  [[ "$_cnt" != @(s|S) ]] && return
}
if [[ "$PROTO" = "ws" ]]; then
  echo -ne "${cor2}CAMINHO (path) WS ${cor3}[padrao /sshplus]${cor7} : ${cor0}"; read _c
  CAMINHO=${_c:-/sshplus}
  [[ "${CAMINHO:0:1}" != "/" ]] && CAMINHO="/$CAMINHO"
else
  echo -ne "${cor2}DESTINO/SNI DE CAMUFLAGEM ${cor3}[padrao www.microsoft.com]${cor7} : ${cor0}"; read _s
  SNI=${_s:-www.microsoft.com}
fi
echo ""
echo -e "${cor3}BAIXANDO E INSTALANDO O XRAY-CORE...${cor0}"
echo ""
chk_dep
fun_bar 'inst_core'
[[ ! -e "$XBIN" ]] && {
  echo -e "\n${cor1}ERRO: NAO FOI POSSIVEL INSTALAR O XRAY-CORE!${cor0}"
  echo -ne "\n${cor1}ENTER ${cor3}para retornar!${cor0}"; read
  return
}
FIRST_UUID=$(gen_uuid)
if [[ "$PROTO" = "ws" ]]; then
cat > "$CONF" <<EOF_CFG
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": $PORT,
      "protocol": "vless",
      "tag": "vless-ws-in",
      "settings": {
        "clients": [ { "id": "$FIRST_UUID", "email": "sshplus" } ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": { "path": "$CAMINHO" }
      },
      "sniffing": { "enabled": true, "destOverride": [ "http", "tls" ] }
    }
  ],
  "outbounds": [
    { "protocol": "freedom", "tag": "direct" },
    { "protocol": "blackhole", "tag": "blocked" }
  ]
}
EOF_CFG
else
KEYS=$($XBIN x25519 2>/dev/null)
PRIV=$(echo "$KEYS" | grep -i 'privat' | awk '{print $NF}')
PUB=$(echo "$KEYS" | grep -i 'public' | awk '{print $NF}')
SID=$(cat /proc/sys/kernel/random/uuid | tr -d '-' | cut -c1-8)
[[ -z "$PRIV" || -z "$PUB" ]] && {
  echo -e "\n${cor1}ERRO AO GERAR CHAVES REALITY!${cor0}"; sleep 2; return
}
cat > "$CONF" <<EOF_CFG
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": $PORT,
      "protocol": "vless",
      "tag": "vless-reality-in",
      "settings": {
        "clients": [ { "id": "$FIRST_UUID", "flow": "xtls-rprx-vision", "email": "sshplus" } ],
        "decryption": "none",
        "fallbacks": [ { "dest": "$SNI:443" } ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "$SNI:443",
          "xver": 0,
          "serverNames": [ "$SNI" ],
          "privateKey": "$PRIV",
          "shortIds": [ "$SID" ]
        }
      },
      "sniffing": { "enabled": true, "destOverride": [ "http", "tls" ] }
    }
  ],
  "outbounds": [
    { "protocol": "freedom", "tag": "direct" },
    { "protocol": "blackhole", "tag": "blocked" }
  ]
}
EOF_CFG
fi
save_info
[[ -e /usr/sbin/ufw ]] && ufw allow ${PORT}/tcp > /dev/null 2>&1
echo ""
fun_bar 'systemctl enable xray; systemctl restart xray; sleep 2'
clear
linha
if [[ "$(systemctl is-active xray 2>/dev/null)" = "active" ]]; then
  echo -e "${cor2}         • XRAY INSTALADO E ATIVO •${cor0}"
  load_info
  show_dados "sshplus" "$FIRST_UUID"
else
  echo -e "${cor1}      • XRAY INSTALADO MAS NAO INICIOU •${cor0}"
  echo -e "${cor3}VERIFIQUE OS LOGS NA OPCAO 07 DO MENU XRAY${cor0}"
fi
echo -ne "\n${cor1}ENTER ${cor3}para retornar!${cor0}"; read
}

add_user () {
xray_ok || { echo -e "\n${cor1}XRAY NAO INSTALADO! USE A OPCAO 01.${cor0}"; sleep 2; return; }
clear
linha
echo -e "${cor3}               • CRIAR USUARIO XRAY •${cor0}"
linha
echo ""
echo -ne "${cor2}NOME DO USUARIO ${cor7}: ${cor0}"; read _nome
[[ -z "$_nome" ]] && return
_nok=$(jq --arg e "$_nome" '[.inbounds[0].settings.clients[] | select(.email==$e)] | length' "$CONF" 2>/dev/null)
[[ "$_nok" != "0" && -n "$_nok" ]] && {
  echo -e "\n${cor1}USUARIO JA EXISTE!${cor0}"; sleep 2; return
}
_id=$(gen_uuid)
load_info
_tmp=$(mktemp)
if [[ "$PROTO" = "reality" ]]; then
  jq --arg id "$_id" --arg em "$_nome" '.inbounds[0].settings.clients += [{"id":$id,"flow":"xtls-rprx-vision","email":$em}]' "$CONF" > "$_tmp" 2>/dev/null
else
  jq --arg id "$_id" --arg em "$_nome" '.inbounds[0].settings.clients += [{"id":$id,"email":$em}]' "$CONF" > "$_tmp" 2>/dev/null
fi
if jq empty "$_tmp" 2>/dev/null; then
  cat "$_tmp" > "$CONF"
  rm -f "$_tmp"
  systemctl restart xray > /dev/null 2>&1
  echo -e "\n${cor2}USUARIO CRIADO COM SUCESSO!${cor0}"
  show_dados "$_nome" "$_id"
else
  rm -f "$_tmp"
  echo -e "\n${cor1}ERRO AO SALVAR A CONFIGURACAO!${cor0}"
fi
echo -ne "\n${cor1}ENTER ${cor3}para retornar!${cor0}"; read
}

del_user () {
xray_ok || { echo -e "\n${cor1}XRAY NAO INSTALADO!${cor0}"; sleep 2; return; }
clear
linha
echo -e "${cor3}               • REMOVER USUARIO XRAY •${cor0}"
linha
echo ""
_n=0
for _e in $(jq -r '.inbounds[0].settings.clients[].email' "$CONF" 2>/dev/null); do
  _n=$((_n+1))
  echo -e "${cor1}[${cor6}$(printf '%02d' $_n)${cor1}] ${cor7}• ${cor3}$_e${cor0}"
done
[[ $_n -eq 0 ]] && { echo -e "${cor1}NENHUM USUARIO CADASTRADO!${cor0}"; sleep 2; return; }
echo ""
echo -ne "${cor2}NOME DO USUARIO A REMOVER ${cor7}: ${cor0}"; read _nome
[[ -z "$_nome" ]] && return
_tmp=$(mktemp)
jq --arg e "$_nome" 'del(.inbounds[0].settings.clients[] | select(.email==$e))' "$CONF" > "$_tmp" 2>/dev/null
if jq empty "$_tmp" 2>/dev/null; then
  cat "$_tmp" > "$CONF"
  rm -f "$_tmp"
  systemctl restart xray > /dev/null 2>&1
  echo -e "\n${cor2}USUARIO $_nome REMOVIDO!${cor0}"
else
  rm -f "$_tmp"
  echo -e "\n${cor1}ERRO AO SALVAR A CONFIGURACAO!${cor0}"
fi
sleep 2
}

list_user () {
xray_ok || { echo -e "\n${cor1}XRAY NAO INSTALADO!${cor0}"; sleep 2; return; }
clear
linha
echo -e "${cor3}            • USUARIOS XRAY + LINKS •${cor0}"
linha
load_info
_n=0
while read -r _line; do
  _n=$((_n+1))
  _nome=$(echo "$_line" | awk '{print $1}')
  _id=$(echo "$_line" | awk '{print $2}')
  echo ""
  echo -e "${cor1}[${cor6}$(printf '%02d' $_n)${cor1}] ${cor3}$_nome ${cor1}| ${cor7}$_id${cor0}"
  echo -e "${cor6}$(gen_link "$_nome" "$_id")${cor0}"
done < <(jq -r '.inbounds[0].settings.clients[] | "\(.email) \(.id)"' "$CONF" 2>/dev/null)
[[ $_n -eq 0 ]] && echo -e "\n${cor1}NENHUM USUARIO CADASTRADO!${cor0}"
echo ""
linha
echo -ne "\n${cor1}ENTER ${cor3}para retornar!${cor0}"; read
}

alt_port () {
xray_ok || { echo -e "\n${cor1}XRAY NAO INSTALADO!${cor0}"; sleep 2; return; }
load_info
clear
linha
echo -e "${cor3}               • ALTERAR PORTA XRAY •${cor0}"
linha
echo -e "${cor3}PORTA ATUAL: ${cor7}$PORT"
echo ""
echo -ne "${cor2}NOVA PORTA ${cor7}: ${cor0}"; read _np
[[ "$_np" =~ ^[0-9]+$ && $_np -ge 1 && $_np -le 65535 ]] || {
  echo -e "\n${cor1}Porta invalida !${cor0}"; sleep 2; return
}
_tmp=$(mktemp)
jq --argjson p "$_np" '.inbounds[0].port=$p' "$CONF" > "$_tmp" 2>/dev/null
if jq empty "$_tmp" 2>/dev/null; then
  cat "$_tmp" > "$CONF"
  rm -f "$_tmp"
  [[ -e /usr/sbin/ufw ]] && ufw allow ${_np}/tcp > /dev/null 2>&1
  sed -i "s/^PORT=.*/PORT=$_np/" "$INFO"
  systemctl restart xray > /dev/null 2>&1
  echo -e "\n${cor2}PORTA ALTERADA PARA $_np COM SUCESSO!${cor0}"
else
  rm -f "$_tmp"
  echo -e "\n${cor1}ERRO AO SALVAR A CONFIGURACAO!${cor0}"
fi
sleep 2
}

restart_xray () {
xray_ok || { echo -e "\n${cor1}XRAY NAO INSTALADO!${cor0}"; sleep 2; return; }
echo ""
fun_bar 'systemctl restart xray; sleep 2'
[[ "$(systemctl is-active xray 2>/dev/null)" = "active" ]] && {
  echo -e "${cor2}SERVICO XRAY REINICIADO E ATIVO!${cor0}"
} || {
  echo -e "${cor1}SERVICO NAO INICIOU! VEJA OS LOGS (OPCAO 07).${cor0}"
}
sleep 2
}

status_xray () {
clear
linha
echo -e "${cor3}               • STATUS DO SERVICO XRAY •${cor0}"
linha
echo ""
[[ -e "$XBIN" ]] && echo -e "${cor3}VERSAO: ${cor7}$($XBIN version 2>/dev/null | head -n 1)"
echo -e "${cor3}STATUS: ${cor7}$(systemctl is-active xray 2>/dev/null || echo inactive)"
load_info
[[ -n "$PORT" ]] && echo -e "${cor3}PORTA : ${cor7}$PORT ${cor3}PROTOCOLO: ${cor7}$PROTO"
echo ""
linha
echo -e "${cor3}ULTIMOS LOGS:${cor0}"
echo ""
journalctl -u xray -n 15 --no-pager 2>/dev/null | tail -n 15
linha
echo -ne "\n${cor1}ENTER ${cor3}para retornar!${cor0}"; read
}

uninstall_xray () {
clear
linha
echo -e "${cor1}              • DESINSTALAR O XRAY •${cor0}"
linha
echo ""
echo -ne "${cor2}TEM CERTEZA QUE DESEJA REMOVER O XRAY ${cor3}? ${cor7}[s/n]: ${cor0}"
read _rm
[[ "$_rm" != @(s|S) ]] && return
echo ""
load_info
fun_bar '
systemctl stop xray
systemctl disable xray
rm -f /etc/systemd/system/xray.service
rm -f /usr/local/bin/xray
rm -rf /usr/local/etc/xray
rm -rf /usr/local/share/xray
rm -f /etc/SSHPlus/xray.info
systemctl daemon-reload
sleep 1
'
[[ -e /usr/sbin/ufw && -n "$PORT" ]] && ufw delete allow ${PORT}/tcp > /dev/null 2>&1
echo -e "${cor2}XRAY REMOVIDO COM SUCESSO!${cor0}"
sleep 2
}

xray_menu () {
[[ "$(whoami)" != "root" ]] && {
  echo -e "${cor1}EXECUTE COMO ROOT!${cor0}"; exit 1
}
get_ip
while true; do
xray_ok && stsx="${cor2}◉" || stsx="${cor1}○"
clear
linha
echo -e "${cor4}┏━ ${cor7}SSHPLUS MANAGER ${cor1}• ${cor3}GERENCIADOR XRAY $stsx ${cor4}━┓${cor0}"
linha
echo ""
echo -e "${cor1}[${cor6}01${cor1}] ${cor7}• ${cor3}INSTALAR / REINSTALAR XRAY
${cor1}[${cor6}02${cor1}] ${cor7}• ${cor3}CRIAR USUARIO XRAY
${cor1}[${cor6}03${cor1}] ${cor7}• ${cor3}REMOVER USUARIO
${cor1}[${cor6}04${cor1}] ${cor7}• ${cor3}USUARIOS + LINKS
${cor1}[${cor6}05${cor1}] ${cor7}• ${cor3}ALTERAR PORTA
${cor1}[${cor6}06${cor1}] ${cor7}• ${cor3}REINICIAR SERVICO
${cor1}[${cor6}07${cor1}] ${cor7}• ${cor3}STATUS / LOGS
${cor1}[${cor6}08${cor1}] ${cor7}• ${cor3}DESINSTALAR XRAY
${cor1}[${cor6}00${cor1}] ${cor7}• ${cor3}VOLTAR ${cor2}<${cor3}<${cor1}< ${cor0}"
echo ""
linha
echo -ne "${cor2}OQUE DESEJA FAZER ${cor3}?${cor1}?${cor7} : ${cor0}"; read _op
case "$_op" in
1|01) inst_xray ;;
2|02) add_user ;;
3|03) del_user ;;
4|04) list_user ;;
5|05) alt_port ;;
6|06) restart_xray ;;
7|07) status_xray ;;
8|08) uninstall_xray ;;
0|00) echo -e "${cor1}Voltando...${cor0}"; sleep 1; exit 0 ;;
*) echo -e "\n${cor1}Opcao invalida !${cor0}"; sleep 1 ;;
esac
done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  xray_menu "$@"
fi
 
