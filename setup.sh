#!/bin/bash

# ==============================================================================
# ⚔️  HYTALE MOD MANAGER - SETUP v2.0
# ==============================================================================

CONFIG_DIR="$HOME/.config/hytale-mod-manager"
CONFIG_FILE="$CONFIG_DIR/config.txt"
LOG_FILE="$CONFIG_DIR/daemon.log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DAEMON_SCRIPT="$SCRIPT_DIR/daemon.sh"
SERVICE="hytale-mod-manager.service"

# Cores Hytale
C_BLUE="39"
C_GREEN="76"
C_GRAY="244"
C_WHITE="255"
C_RED="196"

# Verifica Gum
if ! command -v gum &>/dev/null; then
    echo "❌ Gum não instalado. Instale em: https://github.com/charmbracelet/gum"
    exit 1
fi

# --- HELPERS ---

get_mods_dir() {
    sed -n '2p' "$CONFIG_FILE" 2>/dev/null | tr -d '[:space:]'
}

get_watch_dir() {
    sed -n '1p' "$CONFIG_FILE" 2>/dev/null | tr -d '[:space:]'
}

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
    if [ -d "$DIR" ]; then
        ls -A "$DIR" 2>/dev/null | wc -l
    else
        echo "?"
    fi
}

show_dashboard() {
    clear
    local STATUS COUNT WATCH MODS
    STATUS=$(get_status)
    COUNT=$(get_mods_count)
    WATCH=$(get_watch_dir || echo "Não configurado")
    MODS=$(get_mods_dir || echo "Não configurado")

    gum style \
        --border double --border-foreground "$C_BLUE" \
        --padding "1 2" --margin "1 0" \
        --align center --width 60 \
        "⚔️   HYTALE MOD MANAGER v2.0" "" \
        "DAEMON: $STATUS  |  MODS: $(gum style --foreground "$C_BLUE" --bold "$COUNT")"

    gum style --foreground "$C_GRAY" --align center --width 60 "👁️  $WATCH"
    gum style --foreground "$C_GRAY" --align center --width 60 "📦 $MODS"
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

create_command() {
    local CMD_FILE="/usr/local/bin/hytalemm"

    cat > /tmp/hytalemm_install << EOFCMD
#!/bin/bash
# ⚔️  hytalemm — Hytale Mod Manager
CONFIG_FILE="$CONFIG_FILE"
LOG_FILE="$LOG_FILE"
SERVICE="$SERVICE"
SCRIPT_DIR="$SCRIPT_DIR"

get_mods_dir() { sed -n '2p' "\$CONFIG_FILE" 2>/dev/null | tr -d '[:space:]'; }

case "\${1:-menu}" in
    start)
        systemctl --user start "\$SERVICE" && echo "▶️  Daemon iniciado."
        ;;
    stop)
        systemctl --user stop "\$SERVICE" && echo "⏸️  Daemon parado."
        ;;
    restart)
        systemctl --user restart "\$SERVICE" && echo "🔄 Daemon reiniciado."
        ;;
    status)
        systemctl --user status "\$SERVICE"
        ;;
    logs)
        [ -f "\$LOG_FILE" ] && tail -f "\$LOG_FILE" || echo "❌ Sem logs ainda."
        ;;
    mods)
        DIR=\$(get_mods_dir)
        if [ -d "\$DIR" ]; then
            xdg-open "\$DIR" 2>/dev/null || nautilus "\$DIR" 2>/dev/null || thunar "\$DIR" 2>/dev/null || echo "📂 \$DIR"
        else
            echo "❌ Pasta de mods não configurada."
        fi
        ;;
    purge)
        DIR=\$(get_mods_dir)
        if [ ! -d "\$DIR" ]; then
            echo "❌ Pasta de mods não configurada."
            exit 1
        fi
        echo ""
        echo "⚠️  Isso vai apagar TODOS os mods em:"
        echo "   \$DIR"
        echo ""
        read -rp "   Tem certeza? [s/N] " CONFIRM
        if [[ "\$CONFIRM" =~ ^[sS]$ ]]; then
            rm -rf "\$DIR"/*
            echo "🗑️  Todos os mods foram removidos."
        else
            echo "❌ Cancelado."
        fi
        ;;
    config)
        cd "\$SCRIPT_DIR" && ./setup.sh
        ;;
    help|--help|-h)
        echo ""
        echo "  ⚔️  hytalemm — Hytale Mod Manager"
        echo ""
        echo "  Uso: hytalemm [comando]"
        echo ""
        echo "  Comandos:"
        echo "    (vazio)     → Abre o menu interativo"
        echo "    start       → Inicia o daemon"
        echo "    stop        → Para o daemon"
        echo "    restart     → Reinicia o daemon"
        echo "    status      → Status do serviço"
        echo "    logs        → Log em tempo real"
        echo "    mods        → Abre pasta de mods no gerenciador de arquivos"
        echo "    purge       → Remove TODOS os mods (pede confirmação)"
        echo "    config      → Abre menu de configuração"
        echo "    help        → Mostra esta ajuda"
        echo ""
        ;;
    menu|*)
        cd "\$SCRIPT_DIR" && ./setup.sh
        ;;
esac
EOFCMD

    if sudo mv /tmp/hytalemm_install "$CMD_FILE" && sudo chmod +x "$CMD_FILE"; then
        gum style --foreground "$C_GREEN" "✅ Comando 'hytalemm' criado!"
    else
        gum style --foreground "$C_RED" "⚠️  Erro ao criar comando (precisa de sudo)"
    fi
}

create_desktop() {
    local DESKTOP_FILE="$HOME/.local/share/applications/hytale-mod-manager.desktop"
    mkdir -p "$HOME/.local/share/applications"
    cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Hytale Mod Manager
Comment=Gerenciador de Mods para Hytale
Exec=gnome-terminal --title="Hytale Mod Manager" -- bash -c '$SCRIPT_DIR/setup.sh; exec bash'
Icon=utilities-terminal
Terminal=false
Categories=Game;Utility;
EOF
    chmod +x "$DESKTOP_FILE"
    gum style --foreground "$C_GREEN" "✅ Atalho criado no menu de apps!"
}

# ==============================================================================
# MENU PRINCIPAL
# ==============================================================================
while true; do
    show_dashboard

    OPCAO=$(gum choose \
        --cursor.foreground "$C_GREEN" \
        --item.foreground "$C_GRAY" \
        --selected.foreground "$C_WHITE" \
        "👁️   Modo Monitor (Ao Vivo)" \
        "💾   Criar Backup" \
        "♻️   Restaurar Backup" \
        "⚙️   Configurar Pastas" \
        "🔗   Recriar Atalhos/Comandos" \
        "❓   Ajuda & Comandos" \
        "📜   Ver Logs" \
        "▶️   Iniciar Daemon" \
        "⏸️   Parar Daemon" \
        "❌   Sair")

    [ $? -ne 0 ] && [ -z "$OPCAO" ] && continue

    case "$OPCAO" in
        "👁️   Modo Monitor (Ao Vivo)")
            watch -n 1 --color "
                echo '⚔️  HYTALE LIVE MONITOR';
                echo '-------------------------';
                echo \"🕒 \$(date)\";
                echo '';
                echo \"⚙️  Status: \$(systemctl --user is-active $SERVICE)\";
                echo '';
                echo '📦 Últimas ações:';
                tail -n 10 $LOG_FILE 2>/dev/null || echo 'Sem logs ainda.';
                echo '';
                echo 'CTRL+C para voltar.';
            "
            ;;

        "💾   Criar Backup")
            MODS=$(get_mods_dir)
            if [ ! -d "$MODS" ]; then
                gum style --foreground "$C_RED" "❌ Pasta de mods não configurada."
                sleep 2; continue
            fi
            gum confirm "Criar backup de todos os mods?" || continue
            mkdir -p "$HOME/Hytale_Backups"
            TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
            FILENAME="HYTALEMM_BACKUP_$TIMESTAMP.tar.gz"
            FILEPATH="$HOME/Hytale_Backups/$FILENAME"
            gum spin --spinner globe --title "Compactando..." --title.foreground "$C_BLUE" \
                -- tar -czf "$FILEPATH" -C "$MODS" .
            gum style --foreground "$C_GREEN" "✅ Backup salvo!"
            echo ""
            gum style --foreground "$C_WHITE" "📁 $FILENAME"
            gum style --foreground "$C_GRAY"  "📍 $HOME/Hytale_Backups/"
            echo ""
            gum style --foreground "$C_GRAY" "Pressione ENTER..."
            read -r
            ;;

        "♻️   Restaurar Backup")
            BACKUP_DIR="$HOME/Hytale_Backups"
            if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
                gum style --foreground "$C_RED" "❌ Nenhum backup encontrado."
                sleep 2; continue
            fi
            FILE=$(ls "$BACKUP_DIR" | gum choose --header "Escolha o backup:")
            [ -z "$FILE" ] && continue
            gum confirm "Isso apaga os mods atuais. Restaurar '$FILE'?" || continue
            DEST=$(get_mods_dir)
            rm -rf "$DEST"/*
            gum spin --spinner globe --title "Restaurando..." --title.foreground "$C_BLUE" \
                -- tar -xzf "$BACKUP_DIR/$FILE" -C "$DEST"
            gum style --foreground "$C_GREEN" "✅ Restaurado!"
            sleep 1.5
            ;;

        "⚙️   Configurar Pastas")
            gum style --foreground "$C_BLUE" "📂 Pasta monitorada (onde você baixa os mods):"
            CURRENT_WATCH=$(get_watch_dir)
            NEW_WATCH=$(gum input --placeholder "/home/usuario/Hytale" --value "$CURRENT_WATCH" --width 60)
            [ -z "$NEW_WATCH" ] && continue

            gum style --foreground "$C_BLUE" "📦 Pasta de mods do Hytale:"
            CURRENT_MODS=$(get_mods_dir)
            NEW_MODS=$(gum input --placeholder "/home/.../.var/app/.../mods" --value "$CURRENT_MODS" --width 60)
            [ -z "$NEW_MODS" ] && continue

            mkdir -p "$CONFIG_DIR"
            printf '%s\n%s\n' "$NEW_WATCH" "$NEW_MODS" > "$CONFIG_FILE"
            mkdir -p "$NEW_WATCH" "$NEW_MODS"

            register_service
            systemctl --user enable --now "$SERVICE" 2>/dev/null
            gum style --foreground "$C_GREEN" "✅ Configurado e daemon reiniciado!"
            sleep 1.5
            ;;

        "🔗   Recriar Atalhos/Comandos")
            gum spin --spinner globe --title "Criando comando 'hytalemm'..." --title.foreground "$C_BLUE" -- sleep 1
            create_command
            gum spin --spinner globe --title "Criando atalho no menu..." --title.foreground "$C_BLUE" -- sleep 1
            create_desktop
            sleep 2
            ;;

        "❓   Ajuda & Comandos")
            clear
            gum style --foreground "$C_BLUE" --border double --padding "1 2" "📖 COMANDOS DO HYTALEMM"
            echo ""
            gum style --foreground "$C_WHITE" "Use 'hytalemm [comando]' no terminal:"
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
            gum style --foreground "$C_GRAY" "Pressione ENTER para voltar..."
            read -r
            ;;

        "📜   Ver Logs")
            if [ -f "$LOG_FILE" ]; then
                tail -n 100 "$LOG_FILE" | gum pager \
                    --border double \
                    --border-foreground "$C_GREEN" \
                    --foreground "$C_GREEN" \
                    --padding "0 2"
            else
                gum style --foreground "$C_RED" "❌ Sem logs ainda."
                sleep 2
            fi
            ;;

        "▶️   Iniciar Daemon")
            systemctl --user start "$SERVICE"
            gum spin --spinner dot --title "Iniciando..." --title.foreground "$C_BLUE" -- sleep 1
            ;;

        "⏸️   Parar Daemon")
            systemctl --user stop "$SERVICE"
            gum spin --spinner dot --title "Parando..." --title.foreground "$C_GRAY" -- sleep 1
            ;;

        "❌   Sair")
            clear; exit 0
            ;;
    esac
done
