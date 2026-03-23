#!/bin/bash

# ==========================================
# HYTALE MOD MANAGER - MENU v2.1
# ==========================================

CONFIG_DIR="$HOME/.config/hytale-mod-manager"
CONFIG_FILE="$CONFIG_DIR/config.txt"
LOG_FILE="$CONFIG_DIR/daemon.log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DAEMON_SCRIPT="$SCRIPT_DIR/daemon.sh"
SERVICE="hytale-mod-manager.service"

C_BLUE="39"
C_GREEN="76"
C_GRAY="244"
C_WHITE="255"
C_RED="196"

if ! command -v gum &>/dev/null; then
    echo "❌ Gum não instalado."
    exit 1
fi

get_mods_dir()  { sed -n '2p' "$CONFIG_FILE" 2>/dev/null | tr -d '[:space:]'; }
get_watch_dir() { sed -n '1p' "$CONFIG_FILE" 2>/dev/null | tr -d '[:space:]'; }

get_status() {
    if systemctl --user is-active --quiet "$SERVICE"; then
        gum style --foreground "$C_GREEN" "● ONLINE"
    else
        gum style --foreground "$C_RED" "● OFFLINE"
    fi
}

get_mods_count() {
    local DIR
    DIR=$(get_mods_dir)
    [ -d "$DIR" ] && ls -A "$DIR" 2>/dev/null | wc -l || echo "?"
}

show_dashboard() {
    clear

    gum style --foreground "$C_BLUE" \
'  ██╗  ██╗██╗   ██╗████████╗ █████╗ ██╗     ███████╗
  ██║  ██║╚██╗ ██╔╝╚══██╔══╝██╔══██╗██║     ██╔════╝
  ███████║ ╚████╔╝    ██║   ███████║██║     █████╗
  ██╔══██║  ╚██╔╝     ██║   ██╔══██║██║     ██╔══╝
  ██║  ██║   ██║      ██║   ██║  ██║███████╗███████╗
  ╚═╝  ╚═╝   ╚═╝      ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝'

    gum style --foreground "$C_GRAY" "  ________________________________________________"
    echo ""

    local STATUS COUNT WATCH MODS
    STATUS=$(get_status)
    COUNT=$(get_mods_count)
    WATCH=$(get_watch_dir || echo "Não configurado")
    MODS=$(get_mods_dir || echo "Não configurado")

    echo -n "  DAEMON: "; echo -n "$STATUS"; echo -n "    MODS: "; gum style --foreground "$C_BLUE" --bold "$COUNT"
    gum style --foreground "$C_GRAY" "  👁️  $WATCH"
    gum style --foreground "$C_GRAY" "  📦 $MODS"

    gum style --foreground "$C_GRAY" "  ________________________________________________"
    echo ""
}

register_service() {
    mkdir -p "$HOME/.config/systemd/user"
    cat > "$HOME/.config/systemd/user/$SERVICE" << EOF
[Unit]
Description=Hytale Mod Manager Daemon
After=graphical-session.target

[Service]
Type=simple
ExecStart=$DAEMON_SCRIPT
Restart=on-failure
RestartSec=5
Environment="DISPLAY=:0"
Environment="DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus"

[Install]
WantedBy=default.target
EOF
    systemctl --user daemon-reload
}

