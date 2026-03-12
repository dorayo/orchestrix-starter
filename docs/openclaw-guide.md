# OpenClaw + Orchestrix Integration Guide

> 本文档指导 OpenClaw（小龙虾）如何在 Claude Code 中操作 Orchestrix Agent，完成从项目创建到迭代开发的全自动化流程。

---

## 一、架构概览

```
OpenClaw (自动化控制层)
    ↓ 通过消息平台发送指令（Telegram / WhatsApp / Slack）
Claude Code (AI 编码助手)
    ↓ 通过 /o 激活 Agent
Orchestrix MCP Server (Agent 定义、任务、模板)
    ↓ 返回 Agent 配置和工作流
Claude Code 执行 Agent 工作流
```

**两种运行模式**：

| 模式 | 说明 | 适用场景 |
|------|------|---------|
| **单窗口模式** | OpenClaw 在一个 Claude Code 会话中逐个切换 Agent | 简单项目、线性流程 |
| **tmux 多窗口模式** | 4 个 Agent 各占一个 tmux 窗口，通过 HANDOFF 自动协作 | 持续迭代开发、全自动化 |

---

## 二、安装与配置

### 2.1 安装 Orchestrix Starter

```bash
# 方式 1: ClawHub（推荐）
clawhub install create-project

# 方式 2: Claude Code Plugin
/plugin install dorayo/orchestrix-starter

# 方式 3: 手动安装
curl -fsSL https://raw.githubusercontent.com/dorayo/orchestrix-starter/main/scripts/install.sh | bash
```

### 2.2 前置依赖

| 依赖 | 用途 | 安装 |
|------|------|------|
| `claude` (Claude Code) | AI 编码环境 | https://claude.ai/download |
| `tmux` | 多窗口终端复用 | `brew install tmux` |
| `git` | 版本控制 | 系统自带 |
| `jq` | JSON 处理（tmux 模式可选） | `brew install jq` |

### 2.3 别名配置

```bash
# 确保 cc 命令可用（start-orchestrix.sh 依赖此别名）
alias cc='claude --dangerously-skip-permissions'
```

---

## 三、创建项目

### 通过 OpenClaw 创建

告诉 OpenClaw：

> "创建一个新项目，叫[项目名]，是[简要描述]"

OpenClaw 执行：
1. 启动 Claude Code → `cc`
2. 输入 `/create-project`
3. 按 Skill 提示逐步回答问题
4. 确认后自动生成项目骨架

### 项目创建后的目录结构

```
~/Codes/{project-name}/
├── docs/project-brief.md              # 项目简报
├── .mcp.json                          # Orchestrix MCP Server 配置
├── .gitignore
├── .claude/
│   ├── settings.local.json            # Hook 配置（Stop 事件触发 HANDOFF 检测）
│   ├── hooks/handoff-detector.sh      # HANDOFF 检测 hook
│   └── commands/
│       ├── o.md                       # /o 指令
│       ├── o-help.md
│       └── o-status.md
└── .orchestrix-core/
    ├── core-config.yaml               # 项目配置
    └── scripts/start-orchestrix.sh    # tmux 启动脚本
```

---

## 四、单窗口模式（逐个切换 Agent）

### 4.1 Agent 切换协议

**每次切换 Agent 必须严格遵循此序列**：

```
1. /clear              ← 清空上下文（必须）
2. 等待 0.5 秒
3. 按回车
4. 等待 1 秒
5. /o {agent}          ← 激活新 Agent
6. 等待 0.5 秒
7. 按回车
8. 等待 Agent 问候出现  ← Agent 就绪
9. *{command}          ← 执行命令
```

**关键**：不跳过 `/clear`，否则上下文残留会导致角色混乱。

### 4.2 完整规划阶段

```
cc                                          # 启动 Claude Code
│
├─ /o analyst                               # Step 1: 分析师
│  └─ *create-doc project-brief             # 生成/深化项目简报
│
├─ /clear → 回车 → 等 1s
├─ /o pm                                    # Step 2: 产品经理
│  └─ *create-doc prd                       # 生成 PRD
│
├─ /clear → 回车 → 等 1s
├─ /o ux-expert                             # Step 3: UX 专家（可选）
│  └─ *create-doc front-end-spec            # 前端规格
│
├─ /clear → 回车 → 等 1s
├─ /o architect                             # Step 4: 架构师
│  └─ *create-doc fullstack-architecture    # 架构文档
│
├─ /clear → 回车 → 等 1s
├─ /o po                                    # Step 5: PO
│  └─ *execute-checklist po-master-validation # 验证文档一致性
│  └─ *shard                                # 分片文档
```

