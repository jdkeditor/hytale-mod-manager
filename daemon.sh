#!/bin/bash

# ==========================================
# HYTALE MOD MANAGER - DAEMON v2.1
# ==========================================

WATCH_DIR=$(sed -n '1p' "$HOME/.config/hytale-mod-manager/config.txt" | tr -d '[:space:]')
MODS_DIR=$(sed -n '2p'  "$HOME/.config/hytale-mod-manager/config.txt" | tr -d '[:space:]')
LOG_FILE="$HOME/.config/hytale-mod-manager/daemon.log"

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"; }

notify_user() {
    (paplay /usr/share/sounds/freedesktop/stereo/complete.oga \
     || aplay /usr/share/sounds/alsa/Front_Center.wav) 2>/dev/null &
    notify-send "Hytale Mod Manager" "$1" -i "${2:-package-x-generic}" 2>/dev/null
}

log "🟢 Daemon v2.1 iniciado."
log "   📂 Monitorando : $WATCH_DIR"
log "   📦 Instalando  : $MODS_DIR"
log "👁️  Monitoramento ativo..."

inotifywait -m -q -e close_write,moved_to --format '%f' "$WATCH_DIR" | while IFS= read -r FILE; do

    [[ "$FILE" =~ \.(crdownload|part|tmp)$ ]] && continue

    FULL_PATH="$WATCH_DIR/$FILE"
    [ ! -f "$FULL_PATH" ] && continue

    case "$FILE" in
        *.jar|*.JAR)
            log "📦 JAR detectado: $FILE"
            mv "$FULL_PATH" "$MODS_DIR/"
            log "✅ Instalado: $FILE"
            notify_user "✅ Mod instalado: $FILE"
            ;;

        *.zip|*.ZIP)
            log "📦 ZIP detectado: $FILE"
            MOD_NAME="${FILE%.*}"
            TARGET="$MODS_DIR/$MOD_NAME"
            rm -rf "$TARGET"
            mkdir -p "$TARGET"
            if unzip -o -q "$FULL_PATH" -d "$TARGET"; then
                rm -f "$FULL_PATH"
                log "✅ Instalado: $MOD_NAME"
                notify_user "✅ Mod instalado: $MOD_NAME"
            else
                rm -rf "$TARGET"
                log "❌ Erro ao extrair: $FILE"
                notify_user "❌ Erro ao instalar: $FILE" "dialog-error"
            fi
            ;;

        *.7z|*.7Z)
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
                notify_user "✅ Mod instalado: $MOD_NAME"
            else
                rm -rf "$TARGET"
                log "❌ Erro ao extrair: $FILE"
                notify_user "❌ Erro ao instalar: $FILE" "dialog-error"
            fi
            ;;
    esac
done
