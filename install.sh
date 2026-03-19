#!/usr/bin/env bash
# ============================================================
#  HyprMocha-Blue — Dotfiles Install Script
#  https://github.com/Usernames-are-useful/HyprMocha-Blue
#
#  For Arch Linux (btw)
# ============================================================

set -euo pipefail

REPO_URL="https://github.com/Usernames-are-useful/HyprMocha-Blue.git"
DOTFILES_DIR="$HOME/.dotfiles/HyprMocha-Blue"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d_%H%M%S)"

# ── Colours ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${BLUE}${BOLD}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}${BOLD}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}${BOLD}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}${BOLD}[ERR]${NC}   $*" >&2; }
btw()     { echo -e "${BOLD}        $*${NC}"; }

# ── Packages ─────────────────────────────────────────────────
PACMAN_PKGS=(
    hyprland
    waybar
    kitty
    rofi-wayland
    swaync
    cava
    fastfetch
    neovim
    yazi
    git
    grim
    slurp
    swappy
    hyprpicker
    hypridle
    hyprlock
    xdg-desktop-portal-hyprland
    xdg-user-dirs
    polkit-kde-agent
    qt5-wayland
    qt6-wayland
    nwg-look
    brightnessctl
    playerctl
    pamixer
    pipewire
    wireplumber
    pipewire-pulse
    ttf-jetbrains-mono-nerd
    noto-fonts-emoji
    wget
    curl
    unzip
)

AUR_PKGS=(
    wlogout
    swww
    hyprshot
)

# ── Helpers ───────────────────────────────────────────────────
command_exists() { command -v "$1" &>/dev/null; }

backup_existing() {
    local target="$CONFIG_DIR/$1"
    if [[ -e "$target" || -L "$target" ]]; then
        warn "Backing up existing $target → $BACKUP_DIR/$1"
        mkdir -p "$BACKUP_DIR"
        mv "$target" "$BACKUP_DIR/$1"
    fi
}

link_config() {
    local name="$1"
    local src="$DOTFILES_DIR/$name"
    local dst="$CONFIG_DIR/$name"

    if [[ ! -d "$src" ]]; then
        warn "Source not found, skipping: $src"
        return
    fi

    backup_existing "$name"
    ln -sf "$src" "$dst"
    success "Linked $name → $dst"
}

install_yay() {
    if command_exists yay; then
        success "yay already installed"
        return
    fi
    info "Installing yay (AUR helper)..."
    local tmp
    tmp=$(mktemp -d)
    git clone --depth=1 https://aur.archlinux.org/yay.git "$tmp/yay"
    (cd "$tmp/yay" && makepkg -si --noconfirm)
    rm -rf "$tmp"
    success "yay installed"
}

# ── Main ──────────────────────────────────────────────────────
main() {
    echo
    echo -e "${BOLD}╔══════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║       HyprMocha-Blue  Installer          ║${NC}"
    echo -e "${BOLD}║       btw, I use Arch                    ║${NC}"
    echo -e "${BOLD}╚══════════════════════════════════════════╝${NC}"
    echo

    if [[ "$EUID" -eq 0 ]]; then
        error "Do not run this script as root."
        exit 1
    fi

    if ! command_exists pacman; then
        error "pacman not found. This script is for Arch Linux (btw)."
        error "If you're on Fedora, use install-fedora.sh instead."
        exit 1
    fi

    # ── 1. Clone repo ─────────────────────────────────────────
    info "Cloning dotfiles..."
    if [[ -d "$DOTFILES_DIR" ]]; then
        warn "Dotfiles directory already exists at $DOTFILES_DIR"
        read -rp "$(echo -e "${YELLOW}Pull latest changes?${NC} [y/N] ")" pull_yn
        if [[ "${pull_yn,,}" == "y" ]]; then
            git -C "$DOTFILES_DIR" pull
            success "Pulled latest changes"
        fi
    else
        git clone --depth=1 "$REPO_URL" "$DOTFILES_DIR"
        success "Cloned to $DOTFILES_DIR"
    fi

    # ── 2. Install packages ───────────────────────────────────
    read -rp "$(echo -e "${YELLOW}Install packages?${NC} [Y/n] ")" pkg_yn
    if [[ "${pkg_yn,,}" != "n" ]]; then
        info "Updating system (btw)..."
        sudo pacman -Syu --noconfirm

        info "Installing pacman packages..."
        sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}" || \
            warn "Some pacman packages may have failed — check output above"

        install_yay

        info "Installing AUR packages..."
        yay -S --needed --noconfirm "${AUR_PKGS[@]}" || \
            warn "Some AUR packages may have failed — check output above"

        success "Package installation complete"
    else
        info "Skipping package installation"
    fi

    # ── 3. Link configs ───────────────────────────────────────
    info "Linking config directories..."
    mkdir -p "$CONFIG_DIR"

    link_config "hypr"
    link_config "waybar"
    link_config "kitty"
    link_config "rofi"
    link_config "swaync"
    link_config "wlogout"
    link_config "cava"
    link_config "fastfetch"
    link_config "nvim"
    link_config "yazi"

    # ── 4. Post-install ───────────────────────────────────────
    info "Running post-install steps..."
    xdg-user-dirs-update 2>/dev/null || true

    if command_exists systemctl; then
        systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || \
            warn "Could not enable pipewire services — you may need to do this manually"
    fi

    echo
    echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║          Installation Complete!          ║${NC}"
    echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════╝${NC}"
    echo
    [[ -d "$BACKUP_DIR" ]] && info "Old configs backed up to: $BACKUP_DIR"
    info "Dotfiles location: $DOTFILES_DIR"
    echo
    echo -e "  ${BOLD}Next steps:${NC}"
    echo -e "  1. Log out and select ${BOLD}Hyprland${NC} from your display manager"
    echo -e "  2. Or start it with: ${BOLD}Hyprland${NC}"
    echo -e "  3. Edit ${BOLD}~/.config/hypr/hyprland.conf${NC} to set your monitor layout"
    echo -e "     (run ${BOLD}hyprctl monitors${NC} after first launch to get your monitor name)"
    echo
    btw "I use Arch, by the way."
    echo
}

main "$@"
