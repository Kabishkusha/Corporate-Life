#!/usr/bin/env bash
#
# check-tools.sh — Animated toolchain checker for Node.js, npm, Git on Debian/Ubuntu.
#

set -euo pipefail

# --- Colors & styles ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'
HIDE_CURSOR='\033[?25l'
SHOW_CURSOR='\033[?25h'
CLEAR_LINE='\033[2K\r'

# Restore cursor on exit
trap 'echo -e "${SHOW_CURSOR}"' EXIT
echo -e "${HIDE_CURSOR}"

# --- Spinner ---
SPINNER_FRAMES=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
spinner() {
    local pid=$1
    local msg=$2
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "${CLEAR_LINE}${CYAN}${SPINNER_FRAMES[$i]}${NC} ${msg}"
        i=$(( (i + 1) % ${#SPINNER_FRAMES[@]} ))
        sleep 0.08
    done
    printf "${CLEAR_LINE}"
}

# --- Progress bar ---
progress_bar() {
    local duration=$1
    local msg=$2
    local width=40
    local steps=50
    local delay
    delay=$(awk "BEGIN {print $duration / $steps}")

    for ((i = 0; i <= steps; i++)); do
        local filled=$((i * width / steps))
        local empty=$((width - filled))
        local bar="${GREEN}$(printf '█%.0s' $(seq 1 $filled 2>/dev/null) 2>/dev/null)${DIM}$(printf '░%.0s' $(seq 1 $empty 2>/dev/null) 2>/dev/null)${NC}"
        local pct=$((i * 100 / steps))
        printf "${CLEAR_LINE}  ${msg} [${bar}] ${BOLD}%3d%%${NC}" "$pct"
        sleep "$delay"
    done
    printf "${CLEAR_LINE}  ${msg} [${GREEN}$(printf '█%.0s' $(seq 1 $width))${NC}] ${BOLD}100%%${NC}\n"
}

# --- Typewriter effect ---
typewriter() {
    local text=$1
    local delay=${2:-0.02}
    for ((i = 0; i < ${#text}; i++)); do
        printf "%s" "${text:$i:1}"
        sleep "$delay"
    done
    echo
}

# --- Status lines ---
info()  { echo -e "  ${GREEN}✔${NC} $*"; }
warn()  { echo -e "  ${YELLOW}⚠${NC} $*"; }
error() { echo -e "  ${RED}✘${NC} $*" >&2; }
step()  { echo -e "\n${BOLD}${BLUE}▶ $*${NC}"; }

# --- Check apt ---
command_exists() { command -v "$1" &>/dev/null; }

if ! command_exists apt-get; then
    error "This script requires apt-get (Debian/Ubuntu). Exiting."
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
    if command_exists sudo; then
        exec sudo "$0" "$@"
    else
        error "Please run as root or install sudo."
        exit 1
    fi
fi

# --- Banner ---
clear
echo -e "${MAGENTA}${BOLD}"
cat << 'EOF'
  ╔═══════════════════════════════════════════════╗
  ║   ⚙️   TOOLCHAIN CHECKER — Node · npm · Git   ║
  ╚═══════════════════════════════════════════════╝
EOF
echo -e "${NC}"
typewriter "  Initializing environment scan..." 0.015
echo

step "Updating apt package index"
( apt-get update -qq ) &
spinner $! "Refreshing package lists..."
info "Package index refreshed"

# --- Git ---
check_git() {
    step "Checking Git"
    if command_exists git; then
        local v
        v="$(git --version | awk '{print $3}')"
        info "Git detected — version ${BOLD}$v${NC}"

        if ! grep -rq "ppa:git-core/ppa" /etc/apt/sources.list.d/ 2>/dev/null; then
            ( apt-get install -y -qq software-properties-common && add-apt-repository -y ppa:git-core/ppa && apt-get update -qq ) &
            spinner $! "Adding git-core PPA..."
            info "git-core PPA added"
        fi

        ( apt-get install -y -qq git ) &
        spinner $! "Updating Git to latest..."
        info "Git updated → ${BOLD}$(git --version)${NC}"
    else
        warn "Git not found — installing..."
        ( apt-get install -y -qq git ) &
        spinner $! "Installing Git..."
        info "Git installed → ${BOLD}$(git --version)${NC}"
    fi
}

# --- Node.js ---
install_node_nodesource() {
    ( apt-get install -y -qq curl ca-certificates && \
      curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
      apt-get install -y -qq nodejs ) &
    spinner $! "Installing Node.js from NodeSource LTS..."
    info "Node.js installed → ${BOLD}$(node --version)${NC}"
    info "npm installed     → ${BOLD}$(npm --version)${NC}"
}

check_node() {
    step "Checking Node.js"
    if command_exists node; then
        local v major
        v="$(node --version)"
        major="$(echo "$v" | sed 's/^v//' | cut -d. -f1)"
        info "Node.js detected — version ${BOLD}$v${NC}"

        if [[ "$major" -lt 20 ]]; then
            warn "Node.js v$major is behind LTS (20) — updating..."
            install_node_nodesource
        else
            info "Node.js is at or above LTS — no update needed"
        fi
    else
        warn "Node.js not found — installing..."
        install_node_nodesource
    fi
}

# --- npm ---
check_npm() {
    step "Checking npm"
    if ! command_exists npm; then
        warn "npm not found — reinstalling Node.js..."
        install_node_nodesource
    fi

    local current latest
    current="$(npm --version)"
    info "npm detected — version ${BOLD}$current${NC}"

    latest="$(npm view npm version 2>/dev/null || echo "")"
    if [[ -n "$latest" && "$current" != "$latest" ]]; then
        warn "Updating npm $current → $latest"
        ( npm install -g npm@latest >/dev/null 2>&1 ) &
        spinner $! "Fetching npm@latest..."
        info "npm updated → ${BOLD}$(npm --version)${NC}"
    else
        info "npm is up to date"
    fi
}

# --- Run checks ---
check_git
check_node
check_npm

# --- Summary ---
step "Summary"
progress_bar 0.8 "Finalizing"
echo
echo -e "  ${BOLD}${CYAN}┌─────────────────────────────────────┐${NC}"
printf "  ${BOLD}${CYAN}│${NC}  %-8s %-22s ${BOLD}${CYAN}│${NC}\n" "Git:"  "$(git --version 2>/dev/null | awk '{print $3}' || echo 'NOT FOUND')"
printf "  ${BOLD}${CYAN}│${NC}  %-8s %-22s ${BOLD}${CYAN}│${NC}\n" "Node:" "$(node --version 2>/dev/null || echo 'NOT FOUND')"
printf "  ${BOLD}${CYAN}│${NC}  %-8s %-22s ${BOLD}${CYAN}│${NC}\n" "npm:"  "$(npm --version 2>/dev/null || echo 'NOT FOUND')"
echo -e "  ${BOLD}${CYAN}└─────────────────────────────────────┘${NC}"
echo
typewriter "  ✅ All checks complete." 0.02
echo