### 4.3 开发循环（每个 Story 重复）

```
├─ /clear → 回车 → 等 1s
├─ /o sm                                    # SM 创建 Story
│  └─ *draft
│
├─ /clear → 回车 → 等 1s
├─ /o architect                             # Architect 技术审查（可选）
│  └─ *review {story_id}
│
├─ /clear → 回车 → 等 1s
├─ /o dev                                   # Dev 开发
│  └─ *develop-story {story_id}
│
├─ /clear → 回车 → 等 1s
├─ /o qa                                    # QA 审查
│  └─ *review {story_id}
│  └─ *finalize-commit {story_id}           # 提交代码
│
└─ 回到 SM，重复下一个 Story
```

---

## 五、tmux 多窗口模式（全自动化迭代开发）

> **这是 Orchestrix 的核心自动化能力。4 个 Agent 在独立窗口中运行，通过 HANDOFF 机制自动协作，无需人工切换。**

### 5.1 启动 tmux 自动化

```bash
cd ~/Codes/{project-name}/
bash .orchestrix-core/scripts/start-orchestrix.sh
```

脚本自动完成：
1. 创建 tmux session：`orchestrix-{repo-id}`
2. 创建 4 个窗口，每个窗口启动 Claude Code
3. 在每个窗口中激活对应 Agent
4. 在 SM 窗口自动启动工作流

### 5.2 tmux 窗口布局

| 窗口 | Agent | 环境变量 `AGENT_ID` | 职责 |
|------|-------|---------------------|------|
| `0` | Architect | `architect` | 技术审查、架构守护 |
| `1` | SM | `sm` | Story 创建、流程编排 |
| `2` | Dev | `dev` | 代码实现 |
| `3` | QA | `qa` | 代码审查、质量验证 |

### 5.3 HANDOFF 自动协作机制

当一个 Agent 完成任务后，会输出 HANDOFF 指令：

```
🎯 HANDOFF TO dev: *develop-story 1.1
```

`handoff-detector.sh` 会：
1. 扫描所有 4 个窗口的终端输出
2. 检测 HANDOFF 模式（3 种模式，优先级从高到低）：
   - **Pattern 1**: `🎯 HANDOFF TO {agent}: *{command}`
   - **Pattern 2**: `*{command} {story_id}`（简化格式）
   - **Pattern 3**: 读取 `.orchestrix-core/runtime/pending-handoff.json`（降级方案）
3. 将命令发送到目标 Agent 的 tmux 窗口
4. 在源 Agent 窗口执行 `/clear` + 重新加载 Agent

### 5.4 自动化迭代流程

```
start-orchestrix.sh 启动
    ↓
SM (窗口1) 自动开始 → *draft（创建第一个 Story）
    ↓ HANDOFF TO architect
Architect (窗口0) → *review 1.1（技术审查）
    ↓ HANDOFF TO dev
Dev (窗口2) → *develop-story 1.1（开发）
    ↓ HANDOFF TO qa
QA (窗口3) → *review 1.1（代码审查）
    ↓ HANDOFF TO sm
SM (窗口1) → *draft 1.2（创建下一个 Story）
    ↓ HANDOFF TO dev
Dev (窗口2) → *develop-story 1.2
    ↓ ...
    ↓ 循环直到所有 Story 完成
```

**整个过程无需人工干预。** 每个 Agent 完成任务后自动 HANDOFF 到下一个 Agent。

### 5.5 tmux 操作指南

| 操作 | 快捷键 |
|------|--------|
| 切换到窗口 0/1/2/3 | `Ctrl+b` → `0` / `1` / `2` / `3` |
| 下一个/上一个窗口 | `Ctrl+b` → `n` / `p` |
| 后台运行（detach） | `Ctrl+b` → `d` |
| 重新连接 | `tmux attach -t orchestrix-{repo-id}` |
| 滚动查看历史 | `Ctrl+b` → `[`（按 `q` 退出） |
| 杀掉 session | `tmux kill-session -t orchestrix-{repo-id}` |

