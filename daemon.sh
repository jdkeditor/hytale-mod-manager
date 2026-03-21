#!/bin/bash

# ==============================================================================
# ⚔️  HYTALE MOD MANAGER - DAEMON v2.0
# ==============================================================================

CONFIG_DIR="$HOME/.config/hytale-mod-manager"
CONFIG_FILE="$CONFIG_DIR/config.txt"
LOG_FILE="$CONFIG_DIR/daemon.log"

mkdir -p "$CONFIG_DIR"
touch "$LOG_FILE"

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"; }

notify_user() {
    local TITLE="$1" MSG="$2" ICON="${3:-package-x-generic}"
    (paplay /usr/share/sounds/freedesktop/stereo/complete.oga \
     || aplay /usr/share/sounds/alsa/Front_Center.wav) 2>/dev/null &
    notify-send "$TITLE" "$MSG" -i "$ICON" 2>/dev/null
}

if [ ! -f "$CONFIG_FILE" ]; then
    log "❌ Configuração não encontrada: $CONFIG_FILE"
    exit 1
fi

WATCH_DIR=$(sed -n '1p' "$CONFIG_FILE" | tr -d '[:space:]')
MODS_DIR=$(sed -n '2p'  "$CONFIG_FILE" | tr -d '[:space:]')
MODS_DIR="${MODS_DIR:-$WATCH_DIR}"

if [ ! -d "$WATCH_DIR" ]; then
    log "❌ Pasta monitorada não existe: $WATCH_DIR"
    exit 1
fi

mkdir -p "$MODS_DIR"

log "🟢 Daemon v2.0 iniciado."
log "   📂 Monitorando : $WATCH_DIR"
log "   📦 Instalando  : $MODS_DIR"
log "👁️  Monitoramento ativo..."

if ! command -v inotifywait &>/dev/null; then
    log "❌ FATAL: inotify-tools não encontrado."
    exit 1
fi

inotifywait -m -q -e close_write,moved_to --format '%f' "$WATCH_DIR" \
| while IFS= read -r FILE; do

    [[ "$FILE" =~ \.(crdownload|part|tmp|download)$ ]] && continue

    FULL_PATH="$WATCH_DIR/$FILE"
    [ ! -f "$FULL_PATH" ] && continue

    case "${FILE,,}" in
        *.jar)
            log "📦 JAR detectado: $FILE"
            mv "$FULL_PATH" "$MODS_DIR/"
            log "✅ Instalado: $FILE"
            notify_user "Hytale Mod Manager" "✅ Mod instalado: $FILE"
            ;;

        *.zip)
            log "📦 ZIP detectado: $FILE"
            MOD_NAME="${FILE%.*}"
            TARGET="$MODS_DIR/$MOD_NAME"
            rm -rf "$TARGET"
            mkdir -p "$TARGET"
            if unzip -o -q "$FULL_PATH" -d "$TARGET"; then
                rm -f "$FULL_PATH"
                log "✅ Instalado: $MOD_NAME"
                notify_user "Hytale Mod Manager" "✅ Mod instalado: $MOD_NAME"
            else
                rm -rf "$TARGET"
                log "❌ Erro ao extrair: $FILE"
                notify_user "Hytale Mod Manager" "❌ Erro ao instalar: $FILE" "dialog-error"
            fi
            ;;

        *.7z)
            if ! command -v 7z &>/dev/null; then
                log "❌ p7zip não instalado. Rode: sudo pacman -S p7zip"
                continue
            fi
            log "📦 7z detectado: $FILE"
            MOD_NAME="${FILE%.*}"
            TARGET="$MODS_DIR/$MOD_NAME"
            rm -rf "$TARGET"
            mkdir -p "$TARGET"
            if 7z x -y -o"$TARGET" "$FULL_PATH" &>/dev/null; then
                rm -f "$FULL_PATH"
                log "✅ Instalado: $MOD_NAME"
                notify_user "Hytale Mod Manager" "✅ Mod instalado: $MOD_NAME"
            else
                rm -rf "$TARGET"
                log "❌ Erro ao extrair: $FILE"
                notify_user "Hytale Mod Manager" "❌ Erro ao instalar: $FILE" "dialog-error"
            fi
            ;;
    esac
done
