#!/bin/bash

# Orchestrix Starter - Manual Installation Script
# Usage: curl -fsSL https://raw.githubusercontent.com/dorayo/orchestrix-starter/main/scripts/install.sh | bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

BASE_URL="https://raw.githubusercontent.com/dorayo/orchestrix-starter/main"
COMMANDS_DIR="$HOME/.claude/commands"
SKILL_DIR="$COMMANDS_DIR/create-project"
HOOKS_DIR="$HOME/.claude/hooks"

check_requirements() {
    if ! command -v curl &> /dev/null; then
        error "curl is not installed. Please install curl first."
    fi
    if ! command -v git &> /dev/null; then
        warn "git is not installed. Project initialization will require git."
    fi
}

download() {
    local url=$1
    local target=$2
    curl -fsSL "$url" -o "$target" 2>/dev/null
    if [ $? -eq 0 ] && [ -f "$target" ]; then
        return 0
    else
        return 1
    fi
}

main() {
    echo ""
    echo "========================================="
    echo "  Orchestrix Starter Installation        "
    echo "========================================="
    echo ""

    check_requirements

    # Create directories
    mkdir -p "$COMMANDS_DIR" "$SKILL_DIR" "$HOOKS_DIR"

    # Download skill entry point
    info "Downloading create-project skill..."
    if download "$BASE_URL/skills/create-project/SKILL.md" "$COMMANDS_DIR/create-project.md"; then
        info "Saved: $COMMANDS_DIR/create-project.md"
    else
        error "Failed to download SKILL.md"
    fi

    # Download slash commands
    info "Downloading slash commands..."
    local commands=("o.md" "o-help.md" "o-status.md")
    for cmd in "${commands[@]}"; do
        if download "$BASE_URL/skills/create-project/resources/$cmd" "$COMMANDS_DIR/$cmd"; then
            info "Saved: $COMMANDS_DIR/$cmd"
        else
            warn "Failed to download: $cmd"
        fi
    done

    # Download skill resources
    info "Downloading skill resources..."
    local resources=(
        "mcp.json.template"
        "settings.local.json"
        "core-config.template.yaml"
        "handoff-detector.sh"
        "start-orchestrix.sh"
    )
    for res in "${resources[@]}"; do
        if download "$BASE_URL/skills/create-project/resources/$res" "$SKILL_DIR/$res"; then
            info "Saved: $SKILL_DIR/$res"
        else
            warn "Failed to download: $res"
        fi
    done

    # Also copy slash commands to skill resource dir for create-project to use
    for cmd in "${commands[@]}"; do
        cp "$COMMANDS_DIR/$cmd" "$SKILL_DIR/$cmd" 2>/dev/null || true
    done

    # Download hook
    info "Installing handoff-detector hook..."
    if download "$BASE_URL/skills/create-project/resources/handoff-detector.sh" "$HOOKS_DIR/handoff-detector.sh"; then
        chmod +x "$HOOKS_DIR/handoff-detector.sh"
        info "Saved: $HOOKS_DIR/handoff-detector.sh (executable)"
    else
        warn "Failed to download hook (non-critical)"
    fi

    echo ""
    echo "========================================="
    echo "        Installation Complete!           "
    echo "========================================="
    echo ""
    info "Skill installed:    ~/.claude/commands/create-project.md"
    info "Commands installed: ~/.claude/commands/o.md, o-help.md, o-status.md"
    info "Resources:          ~/.claude/commands/create-project/"
    info "Hook:               ~/.claude/hooks/handoff-detector.sh"
    echo ""
    echo "Usage:"
    echo "  1. Open Claude Code in any directory"
    echo "  2. Type: /create-project"
    echo "  3. Follow the interactive prompts"
    echo ""
}

main
