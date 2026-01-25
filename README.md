# ⚔️ Hytale Mod Manager (Linux)

> **Gerenciador de Mods CLI moderno, automático e estiloso para Hytale.**
> Esqueça a instalação manual. Apenas arraste o ZIP e jogue!

![License](https://img.shields.io/badge/license-MIT-green.svg)
![Bash](https://img.shields.io/badge/language-Bash-4EAA25.svg)
![Platform](https://img.shields.io/badge/platform-Linux-blue.svg)
![Status](https://img.shields.io/badge/status-Stable-success.svg)

![Hytale Mod Manager Dashboard](https://via.placeholder.com/800x400?text=Place+Screenshot+Here)

## ✨ Funcionalidades

O **Hytalemm** é uma ferramenta "Set and Forget". Você configura uma vez e ele trabalha em background para você.

* **🕵️ Monitoramento em Tempo Real:** O Daemon detecta novos arquivos `.zip`, `.jar` ou `.7z` assim que você os baixa.
* **📦 Instalação Inteligente:** Extrai mods automaticamente, substitui versões antigas e limpa o arquivo compactado.
* **💾 Sistema de Backup Seguro:** Cria backups automáticos (`.tar.gz`) antes de qualquer alteração crítica.
* **👁️ Modo Live Monitor:** Acompanhe os logs e o status do serviço em uma tela estilo "Matrix" (`watch`).
* **🎨 Interface TUI Moderna:** Menus interativos e bonitos feitos com `gum`, com tema inspirado nas cores do Hytale (Verde/Azul).
* **🔔 Notificações Desktop:** Receba avisos nativos do sistema quando um mod for instalado com sucesso.

## 🚀 Instalação

### 1. Pré-requisitos
Você precisa destas ferramentas instaladas no seu Linux:

* **Arch Linux:**
    ```bash
    sudo pacman -S unzip inotify-tools gum libnotify
    ```
* **Ubuntu/Debian:**
    ```bash
    sudo apt install unzip inotify-tools libnotify-bin
    # Nota: Instale o 'gum' separadamente (veja em: [https://github.com/charmbracelet/gum](https://github.com/charmbracelet/gum))
    ```

### 2. Clonar e Instalar
```bash
# Clone o repositório
git clone [https://github.com/jdkeditor/hytale-mod-manager.git](https://github.com/jdkeditor/hytale-mod-manager.git)

# Entre na pasta
cd hytale-mod-manager

# Dê permissão de execução
chmod +x setup.sh daemon.sh

# Rode o instalador
./setup.sh
