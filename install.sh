#!/bin/bash

# ==========================================
# HYTALE MOD MANAGER - INSTALADOR v2.1
# ==========================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
GRAY='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}✅ $1${NC}"; }
err()  { echo -e "  ${RED}❌ $1${NC}"; }
info() { echo -e "  ${GRAY}   $1${NC}"; }

clear
echo -e "${BLUE}${BOLD}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║     ⚔️   HYTALE MOD MANAGER v2.1        ║"
echo "  ║          Instalador Automático           ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  Pressione ENTER para continuar ou Ctrl+C para cancelar."
read -r

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/hytale-mod-manager"
CONFIG_FILE="$CONFIG_DIR/config.txt"
LOG_FILE="$CONFIG_DIR/daemon.log"
SERVICE="hytale-mod-manager.service"

# --- DEPENDÊNCIAS ---
echo ""
echo -e "${BOLD}[1] Verificando dependências${NC}"
DEPS=(inotify-tools unzip libnotify)
MISSING=()
for DEP in "${DEPS[@]}"; do
    if ! pacman -Qi "$DEP" &>/dev/null; then
        MISSING+=("$DEP")
    else
        ok "$DEP"
    fi
done
if [ ${#MISSING[@]} -gt 0 ]; then
    info "Instalando: ${MISSING[*]}"
    sudo pacman -S --noconfirm "${MISSING[@]}"
    ok "Dependências instaladas!"
fi

# --- PERMISSÕES ---
echo ""
echo -e "${BOLD}[2] Aplicando permissões${NC}"
chmod +x "$SCRIPT_DIR/daemon.sh" "$SCRIPT_DIR/setup.sh"
ok "Permissões aplicadas."

# --- CONFIG ---
echo ""
echo -e "${BOLD}[3] Configurando pastas${NC}"
mkdir -p "$CONFIG_DIR"
touch "$LOG_FILE"

DEFAULT_WATCH="$HOME/Downloads"
echo ""
echo -e "  ${BOLD}📂 Pasta monitorada (onde você baixa os mods):${NC}"
echo -e "  ${GRAY}Padrão: $DEFAULT_WATCH${NC}"
echo -n "  → ENTER para usar o padrão ou digite outro caminho: "
read -r INPUT_WATCH
WATCH_DIR="${INPUT_WATCH:-$DEFAULT_WATCH}"
mkdir -p "$WATCH_DIR"
ok "Pasta monitorada: $WATCH_DIR"

DEFAULT_MODS="$HOME/.var/app/com.hypixel.HytaleLauncher/data/Hytale/UserData/Saves"
echo ""
echo -e "  ${BOLD}📦 Pasta de mods do Hytale:${NC}"
echo -e "  ${GRAY}Ex: $DEFAULT_MODS/NomeMundo/mods${NC}"
echo -n "  → Digite o caminho completo: "
read -r INPUT_MODS
MODS_DIR="${INPUT_MODS:-$DEFAULT_MODS}"
mkdir -p "$MODS_DIR"
ok "Pasta de mods: $MODS_DIR"

printf '%s\n%s\n' "$WATCH_DIR" "$MODS_DIR" > "$CONFIG_FILE"
ok "Config salvo."

# --- SYSTEMD ---
echo ""
echo -e "${BOLD}[4] Registrando serviço${NC}"
mkdir -p "$HOME/.config/systemd/user"
cat > "$HOME/.config/systemd/user/$SERVICE" << EOF
[Unit]
Description=Hytale Mod Manager Daemon
After=graphical-session.target

[Service]
Type=simple
ExecStart=$SCRIPT_DIR/daemon.sh
Restart=on-failure
RestartSec=5
Environment="DISPLAY=:0"
Environment="DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus"

[Install]
WantedBy=default.target
EOF
systemctl --user daemon-reload
systemctl --user enable --now "$SERVICE"
ok "Serviço iniciado!"

# --- COMANDO GLOBAL ---
echo ""
echo -e "${BOLD}[5] Criando comando 'hytalemm'${NC}"
cat > /tmp/hytalemm_install << EOFCMD
#!/bin/bash
CONFIG_FILE="$CONFIG_FILE"
LOG_FILE="$LOG_FILE"
SERVICE="$SERVICE"
SCRIPT_DIR="$SCRIPT_DIR"

get_mods_dir() { sed -n '2p' "\$CONFIG_FILE" 2>/dev/null | tr -d '[:space:]'; }

case "\${1:-menu}" in
    start)   systemctl --user start   "\$SERVICE" && echo "▶️  Daemon iniciado." ;;
    stop)    systemctl --user stop    "\$SERVICE" && echo "⏸️  Daemon parado." ;;
    restart) systemctl --user restart "\$SERVICE" && echo "🔄 Daemon reiniciado." ;;
    status)  systemctl --user status  "\$SERVICE" ;;
    logs)    [ -f "\$LOG_FILE" ] && tail -f "\$LOG_FILE" || echo "❌ Sem logs ainda." ;;
    mods)
        DIR=\$(get_mods_dir)
        [ -d "\$DIR" ] && xdg-open "\$DIR" 2>/dev/null || echo "📂 \$DIR"
        ;;
    purge)
        DIR=\$(get_mods_dir)
        echo ""
        echo "⚠️  Apagar TODOS os mods em: \$DIR"
        read -rp "Tem certeza? [s/N] " C
        [[ "\$C" =~ ^[sS]$ ]] && rm -rf "\$DIR"/* && echo "🗑️  Removido." || echo "❌ Cancelado."
        ;;
    config)  cd "\$SCRIPT_DIR" && ./setup.sh ;;
    help|--help|-h)
        echo ""
        echo "  ⚔️  hytalemm — Hytale Mod Manager"
        echo ""
        echo "  hytalemm          → Abre o menu"
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
        ;;
    menu|*)  cd "\$SCRIPT_DIR" && ./setup.sh ;;
esac
EOFCMD

if sudo mv /tmp/hytalemm_install /usr/local/bin/hytalemm && sudo chmod +x /usr/local/bin/hytalemm; then
    ok "Comando 'hytalemm' criado!"
else
    err "Erro ao criar comando (precisa de sudo)"
fi

# --- RESUMO ---
echo ""
echo -e "${BLUE}${BOLD}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║            ✅  TUDO PRONTO!             ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  ${BOLD}📂 Monitorando:${NC}  $WATCH_DIR"
echo -e "  ${BOLD}📦 Mods em:${NC}      $MODS_DIR"
echo ""
echo -e "  Baixe um mod em ${BOLD}$WATCH_DIR${NC} e ele será instalado automaticamente!"
echo ""