### 5.6 监控与日志

```bash
# 实时查看 HANDOFF 日志
tail -f /tmp/orchestrix-{repo-id}-handoff.log

# 检查 tmux session 状态
tmux ls

# 查看所有窗口当前状态
tmux list-windows -t orchestrix-{repo-id}
```

日志示例：
```
[2026-03-12 15:30:01] HANDOFF detected: sm → dev (*develop-story 1.1)
[2026-03-12 15:45:23] HANDOFF detected: dev → qa (*review 1.1)
[2026-03-12 15:52:07] HANDOFF detected: qa → sm (*draft --continue)
```

### 5.7 HANDOFF 防重机制

- **Hash 去重**：每个 HANDOFF 指令生成唯一 hash，已处理的不会重复执行
- **原子锁**：基于目录的原子锁防止多个窗口同时处理同一个 HANDOFF
- **后台清理**：源 Agent 窗口在后台异步执行 `/clear` + 重载，不阻塞目标窗口

### 5.8 异常处理

| 情况 | 处理方式 |
|------|---------|
| Agent 卡住不输出 HANDOFF | 手动切换到该窗口，输入 `/clear` 后重新 `/o {agent}` |
| HANDOFF 没被检测到 | 检查日志 `tail -f /tmp/orchestrix-*-handoff.log` |
| tmux session 断开 | `tmux attach -t orchestrix-{repo-id}` 重新连接 |
| 需要暂停自动化 | `Ctrl+b` → `d` detach，Agent 会等待输入 |
| 需要完全停止 | `tmux kill-session -t orchestrix-{repo-id}` |
| handoff-detector 找不到 | 确认 `.orchestrix-core/scripts/handoff-detector.sh` 存在且可执行 |

---

## 六、OpenClaw 操作 tmux 模式

### 6.1 启动自动化

告诉 OpenClaw：

> "进入项目 [项目名]，启动 tmux 自动化开发"

OpenClaw 执行：
```bash
cd ~/Codes/{project-name}/
bash .orchestrix-core/scripts/start-orchestrix.sh
```

### 6.2 监控进度

告诉 OpenClaw：

> "检查 Orchestrix 开发进度"

OpenClaw 执行：
```bash
# 查看 HANDOFF 日志
tail -20 /tmp/orchestrix-{repo-id}-handoff.log

# 查看 Story 完成情况
ls docs/stories/

# 查看 git 提交记录
git log --oneline -10
```

### 6.3 干预或恢复

| 用户指令 | OpenClaw 操作 |
|---------|--------------|
| "暂停开发" | `tmux send-keys -t orchestrix-{repo-id}:1 C-c` |
| "恢复开发" | `tmux send-keys -t orchestrix-{repo-id}:1 "*draft --continue" Enter` |
| "重启 Dev Agent" | `tmux send-keys -t orchestrix-{repo-id}:2 "/clear" Enter` → 等 2s → `tmux send-keys -t orchestrix-{repo-id}:2 "/o dev" Enter` |
| "查看 QA 窗口" | `tmux capture-pane -t orchestrix-{repo-id}:3 -p \| tail -30` |
| "停止自动化" | `tmux kill-session -t orchestrix-{repo-id}` |

---

## 七、Solo 开发模式

> **Solo 模式跳过 Story/QA 关卡，适用于小型独立项目或快速原型。**

### 7.1 适用场景

| 场景 | 推荐方式 |
|------|---------|
| 全新小项目脚手架 | `/o dev` → `*solo "项目描述"` |
| 快速加一个小功能 | `/o dev` → `*solo "功能描述"` |
| 不需要 Story 流程的快速开发 | `/o dev` → `*quick-develop` |

### 7.2 操作序列

```
cc
│
├─ /o dev
│  └─ *solo "实现一个用户登录功能，支持邮箱和手机号"
│     ↓ 自动完成：创建 Story → 编码 → 测试 → 提交
│
└─ 完成
```

### 7.3 OpenClaw 用法

告诉 OpenClaw：

> "快速开发一个 [功能描述]，不走完整流程"

OpenClaw 执行：
```
/o dev
*solo "功能描述"
```

---

## 八、Bug 修复流程

