#!/usr/bin/env bash

CONFIG_FILE="$HOME/.config/ghostty/config"
SHADER_DIR="$HOME/.config/ghostty/shaders"

CYAN=$'\e[1;36m'
GREEN=$'\e[1;32m'
MAGENTA=$'\e[1;35m'
YELLOW=$'\e[1;33m'
RED=$'\e[1;31m'
BLUE=$'\e[1;34m'
BOLD=$'\e[1m'
RESET=$'\e[0m'

clear_screen() {
    clear
    echo "${MAGENTA}"
    echo "  ╔═══════════════════════════════════════════════════════╗"
    echo "  ║        G H O S T T Y   C O N F I G   M G R          ║"
    echo "  ╚═══════════════════════════════════════════════════════╝"
    echo "${RESET}"
}

set_config() {
    local key="$1"
    local val="$2"
    sed -i "/^${key} =/d" "$CONFIG_FILE" 2>/dev/null
    if [[ -n "$val" ]]; then
        echo "${key} = ${val}" >> "$CONFIG_FILE"
    fi
}

detect_and_install_git() {
    if command -v git &>/dev/null; then
        return 0
    fi

    echo "${YELLOW}➜ git is not installed on your system.${RESET}"
    read -rp "Would you like to install git now? [y/N]: " install_confirm
    if [[ ! "$install_confirm" =~ ^[Yy]$ ]]; then
        echo "${RED}✖ git installation skipped.${RESET}"
        return 1
    fi

    local distro_id=""
    if [[ -f /etc/os-release ]]; then
        distro_id=$(grep -E '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
    fi

    echo "${BLUE}Installing git...${RESET}"
    case "$distro_id" in
        arch|artix|endeavouros|garuda)
            sudo pacman -S --needed git
            ;;
        fedora|rhel|centos)
            sudo dnf install git
            ;;
        ubuntu|debian|pop|mint)
            sudo apt update && sudo apt install git
            ;;
        alpine)
            sudo apk add git
            ;;
        void)
            sudo xbps-install -S git
            ;;
        gentoo)
            sudo emerge --ask dev-vcs/git
            ;;
        *)
            echo "${RED}Unsupported distribution. Please install git manually.${RESET}"
            return 1
            ;;
    esac

    if command -v git &>/dev/null; then
        echo "${GREEN}✔ git successfully installed!${RESET}"
        return 0
    else
        echo "${RED}✖ Failed to install git.${RESET}"
        return 1
    fi
}

detect_and_install_starship() {
    clear_screen
    echo "${CYAN}─── Starship Installation Assistant ───${RESET}"
    echo ""

    if command -v starship &>/dev/null; then
        echo "${GREEN}✔ Starship is already installed on your system!${RESET}"
        read -rp "Press Enter to return to main menu..."
        return
    fi

    local distro_id=""
    if [[ -f /etc/os-release ]]; then
        distro_id=$(grep -E '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
    fi

    local install_cmd=""

    case "$distro_id" in
        arch|artix|endeavouros|garuda)
            install_cmd="sudo pacman -S starship"
            ;;
        fedora|rhel|centos)
            install_cmd="sudo dnf install starship"
            ;;
        ubuntu|debian|pop|mint)
            install_cmd="curl -sS https://starship.rs/install.sh | sh"
            ;;
        alpine)
            install_cmd="sudo apk add starship"
            ;;
        void)
            install_cmd="sudo xbps-install -S starship"
            ;;
        gentoo)
            install_cmd="sudo emerge --ask app-shells/starship"
            ;;
        *)
            install_cmd="curl -sS https://starship.rs/install.sh | sh"
            ;;
    esac

    echo "${YELLOW}Detected Distro:${RESET} ${BOLD}${distro_id:-Unknown}${RESET}"
    echo "${YELLOW}Recommended Command:${RESET} ${GREEN}${install_cmd}${RESET}"
    echo ""

    read -rp "Do you want to run this installation command now? [y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo ""
        echo "${BLUE}Executing install command...${RESET}"
        if [[ "$distro_id" =~ ^(arch|artix|endeavouros|garuda)$ ]]; then
            sudo pacman -S starship
        elif [[ "$distro_id" =~ ^(fedora|rhel|centos)$ ]]; then
            sudo dnf install starship
        elif [[ "$distro_id" == "alpine" ]]; then
            sudo apk add starship
        elif [[ "$distro_id" == "void" ]]; then
            sudo xbps-install -S starship
        elif [[ "$distro_id" == "gentoo" ]]; then
            sudo emerge --ask app-shells/starship
        else
            curl -sS https://starship.rs/install.sh | sh
        fi
        echo ""
        echo "${GREEN}✔ Operation finished!${RESET}"
    else
        echo ""
        echo "${RED}Installation canceled.${RESET}"
    fi

    read -rp "Press Enter to return to main menu..."
}

