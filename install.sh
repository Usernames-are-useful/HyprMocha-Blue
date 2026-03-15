#!/usr/bin/env bash
# ============================================================
#  HyprMocha-Blue — Dotfiles Install Script
#  https://github.com/Usernames-are-useful/HyprMocha-Blue
#
#  For Fedora 41+
#  (your friend's version)
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

# ── Packages ─────────────────────────────────────────────────
# Requires solopasha/hyprland COPR for most of the Hyprland stack
FEDORA_PKGS=(
    hyprland
    waybar
    kitty
    rofi-wayland
    swaync
    wlogout
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
    pipewire-pulseaudio
    swww
    jetbrains-mono-fonts
    google-noto-emoji-fonts
    wget
    curl
    unzip
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

# ── Main ──────────────────────────────────────────────────────
main() {
    echo
    echo -e "${BOLD}╔══════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║       HyprMocha-Blue  Installer          ║${NC}"
    echo -e "${BOLD}║       Fedora Edition                     ║${NC}"
    echo -e "${BOLD}╚══════════════════════════════════════════╝${NC}"
    echo

    if [[ "$EUID" -eq 0 ]]; then
        error "Do not run this script as root."
        exit 1
    fi

    if ! command_exists dnf; then
        error "dnf not found. This script is for Fedora."
        error "If you're on Arch, use install.sh instead."
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
        info "Enabling solopasha/hyprland COPR..."
        sudo dnf copr enable -y solopasha/hyprland || \
            warn "COPR enable may have failed — Hyprland packages might not install correctly"

        info "Updating system..."
        sudo dnf upgrade -y

        info "Installing packages..."
        sudo dnf install -y "${FEDORA_PKGS[@]}" || \
            warn "Some packages may have failed — check output above"

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
}

main "$@"