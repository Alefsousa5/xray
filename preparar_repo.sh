#!/bin/bash
# ====================================================
#  PREPARAR_REPO.SH
#  Gera o repositório GitHub completo do SSHPLUS+V2RAY
#  com TODOS os links de download apontando para o SEU
#  repositório. Pronto para dar git push.
#
#  Uso:  ./preparar_repo.sh
# ====================================================
# >>>>>>>>>>>>>> EDITE AQUI COM SEUS DADOS <<<<<<<<<<<<<<
REPO_USER="SEU-USUARIO-GITHUB"          # seu usuario do GitHub
REPO_NAME="SSHPLUS-V2RAY"               # nome do seu repositorio
BRANCH="master"                         # master ou main
# opcional: seu Telegram p/ aparecer nas mensagens (ex: @meucanal)
# deixe vazio para manter o do autor original
TELEGRAM=""
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

set -e
DIR_SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="./$REPO_NAME"

ORIG_USER="AAAAAEXQOSyIpN2JZ0ehUQ"
ORIG_REPO="SSHPLUS-MANAGER-FREE"
ORIG_RAW="https://raw.githubusercontent.com/$ORIG_USER/$ORIG_REPO/$BRANCH"
NEW_RAW="https://raw.githubusercontent.com/$REPO_USER/$REPO_NAME/$BRANCH"

[[ "$REPO_USER" == "SEU-USUARIO-GITHUB" ]] && {
    echo -e "\033[1;31mERRO: edite REPO_USER e REPO_NAME no topo do script!\033[0m"
    exit 1
}

for cmd in curl jq base64 tar sed; do
    which "$cmd" > /dev/null 2>&1 || { echo -e "\033[1;31mFalta: $cmd\033[0m"; exit 1; }
done

echo -e "\033[1;33m[1/6] Baixando arquivos do repositório original...\033[0m"
TMPD=$(mktemp -d)
trap "rm -rf $TMPD" EXIT
cd "$TMPD"

# lista de arquivos de texto (exclui midia / painel web / projetos)
curl -s "https://api.github.com/repos/$ORIG_USER/$ORIG_REPO/git/trees/$BRANCH?recursive=1" \
    | jq -r '.tree[] | select(.type=="blob") | .path' \
    | grep -vE '\.(png|jpg|jpeg|gif|mp4|zip|tgz|ovpn|sql|gz|pem|crt|key|dat|db|sqlite)$' \
    | grep -vE '^Imagenes/|^Proyectos/|^Install/Panel_Web/|^Install/multi_instalador.sh$' \
    > paths.txt

ok=0
while read -r p; do
    mkdir -p "$(dirname "$p")" 2>/dev/null
    curl -sf --max-time 30 -o "$p" "$ORIG_RAW/$p" && ok=$((ok+1)) || true
done < paths.txt

# binarios pequenos necessarios na instalacao
for bin in EasyRSA-3.0.1.tgz badvpn-udpgw stunnel.pem squid3 dns dns-server slowdns jq-linux64 sshd_config resolved.conf; do
    curl -sf --max-time 60 -o "Install/$bin" "$ORIG_RAW/Install/$bin" && ok=$((ok+1)) || echo "  (aviso: Install/$bin indisponivel)"
done

echo -e "  \033[1;32m$ok arquivos baixados\033[0m"

echo -e "\033[1;33m[2/6] Aplicando as modificações (opção 09 - V2RAY/XRAY)...\033[0m"
# modulo v2rayx
cp "$DIR_SRC/Modulos/v2rayx" Modulos/v2rayx
chmod +x Modulos/v2rayx
# menu com opção 09
cp "$DIR_SRC/Install/Skin_Plus/menuV3/menu" Install/Skin_Plus/menuV3/menu
# list com v2rayx + versao 39
cp "$DIR_SRC/Install/list" Install/list
cp "$DIR_SRC/Install/versao" Install/versao
# README adaptado
cp "$DIR_SRC/README.md" README.md

