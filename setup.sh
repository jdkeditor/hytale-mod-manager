#!/bin/bash

# ==============================================================================
# 🎮 HYTALE MANAGER - V12 (GREEN LOGS EDITION)
# ==============================================================================

# --- CONFIGURAÇÃO ---
CONFIG_DIR="$HOME/.config/hytale-mod-installer"
CONFIG_FILE="$CONFIG_DIR/config.txt"
LOG_FILE="$HOME/.config/hytale-mod-installer/watcher.log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DAEMON_SCRIPT="$SCRIPT_DIR/daemon.sh"

# Cores Hytale
C_BLUE="39"   # Magia/Céu
C_GREEN="76"  # Grama/Kweebec
C_GRAY="244"  # Pedra
C_WHITE="255" # UI

# Verifica Gum
if ! command -v gum &> /dev/null; then
    echo "❌ Gum não instalado."
    exit 1
fi

# --- FUNÇÕES VISUAIS ---

get_status() {
    if systemctl --user is-active --quiet hytale-mod-installer.service; then
        gum style --foreground "$C_GREEN" "● ONLINE"
    else
        gum style --foreground 196 "● OFFLINE"
    fi
}

get_mods_count() {
    if [ -f "$CONFIG_FILE" ]; then
        DIR=$(cat "$CONFIG_FILE")
        if [ -d "$DIR" ]; then
            CNT=$(ls -A "$DIR" 2>/dev/null | wc -l)
            gum style --foreground "$C_BLUE" --bold "$CNT Mods"
        else
            echo "0"
        fi
    else
        echo "?"
    fi
}

show_dashboard() {
    clear
    STATUS=$(get_status)
    COUNT=$(get_mods_count)
    DIR=$(cat "$CONFIG_FILE" 2>/dev/null || echo "Não configurado")
    
    gum style \
        --border double --border-foreground "$C_BLUE" --padding "1 2" --margin "1 0" \
        --align center --width 60 \
        "⚔️  HYTALE MOD MANAGER" "" \
        "DAEMON: $STATUS  |  INSTALADOS: $COUNT"
        
    gum style --foreground "$C_GRAY" --align center --width 60 "📂 $DIR"
    echo ""
}

create_shortcuts() {
    gum spin --spinner globe --title "Criando comando 'hytalemm'..." --title.foreground "$C_BLUE" -- sleep 1
    
    # 1. Comando Global (hytalemm)
    COMMAND_FILE="/usr/local/bin/hytalemm"
    
    cat > /tmp/hytalemm << EOFCMD
#!/bin/bash
SCRIPT_DIR="$SCRIPT_DIR"
LOG_FILE="$LOG_FILE"

case "\${1:-menu}" in
    setup|config) cd "\$SCRIPT_DIR" && ./setup.sh ;;
    logs|log)     [ -f "\$LOG_FILE" ] && tail -f "\$LOG_FILE" || echo "❌ Sem logs" ;;
    status)       systemctl --user status hytale-mod-installer.service ;;
    start)        systemctl --user start hytale-mod-installer.service && echo "✅ Iniciado" ;;
    stop)         systemctl --user stop hytale-mod-installer.service && echo "🛑 Parado" ;;
    restart)      systemctl --user restart hytale-mod-installer.service && echo "🔄 Reiniciado" ;;
    help|--help)  
        echo "🎮 Comandos do Hytalemm:"
        echo "  hytalemm          -> Abre o menu interativo"
        echo "  hytalemm start    -> Inicia o daemon"
        echo "  hytalemm stop     -> Para o daemon"
        echo "  hytalemm logs     -> Vê os logs"
        ;;
    menu|*)       cd "\$SCRIPT_DIR" && ./setup.sh ;;
esac
EOFCMD

    if sudo mv /tmp/hytalemm "$COMMAND_FILE" && sudo chmod +x "$COMMAND_FILE"; then
        gum style --foreground "$C_GREEN" "✅ Comando 'hytalemm' criado!"
    else
        gum style --foreground 196 "⚠ Erro ao criar comando (precisa de sudo)"
    fi

    # 2. Atalho Desktop
    gum spin --spinner globe --title "Criando ícone no Menu..." --title.foreground "$C_BLUE" -- sleep 1
    
    DESKTOP_FILE="$HOME/.local/share/applications/hytale-mod-manager.desktop"
    mkdir -p "$HOME/.local/share/applications"
    
    cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Hytale Mod Manager
Comment=Gerenciador de Mods
Exec=gnome-terminal --title="Hytale Mod Manager" -- bash -c '$SCRIPT_DIR/setup.sh; exec bash'
Icon=utilities-terminal
Terminal=false
Categories=Game;Utility;
EOF
    
    chmod +x "$DESKTOP_FILE"
    gum style --foreground "$C_GREEN" "✅ Ícone criado no menu de apps!"
    sleep 2
}

