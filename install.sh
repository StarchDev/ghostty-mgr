#!/usr/bin/env bash

INSTALL_DIR="$HOME/.local/bin"
SCRIPT_NAME="ghostty-mgr"

GREEN=$'\e[1;32m'
CYAN=$'\e[1;36m'
YELLOW=$'\e[1;33m'
RED=$'\e[1;31m'
BOLD=$'\e[1m'
RESET=$'\e[0m'

echo "${CYAN}╔═══════════════════════════════════════════════════════╗${RESET}"
echo "${CYAN}║      Installing Ghostty Configuration Manager         ║${RESET}"
echo "${CYAN}╚═══════════════════════════════════════════════════════╝${RESET}"
echo ""

if [[ ! -f "./ghostty-mgr.sh" ]]; then
    echo "${RED}✖ Error: ghostty-mgr.sh not found in current directory!${RESET}"
    echo "Make sure install.sh is in the same folder as ghostty-mgr.sh."
    exit 1
fi

mkdir -p "$INSTALL_DIR"

echo "${CYAN}➜ Installing script to ${INSTALL_DIR}/${SCRIPT_NAME}...${RESET}"
cp ./ghostty-mgr.sh "$INSTALL_DIR/$SCRIPT_NAME"
chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

echo ""
echo "${GREEN}✔ Installation complete!${RESET}"
echo ""

SHELL_NAME="$(basename "$SHELL")"
RC_FILE=""

case "$SHELL_NAME" in
    bash)
        if [[ -f "$HOME/.bashrc" ]]; then
            RC_FILE="$HOME/.bashrc"
        elif [[ -f "$HOME/.bash_profile" ]]; then
            RC_FILE="$HOME/.bash_profile"
        fi
        PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'
        ;;
    zsh)
        RC_FILE="$HOME/.zshrc"
        PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'
        ;;
    fish)
        RC_FILE="$HOME/.config/fish/config.fish"
        PATH_LINE='fish_add_path $HOME/.local/bin'
        ;;
    ksh|mksh)
        RC_FILE="$HOME/.kshrc"
        PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'
        ;;
    *)
        if [[ -f "$HOME/.profile" ]]; then
            RC_FILE="$HOME/.profile"
            PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'
        fi
        ;;
esac

if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    if [[ -n "$RC_FILE" ]]; then
        if ! grep -qs '\.local/bin' "$RC_FILE" 2>/dev/null; then
            echo "${YELLOW}➜ Adding ~/.local/bin to PATH in ${RC_FILE}...${RESET}"
            mkdir -p "$(dirname "$RC_FILE")"
            echo "" >> "$RC_FILE"
            echo "# Added by ghostty-mgr installer" >> "$RC_FILE"
            echo "$PATH_LINE" >> "$RC_FILE"
            echo "${GREEN}✔ PATH updated successfully in ${RC_FILE}!${RESET}"
            echo "${YELLOW}Run 'source ${RC_FILE}' or restart your terminal to apply.${RESET}"
        else
            echo "${GREEN}✔ PATH entry already exists in ${RC_FILE}.${RESET}"
        fi
    else
        echo "${YELLOW}Note: Could not automatically detect shell config file.${RESET}"
        echo "Please add ${BOLD}${PATH_LINE}${RESET} to your shell profile."
    fi
    echo ""
else
    echo "${GREEN}✔ ~/.local/bin is already in your active PATH.${RESET}"
    echo ""
fi

echo "You can now run ${BOLD}${CYAN}ghostty-mgr${RESET} from anywhere!"
