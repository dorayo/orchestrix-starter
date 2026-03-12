# OpenClaw + Orchestrix Integration Guide

This guide explains how [OpenClaw](https://openclaw.ai) (小龙虾) can drive Orchestrix agents in Claude Code for fully automated project development.

## Overview

```
OpenClaw (automation layer)
    ↓ sends commands via messaging
Claude Code (AI coding assistant)
    ↓ activates agents via /o
Orchestrix MCP Server (agent definitions)
    ↓ returns agent config, tasks, templates
Claude Code executes the agent workflow
```

## Setup

### 1. Install Orchestrix Starter

```bash
# Via ClawHub (recommended for OpenClaw)
clawhub install orchestrix-starter

# Or via Claude Code plugin
/plugin install dorayo/orchestrix-starter
```

### 2. Create a Project

Tell OpenClaw:
> "Create a new project called [project name], it's a [description]"

OpenClaw will run `/create-project` and interact with Claude Code to scaffold the project.

### 3. Automated Workflow

After project creation, OpenClaw can drive the full Orchestrix lifecycle:

| Phase | OpenClaw Command | What Happens |
|-------|-----------------|--------------|
| Brief | "Deepen the project brief" | `/o analyst` → `*create-doc project-brief` |
| PRD | "Create the PRD" | `/o pm` → `*create-doc prd` |
| Architecture | "Design the architecture" | `/o architect` → `*create-doc architecture` |
| Stories | "Create stories from PRD" | `/o sm` → `*create-story` |
| Development | "Develop story S001" | `/o dev` → `*develop-story S001` |
| QA | "Review story S001" | `/o qa` → `*review S001` |

## Agent Switching Protocol

When switching between Orchestrix agents, OpenClaw must follow this sequence:

```
1. /clear              ← Clear context (required)
2. Wait 2 seconds      ← Let Claude Code reset
3. /o {agent}          ← Activate new agent
4. Wait for greeting   ← Agent is ready
5. *{command}          ← Execute agent command
```

**Critical**: Never skip `/clear` between agent switches. Each agent requires a clean context.

## Available Agents

| Agent ID | Role | Common Commands |
|----------|------|-----------------|
| `analyst` | Business Analyst | `*create-doc project-brief`, `*brainstorm` |
| `pm` | Product Manager | `*create-doc prd`, `*revise-prd` |
| `architect` | Solution Architect | `*create-doc architecture`, `*review S001` |
| `sm` | Scrum Master | `*create-story`, `*create-next-story` |
| `dev` | Developer | `*develop-story S001`, `*quick-develop` |
| `qa` | QA Engineer | `*review S001`, `*qa-gate` |
| `po` | Product Owner | `*review-proposal`, `*shard-documents` |

## HANDOFF Automation

When running in tmux mode (via `start-orchestrix.sh`), agents can hand off to each other automatically:

```
Agent output: 🎯 HANDOFF TO sm: *create-next-story
                ↓
handoff-detector.sh detects the pattern
                ↓
Sends command to SM's tmux window
```

This enables fully autonomous multi-agent workflows without human intervention.

## Tips for OpenClaw Users

1. **Start simple**: Use `/create-project` first, then manually run a few agent commands to understand the flow
2. **Use tmux mode**: Run `start-orchestrix.sh` to enable automatic agent handoffs
3. **Monitor via logs**: Check `/tmp/orchestrix-{repo}-handoff.log` for handoff activity
4. **Fallback**: If an agent gets stuck, `/clear` and re-activate it
