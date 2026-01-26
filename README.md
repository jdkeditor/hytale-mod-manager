Markdown# ⚔️ Hytale Mod Manager (Linux)

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
Siga os passos na tela para configurar sua pasta de mods e criar os atalhos.🕹️ Como UsarMenu PrincipalApós instalar, você pode abrir o gerenciador de qualquer lugar pelo terminal ou pelo menu de aplicativos:Bashhytalemm
Isso abrirá o Painel de Controle onde você pode:Iniciar/Parar o Daemon.Criar ou Restaurar Backups.Ver Logs em tempo real.Entrar no Modo Monitor.Instalando um ModBaixe qualquer mod de Hytale (.zip).Mova ou salve o arquivo na sua pasta de mods configurada.Pronto! O Hytalemm detecta, instala e te notifica.Comandos Rápidos (CLI)Você também pode controlar o daemon direto pelo terminal sem abrir o menu:ComandoDescriçãohytalemm startInicia o monitoramento em backgroundhytalemm stopPara o serviçohytalemm statusVerifica se está rodandohytalemm logsAbre o visualizador de logs🛠️ Estrutura do Projetosetup.sh: O "Cérebro" (Frontend). Gera a interface gráfica CLI e gerencia configurações.daemon.sh: O "Músculo" (Backend). Script que roda em background monitorando arquivos.~/.config/hytale-mod-installer/: Onde ficam salvas suas configurações e logs.🤝 ContribuiçãoContribuições são bem-vindas! Se você tiver ideias para melhorar a detecção de mods ou novas features:Faça um Fork do projeto.Crie uma Branch (git checkout -b feature/NovaFeature).Commit suas mudanças (git commit -m 'Adiciona nova feature').Push para a Branch (git push origin feature/NovaFeature).Abra um Pull Request.📝 LicençaEste projeto está sob a licença MIT. Veja o arquivo LICENSE para mais detalhes.Desenvolvido com 🌲 por Vrn.