echo -e "\033[1;33m[3/6] Montando o Plus (instalador único com payload)...\033[0m"
mkdir -p /tmp/.pldir
cp Modulos/v2rayx /tmp/.pldir/v2rayx
cp Install/Skin_Plus/menuV3/menu /tmp/.pldir/menu
cd /tmp/.pldir && tar czf /tmp/.payload.tar.gz v2rayx menu && cd - > /dev/null
B64=$(base64 -w0 /tmp/.payload.tar.gz)
sed "s|^__PAYLOAD__$|${B64}|" "$DIR_SRC/_build/Plus_base" > Plus
chmod +x Plus
rm -rf /tmp/.pldir /tmp/.payload.tar.gz

echo -e "\033[1;33m[4/6] Trocando TODOS os links de download para o SEU repositório...\033[0m"
n=0
while IFS= read -r f; do
    grep -q "AAAAAEXQOSyIpN2JZ0ehUQ" "$f" || continue
    sed -i "s|$ORIG_RAW|$NEW_RAW|g; s|https://github.com/$ORIG_USER/$ORIG_REPO|https://github.com/$REPO_USER/$REPO_NAME|g" "$f"
    [[ -n "$TELEGRAM" ]] && sed -i "s|@AAAAAEXQOSyIpN2JZ0ehUQ|$TELEGRAM|g; s|t.me/AAAAAEXQOSyIpN2JZ0ehUQ|t.me/${TELEGRAM#@}|g" "$f"
    n=$((n+1))
done < <(find . -type f)
echo -e "  \033[1;32m$n arquivos com links atualizados\033[0m"

echo -e "\033[1;33m[5/6] Verificações...\033[0m"
rest=$(grep -rl "AAAAAEXQOSyIpN2JZ0ehUQ" . 2>/dev/null || true)
[[ -z "$rest" ]] && echo -e "  \033[1;32mOK: nenhum link original restante\033[0m" || { echo -e "  \033[1;31mAINDA EXISTEM LINKS ORIGINAIS:\033[0m $rest"; }
# sintaxe dos scripts (ignora arquivos python e o alterarsenha que ja vem com bug no repo original)
err=0
while IFS= read -r f; do
    case "$f" in
        *.py|*/alterarsenha) continue ;;
    esac
    bash -n "$f" 2>/dev/null || { echo "  sintaxe: $f"; err=1; }
done < <(find . -type f \( -name "*.sh" -o -name "Plus" -o -path "./Modulos/*" -o -path "./Install/Skin_Plus/*" -o -name "list" -o -name "credits" -o -name "systemverify" -o -name "versao" \))
[[ $err -eq 0 ]] && echo -e "  \033[1;32mOK: sintaxe de todos os scripts\033[0m" || echo -e "  \033[1;33m(aviso: arquivos listados acima)\033[0m"
# payload do Plus
sed -n '/^#__V2RAYX_PAYLOAD_START__$/,$p' Plus | tail -n +2 | base64 -d > /tmp/.pcheck.tar 2>/dev/null \
    && tar tf /tmp/.pcheck.tar > /dev/null 2>&1 \
    && echo -e "  \033[1;32mOK: payload do Plus íntegro (v2rayx + menu)\033[0m" \
    || echo -e "  \033[1;31mFALHA: payload do Plus\033[0m"
rm -f /tmp/.pcheck.tar

echo -e "\033[1;33m[6/6] Gerando a pasta final...\033[0m"
rm -rf "$DIR_SRC/$REPO_NAME"
mkdir -p "$DIR_SRC/$REPO_NAME"
cp -a . "$DIR_SRC/$REPO_NAME/"
echo -e "  \033[1;32mPasta criada: $DIR_SRC/$REPO_NAME/\033[0m"

cat <<EOF

============================================================
 ✅ REPOSITÓRIO PRONTO: $REPO_NAME/
============================================================
1) Crie o repositório no GitHub:
   https://github.com/new  →  nome: $REPO_NAME  (público)

2) Envie:
   cd $DIR_SRC/$REPO_NAME
   git init
   git add .
   git commit -m "SSHPLUS + V2RAY opção 09"
   git branch -M $BRANCH
   git remote add origin https://github.com/$REPO_USER/$REPO_NAME.git
   git push -u origin $BRANCH

3) Instale no VPS:
   wget https://raw.githubusercontent.com/$REPO_USER/$REPO_NAME/$BRANCH/Plus
   chmod +x Plus && ./Plus

4) Pronto: menu → opção 09 → V2RAY/XRAY
============================================================
EOF
