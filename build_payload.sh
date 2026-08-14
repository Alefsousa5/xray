#!/bin/bash
# ====================================================
# build_payload.sh — GERA O INSTALADOR Plus ATUALIZADO
# Embuti o modulo v2rayx + menu (opção 09) no Plus
# Uso: ./build_payload.sh
# ====================================================
cd "$(dirname "$0")"

# 1) cria o payload (tar.gz com o modulo e o menu)
mkdir -p /tmp/payload_v2rayx
cp Modulos/v2rayx /tmp/payload_v2rayx/v2rayx
cp Install/Skin_Plus/menuV3/menu /tmp/payload_v2rayx/menu
cd /tmp/payload_v2rayx
tar czf /tmp/payload_v2rayx.tar.gz v2rayx menu
cd - > /dev/null

# 2) base64 do payload
B64=$(base64 -w0 /tmp/payload_v2rayx.tar.gz)

# 3) injeta no Plus_base
sed "s|^__PAYLOAD__$|${B64}|" _build/Plus_base > Plus
chmod +x Plus

rm -rf /tmp/payload_v2rayx /tmp/payload_v2rayx.tar.gz

echo "=== Plus gerado ==="
ls -la Plus
echo "Tamanho do payload: ${#B64} caracteres"
bash -n Plus && echo "Sintaxe OK"