select_shader_menu() {
    clear_screen
    echo "${CYAN}─── Select Cursor Shader ───${RESET}"
    echo ""

    mkdir -p "$SHADER_DIR"
    mapfile -t SHADER_PATHS < <(find "$SHADER_DIR" -type f -name "*.glsl" 2>/dev/null | sort)

    if [[ ${#SHADER_PATHS[@]} -eq 0 ]]; then
        echo "${YELLOW}✖ No .glsl shaders found in ${SHADER_DIR}${RESET}"
        echo ""
        read -rp "Would you like to clone starter shaders from GitHub? [y/N]: " clone_confirm
        if [[ "$clone_confirm" =~ ^[Yy]$ ]]; then
            if detect_and_install_git; then
                echo "${BLUE}Cloning ghostty-cursor-trails...${RESET}"
                git clone https://github.com/hced/ghostty-cursor-trails.git "$SHADER_DIR/ghostty-cursor-trails"
                mapfile -t SHADER_PATHS < <(find "$SHADER_DIR" -type f -name "*.glsl" 2>/dev/null | sort)
            fi
        fi

        if [[ ${#SHADER_PATHS[@]} -eq 0 ]]; then
            echo ""
            echo "Place your custom .glsl files inside ${SHADER_DIR} to use them."
            read -rp "Press Enter to return to main menu..."
            return
        fi
    fi

    local options=()
    for path in "${SHADER_PATHS[@]}"; do
        options+=("$(basename "$path" .glsl)")
    done
    options+=("Disable Custom Shaders" "Back to Main Menu")

    PS3="${MAGENTA}Choose a shader number ❯ ${RESET}"
    
    select opt in "${options[@]}"; do
        if [[ "$opt" == "Back to Main Menu" ]]; then
            break
        elif [[ "$opt" == "Disable Custom Shaders" ]]; then
            set_config "custom-shader" ""
            set_config "cursor-opacity" "1"
            echo ""
            echo "${GREEN}✔ Disabled custom shader animations.${RESET}"
            sleep 1.5
            break
        elif [[ -n "$opt" ]]; then
            local chosen_path="${SHADER_PATHS[$((REPLY-1))]}"
            
            set_config "custom-shader" "$chosen_path"
            set_config "cursor-opacity" "0"
            set_config "custom-shader-animation" "always"
            
            echo ""
            echo "${GREEN}✔ Applied shader:${RESET} ${BOLD}$opt${RESET}"
            echo "${BLUE}Path:${RESET} $chosen_path"
            sleep 1.5
            break
        else
            echo "${RED}Invalid selection. Please choose a valid number.${RESET}"
        fi
    done
}

while true; do
    clear_screen
    echo "${BLUE}  [1]${RESET} ${BOLD}Launch Theme Switcher${RESET} ${CYAN}(ghostty +list-themes)${RESET}"
    echo "${BLUE}  [2]${RESET} ${BOLD}Choose Cursor Animation Shader${RESET}"
    echo "${BLUE}  [3]${RESET} ${BOLD}Install / Verify Starship Prompt${RESET}"
    echo "${BLUE}  [4]${RESET} ${BOLD}Quit${RESET}"
    echo ""

    read -rp "${MAGENTA}Select an option [1-4] ❯ ${RESET}" main_opt
    case $main_opt in
        1)
            ghostty +list-themes
            ;;
        2)
            select_shader_menu
            ;;
        3)
            detect_and_install_starship
            ;;
        4)
            echo ""
            echo "${CYAN}Goodbye!${RESET}"
            echo ""
            exit 0
            ;;
        *)
            echo "${RED}Invalid option.${RESET}"
            sleep 1
            ;;
    esac
done
