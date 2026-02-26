---
root: true
targets: ["*"]
description: "ai-workspace のプロジェクト概要と開発ルール"
globs: ["**/*"]
---

# 大前提

- 日本語でやりとりすること

# 基本原則

- シンプルさの優先: すべての変更を可能な限りシンプルに保ち、コードへの影響範囲を最小限に抑える。
- 妥協の排除: 根本原因を特定すること。一時しのぎの修正は行わず、シニア開発者としての基準を維持する。
- 影響の最小化: 必要な箇所のみを変更し、新たなバグの混入を徹底的に防ぐ。

# ai-workspace 概要

マルチプロジェクト開発用ワークスペース。

- **Cursor**: `ai-workspace.code-workspace` をマルチルートワークスペースとして開いて横断的に開発
- **Claude Code**: `projects/` 配下に複数のリポジトリをクローンして横断的に開発
- **Codex**: `ai-workspace` をルートに開き、`projects/` 配下の複数リポジトリを横断的に開発

## AI エージェント設定

### rulesync で共通管理

`.rulesync/` で編集し、`rulesync generate` で各エージェント向けに展開する。

| 編集正本 | Cursor | Claude Code | Codex |
| --- | --- | --- | --- |
| `.rulesync/rules/` | `.cursor/rules` | `.claude/rules` | `.codex/memories` |
| `.rulesync/rules/overview.md` | `.cursor/rules/overview.mdc` | `CLAUDE.md` | `AGENTS.md` |
| `.rulesync/skills/` | `.cursor/skills` | `.claude/skills` | `.codex/skills` |
| `.rulesync/subagents` | `.cursor/subagents` | `.claude/subagents` | `.codex/subagents` |

詳細は `rulesync.jsonc` を参照。

### 個別管理

各エージェントのディレクトリを直接編集する。

| 項目 | Cursor | Claude Code | Codex |
| --- | --- | --- | --- |
| MCP 設定 | `.cursor/mcp.json` | `.mcp.json` | - |
| Kiro コマンド | `.cursor/commands/kiro/` | `.claude/commands/kiro/` | `.codex/prompts/` |

# AI-DLC and Spec-Driven Development

Kiro-style Spec Driven Development implementation on AI-DLC (AI Development Life Cycle)

## Project Context

### Paths

- Steering: `.kiro/steering/`
- Specs: `.kiro/specs/`

### Steering vs Specification

**Steering** (`.kiro/steering/`) - Guide AI with project-wide rules and context
**Specs** (`.kiro/specs/`) - Formalize development process for individual features

### Active Specifications

- Check `.kiro/specs/` for active specifications
- Use `/kiro:spec-status [feature-name]` to check progress

## Development Guidelines

- Think in English, generate responses in Japanese. All Markdown content written to project files (e.g., requirements.md, design.md, tasks.md, research.md, validation reports) MUST be written in the target language configured for this specification (see spec.json.language).

## Minimal Workflow

- Phase 0 (optional): `/kiro:steering`, `/kiro:steering-custom`
- Phase 1 (Specification):
  - `/kiro:spec-init "description"`
  - `/kiro:spec-requirements {feature}`
  - `/kiro:validate-gap {feature}` (optional: for existing codebase)
  - `/kiro:spec-design {feature} [-y]`
  - `/kiro:validate-design {feature}` (optional: design review)
  - `/kiro:spec-tasks {feature} [-y]`
- Phase 2 (Implementation): `/kiro:spec-impl {feature} [tasks]`
  - `/kiro:validate-impl {feature}` (optional: after implementation)
- Progress check: `/kiro:spec-status {feature}` (use anytime)

## Development Rules

- 3-phase approval workflow: Requirements → Design → Tasks → Implementation
- Human review required each phase; use `-y` only for intentional fast-track
- Keep steering current and verify alignment with `/kiro:spec-status`
- Follow the user's instructions precisely, and within that scope act autonomously: gather the necessary context and complete the requested work end-to-end in this run, asking questions only when essential information is missing or the instructions are critically ambiguous.

## Steering Configuration

- Load entire `.kiro/steering/` as project memory
- Default files: `product.md`, `tech.md`, `structure.md`
- Custom files are supported (managed via `/kiro:steering-custom`)

### Projects Analysis (CRITICAL)

When running `/kiro:steering` (Bootstrap or Sync mode), you MUST analyze the target projects:

- **Claude Code**: analyze subdirectories under `projects/`
- **Cursor**: analyze folders listed in `ai-workspace.code-workspace`

**Bootstrap Mode**:

1. Identify target projects from the appropriate source above
2. For each project:
   - Read `README.md` and project overview documentation
   - Identify tech stack (language, framework, runtime)
   - Extract architecture patterns (layered, feature-first, DDD, etc.)
   - Note naming conventions, import strategies
3. Merge patterns from all projects into steering files:
   - `tech.md`: Common frameworks, standards across projects
   - `structure.md`: Cross-project organization patterns
   - `product.md`: If projects share domain/purpose

**Sync Mode**:

- Check if new projects added
- Verify existing steering reflects current project patterns
- Report drift if projects diverged from steering

**Why**: This workspace manages multiple development repositories. Steering must capture patterns from actual codebases, not just workspace-level config.