while true; do
    show_dashboard

    OPCAO=$(gum choose \
        --cursor.foreground "$C_GREEN" \
        --item.foreground "$C_GRAY" \
        --selected.foreground "$C_WHITE" \
        "🔍  Ver Logs" \
        "📖  Ajuda & Comandos" \
        "🟢  [sys] Iniciar Daemon" \
        "🔴  [sys] Parar Daemon" \
        "🔵  [sys] Reiniciar Daemon" \
        "📁  [mod] Abrir Pasta de Mods" \
        "🗑️  [mod] Purge" \
        "⚙️  [sys] Configurar Pastas" \
        "🚪  Sair")

    [ $? -ne 0 ] && [ -z "$OPCAO" ] && continue

    case "$OPCAO" in
        "🔍  Ver Logs")
            clear
            gum style --foreground "$C_GRAY" "  ________________________________________________"
            gum style --foreground "$C_BLUE" "  🔍 Ver Logs"
            gum style --foreground "$C_GRAY" "  ________________________________________________"
            echo ""
            tail -n 50 "$LOG_FILE" 2>/dev/null || echo "  ❌ Sem logs ainda."
            echo ""
            gum style --foreground "$C_GRAY" "  ________________________________________________"
            read -rp ""
            ;;

        "📖  Ajuda & Comandos")
            clear
            gum style --foreground "$C_GRAY" "  ________________________________________________"
            gum style --foreground "$C_BLUE" "  📖 Ajuda & Comandos"
            gum style --foreground "$C_GRAY" "  ________________________________________________"
            echo ""
            echo "  hytalemm          → Abre este menu"
            echo "  hytalemm start    → Inicia o daemon"
            echo "  hytalemm stop     → Para o daemon"
            echo "  hytalemm restart  → Reinicia o daemon"
            echo "  hytalemm status   → Status do serviço"
            echo "  hytalemm logs     → Log em tempo real"
            echo "  hytalemm mods     → Abre pasta de mods"
            echo "  hytalemm purge    → Remove todos os mods"
            echo "  hytalemm config   → Configuração"
            echo "  hytalemm help     → Esta ajuda"
            echo ""
            gum style --foreground "$C_GRAY" "  ________________________________________________"
            read -rp ""
            ;;

        "🟢  [sys] Iniciar Daemon")
            systemctl --user start "$SERVICE"
            gum spin --spinner dot --title "  Iniciando..." --title.foreground "$C_BLUE" -- sleep 1
            ;;

        "🔴  [sys] Parar Daemon")
            systemctl --user stop "$SERVICE"
            gum spin --spinner dot --title "  Parando..." --title.foreground "$C_GRAY" -- sleep 1
            ;;

        "🔵  [sys] Reiniciar Daemon")
            systemctl --user restart "$SERVICE"
            gum spin --spinner dot --title "  Reiniciando..." --title.foreground "$C_BLUE" -- sleep 1
            ;;

        "📁  [mod] Abrir Pasta de Mods")
            DIR=$(get_mods_dir)
            if [ -d "$DIR" ]; then
                xdg-open "$DIR" 2>/dev/null || nautilus "$DIR" 2>/dev/null || thunar "$DIR" 2>/dev/null
            else
                gum style --foreground "$C_RED" "  ❌ Pasta de mods não configurada."
                sleep 2
            fi
            ;;

        "🗑️  [mod] Purge")
            DIR=$(get_mods_dir)
            if [ ! -d "$DIR" ]; then
                gum style --foreground "$C_RED" "  ❌ Pasta de mods não configurada."
                sleep 2; continue
            fi
            gum confirm "  ⚠️  Apagar TODOS os mods. Tem certeza?" || continue
            rm -rf "$DIR"/*
            gum style --foreground "$C_GREEN" "  🗑️  Todos os mods removidos."
            sleep 1.5
            ;;

        "⚙️  [sys] Configurar Pastas")
            clear
            gum style --foreground "$C_GRAY" "  ________________________________________________"
            gum style --foreground "$C_BLUE" "  ⚙️  Configurar Pastas"
            gum style --foreground "$C_GRAY" "  ________________________________________________"
            echo ""
            gum style --foreground "$C_WHITE" "  📂 Pasta monitorada:"
            NEW_WATCH=$(gum input --placeholder "/home/usuario/Hytale" --value "$(get_watch_dir)" --width 60)
            [ -z "$NEW_WATCH" ] && continue

            gum style --foreground "$C_WHITE" "  📦 Pasta de mods:"
            NEW_MODS=$(gum input --placeholder "/home/.../.var/app/.../mods" --value "$(get_mods_dir)" --width 60)
            [ -z "$NEW_MODS" ] && continue

            mkdir -p "$CONFIG_DIR"
            printf '%s\n%s\n' "$NEW_WATCH" "$NEW_MODS" > "$CONFIG_FILE"
            mkdir -p "$NEW_WATCH" "$NEW_MODS"
            register_service
            systemctl --user enable --now "$SERVICE" 2>/dev/null
            gum style --foreground "$C_GREEN" "  ✅ Configurado!"
            sleep 1.5
            ;;

        "🚪  Sair")
            clear; exit 0
            ;;
    esac
done
