# Changelog

All notable changes to this project will be documented in this file.

## [2.0.0] - 2026-03-30

### Changed
- **tmux 3-step send-keys pattern**: All `send-keys "content" Enter` replaced with `send-keys "content"` → `sleep 1` → `send-keys Enter`. Prevents content getting stuck in Claude Code's input box.
- **Trust dialog auto-acceptance**: `start-orchestrix.sh` and `ensure-session.sh` detect "trust this folder?" prompt during startup and auto-accept via Enter.
- **Completion detection updated**: P1 pattern tightened to `[A-Z][a-z]*ed for [0-9]`, stability threshold reduced from 5×10s to 3×30s, added P3 approval prompt auto-handling.
- **/clear usage rules**: No longer `/clear` on every agent switch. Only use for cross-agent switching, error recovery, and stuck agents.
- **orchestrix-guide**: Full rewrite of Sections 2-6 with updated tmux patterns, added Phase C (testing), added helper scripts reference.
- **create-project**: Updated Phase 5 patterns, added new scripts to file copy list.

### Added
- `ensure-session.sh` — Lazy tmux session creation with trust dialog handling.
- `monitor-agent.sh` — Agent completion polling (4-level priority detection).
- Phase C (Testing) in orchestrix-guide — Full smoke-test → fix → retest cycle.
- `/clear` usage rules section in orchestrix-guide.
- Helper scripts reference section in orchestrix-guide.

## [1.0.0] - 2026-03-12

### Added
- Initial release of `create-project` skill
- Interactive Q&A flow for project information gathering
- Automated project scaffolding with Orchestrix infrastructure
- MCP Server configuration with License Key template
- Claude Code hooks and slash commands installation
- tmux multi-agent automation scripts
- Project brief generation from user answers
- Git initialization with initial commit
- Support for Claude Code Plugin, ClawHub, and manual installation
- OpenClaw compatibility via ClawHub metadata