# --- MENU PRINCIPAL ---
while true; do
    show_dashboard
    
    OPCAO=$(gum choose --timeout 5s --cursor.foreground "$C_GREEN" --item.foreground "$C_GRAY" --selected.foreground "$C_WHITE" \
        "👁️   Modo Monitor (Ao Vivo)" \
        "💾   Criar Backup" \
        "♻️   Restaurar Backup" \
        "⚙️   Configurar Pasta" \
        "🔗   Recriar Atalhos/Comandos" \
        "❓   Ajuda & Comandos" \
        "📜   Ver Logs" \
        "▶️   Iniciar Daemon" \
        "⏸️   Parar Daemon" \
        "❌   Sair")

    STATUS_EXIT=$?
    if [ $STATUS_EXIT -ne 0 ] && [ -z "$OPCAO" ]; then continue; fi

    case "$OPCAO" in
        "👁️   Modo Monitor (Ao Vivo)")
            watch -n 1 --color "
                echo '⚔️  HYTALE LIVE MONITOR ⚔️';
                echo '-------------------------';
                echo '🕒 \$(date)';
                echo '';
                echo '⚙️ Status: \$(systemctl --user is-active hytale-mod-installer.service)';
                echo '';
                echo '📦 Últimas ações:';
                tail -n 10 $LOG_FILE;
                echo '';
                echo 'CTRL+C para voltar.';
            "
            ;;
            
        "💾   Criar Backup")
            MODS_DIR=$(cat "$CONFIG_FILE")
            gum confirm "Criar backup de todos os mods?" && {
                mkdir -p "$HOME/Hytale_Backups"
                
                TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
                FILENAME="HYTALEMM_BACKUP_$TIMESTAMP.tar.gz"
                FILE="$HOME/Hytale_Backups/$FILENAME"
                
                gum spin --spinner globe --title "Compactando..." --title.foreground "$C_BLUE" -- tar -czf "$FILE" -C "$MODS_DIR" .
                
                gum style --foreground "$C_GREEN" "✅ Backup Salvo com Sucesso!"
                echo ""
                gum style --foreground "$C_WHITE" "📁 Nome: $FILENAME"
                gum style --foreground "$C_GRAY"  "📍 Local: $HOME/Hytale_Backups/"
                echo ""
                gum style --foreground "$C_GRAY" "Pressione ENTER..."
                read
            }
            ;;
            
        "♻️   Restaurar Backup")
            BACKUP_DIR="$HOME/Hytale_Backups"
            if [ -d "$BACKUP_DIR" ]; then
                FILE=$(ls "$BACKUP_DIR" | gum choose --header "Escolha o backup:" --cursor.foreground "$C_BLUE")
                if [ -n "$FILE" ]; then
                    gum confirm "Isso apaga os mods atuais. Restaurar?" && {
                        DEST=$(cat "$CONFIG_FILE")
                        rm -rf "$DEST"/*
                        gum spin --spinner globe --title "Restaurando..." --title.foreground "$C_BLUE" -- tar -xzf "$BACKUP_DIR/$FILE" -C "$DEST"
                        gum style --foreground "$C_GREEN" "✅ Restaurado!"
                        sleep 1.5
                    }
                fi
            else
                gum style --foreground 196 "Sem backups."
                sleep 1.5
            fi
            ;;
            
        "⚙️   Configurar Pasta")
            CURRENT=$(cat "$CONFIG_FILE" 2>/dev/null)
            gum style --foreground "$C_BLUE" "📂 Cole o caminho da pasta:"
            NEW_DIR=$(gum input --placeholder "/home/..." --value "$CURRENT" --width 60)
            if [ -n "$NEW_DIR" ]; then
                mkdir -p "$CONFIG_DIR"
                echo "$NEW_DIR" > "$CONFIG_FILE"
                
                mkdir -p "$HOME/.config/systemd/user"
                cat > "$HOME/.config/systemd/user/hytale-mod-installer.service" << EOF
[Unit]
Description=Hytale Mod Installer
After=graphical-session.target
[Service]
Type=simple
ExecStart=$DAEMON_SCRIPT
Restart=always
Environment="DISPLAY=:0"
Environment="DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus"
[Install]
WantedBy=default.target
EOF
                systemctl --user daemon-reload
                systemctl --user enable --now hytale-mod-installer.service
                gum style --foreground "$C_GREEN" "✅ Configurado!"
                sleep 1
            fi
            ;;
            
        "🔗   Recriar Atalhos/Comandos")
             create_shortcuts
             ;;
             
        "❓   Ajuda & Comandos")
             clear
             gum style --foreground "$C_BLUE" --border double --padding "1 2" "📖 MANUAL DE COMANDOS"
             echo ""
             gum style --foreground "$C_WHITE" "Você pode usar o comando 'hytalemm' no terminal:"
             echo ""
             echo "  hytalemm          → Abre este menu"
             echo "  hytalemm start    → Inicia o monitoramento"
             echo "  hytalemm stop     → Para o monitoramento"
             echo "  hytalemm logs     → Mostra o histórico"
             echo ""
             gum style --foreground "$C_GRAY" "Pressione ENTER para voltar..."
             read
             ;;
            
        "📜   Ver Logs")
            if [ -f "$LOG_FILE" ]; then
                gum style --foreground "$C_BLUE" "📜 Use as setas para rolar e 'Q' para sair."
                
                # --- AQUI ESTÁ A MÁGICA ---
                # Adicionei --border-foreground e --foreground para ficar VERDE
                tail -n 100 "$LOG_FILE" | gum pager \
                    --border double \
                    --border-foreground "$C_GREEN" \
                    --foreground "$C_GREEN" \
                    --padding "0 2"
            else
                gum style --foreground 196 "❌ Arquivo de log ainda não existe."
                sleep 2
            fi
            ;;
            
        "▶️   Iniciar Daemon")
            systemctl --user start hytale-mod-installer.service
            gum spin --spinner dot --title "Invocando..." --title.foreground "$C_BLUE" -- sleep 1
            ;;
            
        "⏸️   Parar Daemon")
            systemctl --user stop hytale-mod-installer.service
            gum spin --spinner dot --title "Parando..." --title.foreground "$C_GRAY" -- sleep 1
            ;;
            
        "❌   Sair")
            clear
            exit 0
            ;;
    esac
done
