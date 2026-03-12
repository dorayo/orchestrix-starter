# Orchestrix Starter

Interactive project scaffolding for [Orchestrix](https://orchestrix-mcp.youlidao.ai) — the multi-agent development framework powered by Claude Code.

## What It Does

Run `/create-project` in Claude Code and it will:

1. **Ask** about your project (name, problem, users, tech stack, MVP scope)
2. **Confirm** understanding with a structured summary
3. **Create** a complete project skeleton with:
   - `docs/project-brief.md` — AI-generated project brief
   - `.mcp.json` — Orchestrix MCP Server connection
   - `.claude/` — Hooks, slash commands, and settings
   - `.orchestrix-core/` — Agent config and tmux automation
   - `.gitignore` + initial git commit

## Installation

### Option 1: Claude Code Plugin (Recommended)

```bash
# In Claude Code
/plugin install dorayo/orchestrix-starter
```

### Option 2: Manual Installation

```bash
curl -fsSL https://raw.githubusercontent.com/dorayo/orchestrix-starter/main/scripts/install.sh | bash
```

### Option 3: ClawHub (OpenClaw)

```bash
clawhub install orchestrix-starter
```

## Usage

In any Claude Code session:

```
/create-project
```

Follow the interactive prompts. The skill will guide you through:

1. License Key setup
2. Project information gathering
3. Confirmation
4. Automated project creation

## Prerequisites

- [Claude Code](https://claude.ai/download) installed
- An Orchestrix License Key ([get one here](https://orchestrix-mcp.youlidao.ai))
- `git` and `bash` available in PATH

## What Gets Created

```
~/Codes/your-project/
├── docs/
│   └── project-brief.md           # AI-generated project brief
├── .mcp.json                      # Orchestrix MCP Server config
├── .gitignore
├── .claude/
│   ├── settings.local.json        # Hook configuration
│   ├── hooks/
│   │   └── handoff-detector.sh    # Multi-agent handoff automation
│   └── commands/
│       ├── o.md                   # /o agent activation
│       ├── o-help.md              # /o-help
│       └── o-status.md            # /o-status
└── .orchestrix-core/
    ├── core-config.yaml           # Project-specific config
    └── scripts/
        └── start-orchestrix.sh    # tmux multi-window launcher
```

## After Project Creation

```bash
cd ~/Codes/your-project/
claude
```

Then follow the Orchestrix workflow:

| Step | Command | Purpose |
|------|---------|---------|
| 1 | `/o analyst` → `*create-doc project-brief` | Deepen the project brief |
| 2 | `/o pm` → `*create-doc prd` | Generate PRD from brief |
| 3 | `/o architect` → `*create-doc architecture` | Design system architecture |
| 4 | `/o sm` → `*create-story` | Break PRD into stories |
| 5 | `/o dev` → `*develop-story S001` | Implement stories |
| 6 | `/o qa` → `*review S001` | Review and test |

Or launch all agents in parallel with tmux:

```bash
bash .orchestrix-core/scripts/start-orchestrix.sh
```

## OpenClaw Integration

This skill is compatible with [OpenClaw](https://openclaw.ai) via ClawHub. OpenClaw can drive the entire Orchestrix workflow autonomously — from project creation to development and testing.

See [OpenClaw + Orchestrix Guide](docs/openclaw-guide.md) for details.

## License

MIT
