#!/bin/bash

NOME_REDE=$(nmcli -t -f ACTIVE,NAME connection show | grep '^yes' | cut -d: -f2 | head -n 1)

if [ -z "$NOME_REDE" ]; then
    echo "❌ Erro: Nenhuma conexão ativa encontrada."
    exit 1
fi

function ativar() {
    echo "🌐 Conexão: $NOME_REDE"
    echo "▶️ Ativando IPv6 e resetando DNS..."
    # Volta o IPv6 para automático e remove o DNS fixo do Google
    sudo nmcli connection modify "$NOME_REDE" ipv6.method "auto" ipv4.dns ""
    sudo nmcli connection up "$NOME_REDE"
    echo "✅ Modo Padrão Restaurado."
}

function desativar() {
    echo "🌐 Conexão: $NOME_REDE"
    echo "⏸️ Desativando IPv6 e fixando DNS IPv4 (Google/Cloudflare)..."
    
    # 1. Desativa IPv6
    # 2. Força DNS IPv4 para não perder a navegação (8.8.8.8 e 1.1.1.1)
    sudo nmcli connection modify "$NOME_REDE" ipv6.method "disabled" ipv4.dns "8.8.8.8,1.1.1.1"
    
    sudo nmcli connection up "$NOME_REDE"
    
    echo "⏳ Aguardando sincronização de rede..."
    sleep 2

    if ping -c 2 -4 www.google.com > /dev/null 2>&1; then
        echo "🚀 Sucesso! IPv6 desativado e Internet OK via IPv4."
    else
        echo "⚠️ O Google não respondeu. O seu roteador pode estar bloqueando DNS externo."
    fi
}

case "$1" in
    --on) ativar ;;
    --off) desativar ;;
    *) echo "Uso: $0 {--on|--off}"; exit 1 ;;
esac