### 8.1 轻量 Bug 修复（不需要 Story）

```
/o dev
*quick-fix "登录页面在 Safari 下白屏"
```

Dev 会：定位问题 → 修复 → 测试 → 提交，全程无需创建 Story。

### 8.2 正式 Bug 修复（创建 Bugfix Story）

当 Bug 较复杂或需要追踪时：

```
# Step 1: SM 创建 bugfix Story
/o sm
*draft-bugfix "用户并发下单时库存出现负数"

# Step 2: Dev 开发修复
/clear → /o dev
*develop-story {bugfix_story_id}

# Step 3: QA 验证
/clear → /o qa
*review {bugfix_story_id}
*finalize-commit {bugfix_story_id}
```

### 8.3 Dev 开发中发现 Bug 上报

Dev 在开发 Story 过程中发现不相关的 Bug 时，会在输出中标记。SM 可以用 `*draft-bugfix` 为其创建独立 Story，不影响当前 Story 进度。

### 8.4 OpenClaw 用法

| 指令 | OpenClaw 操作 |
|------|--------------|
| "快速修一个 bug: [描述]" | `/o dev` → `*quick-fix "[描述]"` |
| "这个 bug 比较重要，需要追踪" | `/o sm` → `*draft-bugfix "[描述]"` → Dev → QA |

---

## 九、Epic 冒烟测试

> **当一个 Epic 下的所有 Story 都开发完成后，QA 执行端到端冒烟测试，验证整体功能完整性。**

### 9.1 触发条件

- Epic 下所有 Story 已通过 QA 审查
- 所有代码已提交

### 9.2 操作序列

```
/o qa
*smoke-test {epic_id}
```

QA 会：
1. 识别 Epic 涉及的所有功能点
2. 设计端到端测试场景
3. 执行冒烟测试
4. 生成测试报告
5. 标记 Epic 为已验证或发现回归问题

### 9.3 如果冒烟测试发现问题

```
# QA 生成问题报告后
/clear → /o sm
*draft-bugfix "冒烟测试发现: [问题描述]"

# Dev 修复
/clear → /o dev
*develop-story {bugfix_story_id}

# QA 重新验证
/clear → /o qa
*review {bugfix_story_id}
*smoke-test {epic_id}    # 再次冒烟测试
```

### 9.4 OpenClaw 用法

> "Epic 1 的所有 Story 都做完了，跑一下冒烟测试"

OpenClaw 执行：
```
/clear → /o qa
*smoke-test 1
```

---

## 十、新起迭代（Iteration）

> **MVP 完成后，基于用户反馈或新需求启动新一轮迭代。**

### 10.1 迭代流程

```
# Step 1: PM 启动新迭代（需要已分片的 PRD）
/o pm
*start-iteration

# Step 2: PM 根据反馈修订 PRD（如需要）
*revise-prd

# Step 3: PO 验证更新后的文档
/clear → /o po
*execute-checklist po-master-validation
*shard

# Step 4: 进入开发循环（同主线流程）
/clear → /o sm
*draft
...
```

### 10.2 迭代 vs 新项目

| 维度 | 新迭代 | 新项目 |
|------|--------|--------|
| PRD | 在现有 PRD 上追加/修改 | 从零创建 |
| 架构 | 沿用现有架构（如需变更走变更流程） | 全新设计 |
| Stories | 新 Epic，Story ID 继续递增 | 从 1.1 开始 |
| 文档分片 | 增量分片 | 全量分片 |

### 10.3 OpenClaw 用法

> "MVP 做完了，根据用户反馈启动第二轮迭代"

OpenClaw 执行：
```
/clear → /o pm
*start-iteration
```

---

## 十一、需求变更管理

> **开发过程中收到需求变更时，通过 PO 路由到 PM 或 Architect 处理，确保变更受控。**

### 11.1 变更流程

```
# Step 1: PO 接收变更并路由
/o po
*route-change

# PO 会根据变更类型自动路由：
#   - 需求/范围变更 → PM
#   - 技术/架构变更 → Architect
#   - 两者都涉及 → 先 PM 再 Architect
```

### 11.2 需求变更（PM 处理）

```
# PO 路由到 PM
/clear → /o pm
*revise-prd
# PM 更新 PRD 并标记变更影响范围

# PO 重新验证
/clear → /o po
*execute-checklist po-master-validation
*shard    # 重新分片（如有新增内容）
```

