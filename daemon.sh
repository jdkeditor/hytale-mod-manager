#!/bin/bash

# ==============================================================================
# 🤖 HYTALE DAEMON - BACKEND V1.0
# ==============================================================================

# Configurações
CONFIG_DIR="$HOME/.config/hytale-mod-manager"
CONFIG_FILE="$CONFIG_DIR/config.txt"
LOG_FILE="$CONFIG_DIR/daemon.log"

# Garante diretórios
mkdir -p "$CONFIG_DIR"
touch "$LOG_FILE"

# Função de Log
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"; }

# Verifica Configuração
if [ ! -f "$CONFIG_FILE" ]; then
    log "❌ Erro: Configuração não encontrada."
    exit 1
fi

WATCH_DIR=$(cat "$CONFIG_FILE")
log "🟢 Daemon iniciado. Monitorando: $WATCH_DIR"

# Função de Som e Notificação
notify_user() {
    TITLE="$1"
    MSG="$2"
    ICON="$3"
    
    # Toca som (tenta vários players comuns)
    (paplay /usr/share/sounds/freedesktop/stereo/complete.oga || \
     aplay /usr/share/sounds/alsa/Front_Center.wav) 2>/dev/null &
     
    # Envia notificação
    notify-send "$TITLE" "$MSG" -i "$ICON" 2>/dev/null
}

process_file() {
    FILE="$1"
    # Delay de segurança para download terminar
    sleep 1
    
    cd "$WATCH_DIR" || return
    [ ! -f "$FILE" ] && return

    log "📦 Processando arquivo: $FILE"
    
    EXT="${FILE##*.}"
    EXT_LOWER=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')

    case "$EXT_LOWER" in
           zip)
                # --- FIX v1.0.3: CONTENÇÃO DE ARQUIVOS ---
                # 1. Pega o nome do Mod limpo (ex: "MeuMod.zip" vira "MeuMod")
                MOD_NAME=$(basename "$FILE" .zip)
                
                # Define onde vai instalar (Usa o diretório atual onde o script está operando)
                TARGET_DIR="./$MOD_NAME"

                # 2. Se a pasta já existe, apaga a velha pra atualizar (Clean Install)
                if [ -d "$TARGET_DIR" ]; then
                    log "🔄 Atualizando mod: $MOD_NAME (Versão antiga removida)"
                    rm -rf "$TARGET_DIR"
                fi

                # 3. Cria a pasta "cofre" para o mod
                mkdir -p "$TARGET_DIR"

                # 4. O PULO DO GATO: Extrai com -d para DENTRO da pasta criada
                if unzip -o -q "$FILE" -d "$TARGET_DIR"; then
                    rm -f "$FILE"
                    log "✅ ZIP Instalado e organizado: $MOD_NAME/"
                    notify_user "Hytale Mod Manager" "Mod instalado: $MOD_NAME" "package-x-generic"
                else
                    log "⚠️ Erro ao extrair ZIP: $FILE"
                    # Se falhar, apaga a pasta vazia pra não deixar lixo
                    rm -rf "$TARGET_DIR"
                fi
                ;;
            
        jar)
            # JARs são apenas mantidos (Java Mods)
            log "✅ JAR detectado e mantido: $FILE"
            notify_user "Hytale Mod Manager" "Java Mod detectado: $FILE" "java"
            ;;
            
        7z)
            if command -v 7z &> /dev/null; then
                # 7z não tem listagem simples igual unzip, extrai direto
                if 7z x -y "$FILE" > /dev/null; then
                    rm -f "$FILE"
                    log "✅ 7z Instalado com sucesso: $FILE"
                    notify_user "Hytale Mod Manager" "Mod 7z instalado: $FILE" "package-x-generic"
                else
                    log "⚠️ Erro ao extrair 7z: $FILE"
                fi
            else
                log "❌ Erro: 'p7zip' não instalado para abrir .7z"
            fi
            ;;
    esac
}

# Verifica inotify
if ! command -v inotifywait &> /dev/null; then
    log "❌ FATAL: inotify-tools não encontrado."
    exit 1
fi

# Loop de Monitoramento
# Monitora close_write (download terminou) e moved_to (arquivo movido para pasta)
inotifywait -m -e close_write -e moved_to --format "%f" "$WATCH_DIR" | \
while read FILENAME; do
    if [[ "$FILENAME" =~ \.(zip|jar|7z)$ ]]; then
        process_file "$FILENAME"
    fi
done