### 11.3 技术变更（Architect 处理）

```
# PO 路由到 Architect
/clear → /o architect
*resolve-change
# Architect 生成技术变更提案（TCP）

# SM 根据 TCP 创建/修改 Story
/clear → /o sm
*apply-proposal {proposal_id}
```

### 11.4 变更影响评估

| 变更规模 | 处理方式 |
|---------|---------|
| 小变更（不影响已完成 Story） | PM 更新 PRD → 继续开发 |
| 中变更（影响未开始的 Story） | PM 更新 PRD → SM 修改 Story → 继续 |
| 大变更（影响已完成的 Story） | PM 更新 PRD → Architect 评估 → SM 创建回退/重做 Story |

### 11.5 OpenClaw 用法

| 指令 | OpenClaw 操作 |
|------|--------------|
| "客户要求加一个导出 PDF 的功能" | `/o po` → `*route-change` |
| "需要把数据库从 MySQL 换成 PostgreSQL" | `/o po` → `*route-change`（会路由到 Architect） |
| "PRD 需要更新，加了新需求" | `/o pm` → `*revise-prd` |

---

## 十二、Brownfield（已有项目增强）

> **对已有代码库进行功能增强或维护时的流程。**

### 12.1 路由判断

| 变更规模 | 估时 | 推荐方式 |
|---------|------|---------|
| 单个小功能 | < 4h | `/o sm` → `*draft` (brownfield story) |
| 小型功能（1-3 Story） | 4h-2d | `/o sm` → `*draft` (brownfield epic) |
| 大型增强 | > 2d | 走完整 Greenfield 流程（可跳过已有文档） |
| 快速修复 | < 1h | `/o dev` → `*quick-fix` |

### 12.2 Brownfield 项目摸底

对不熟悉的已有项目，先用 Architect 做代码库分析：

```
/o architect
*document-project
```

生成项目文档后再决定走哪条路径。

### 12.3 OpenClaw 用法

> "这个项目已经有代码了，我想加一个通知功能"

OpenClaw 判断规模后执行对应流程。

---

## 十三、Agent 命令速查表

### 产品与规划

| Agent | ID | 核心命令 |
|-------|----|---------|
| Analyst | `analyst` | `*brainstorm {topic}`, `*create-doc project-brief` |
| PM | `pm` | `*create-doc prd`, `*revise-prd`, `*start-iteration` |
| UX Expert | `ux-expert` | `*create-doc front-end-spec`, `*generate-ui-prompt` |
| Architect | `architect` | `*create-doc architecture`, `*review {story_id}` |
| PO | `po` | `*execute-checklist`, `*shard` |

### 开发循环

| Agent | ID | 核心命令 |
|-------|----|---------|
| SM | `sm` | `*draft`, `*draft-bugfix {bug}`, `*revise {story_id}` |
| Dev | `dev` | `*develop-story {story_id}`, `*quick-develop {story_id}`, `*solo "{desc}"` |
| QA | `qa` | `*review {story_id}`, `*finalize-commit {story_id}`, `*quick-verify {story_id}` |

### 管理

| Agent | ID | 核心命令 |
|-------|----|---------|
| Orchestrator | `orchestrix-orchestrator` | `*status`, `*workflow-guidance` |
| Master | `orchestrix-master` | `*task {name}`, `*create-doc {template}` |

---

## 十四、注意事项

1. **tmux 模式下不需要手动 `/clear`** — HANDOFF 机制自动处理 Agent 切换和上下文清理
2. **单窗口模式下每次切换必须 `/clear`** — 否则上下文残留导致角色混乱
3. **`cc` 别名必须配置** — `start-orchestrix.sh` 使用 `cc` 命令启动 Claude Code
4. **文档存储位置** — 规划文档在 `docs/`，Story 在 `docs/stories/`，QA 在 `docs/qa/`
5. **不确定用哪个 Agent？** — 用 `/o orchestrix-orchestrator` → `*workflow-guidance` 让它引导
6. **HANDOFF 日志路径** — `/tmp/orchestrix-{repo-id}-handoff.log`，`{repo-id}` 来自 `core-config.yaml` 的 `repository_id`
