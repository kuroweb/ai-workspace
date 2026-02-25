Please also reference the following rules as needed. The list below is provided in TOON format, and `@` stands for the project root directory.

rules[1]:
  - path: @.codex/memories/git-command.md
    description: config/settings.yaml の git_command に基づく git コマンド実行制限
    applyTo[1]: **/*

# Additional Conventions Beyond the Built-in Functions

As this project's AI coding tool, you must follow the additional conventions below, in addition to the built-in functions.

# ai-workspace 概要

複数プロジェクト横断で開発するためのワークスペース。

- **開発対象リポジトリ**: `projects/` 配下に配置（シンボリックリンクまたはクローン）
- **設定管理**: `config/settings.yaml` を参照

## 複数プロジェクト開発

このワークスペースは **Cursor のマルチルートワークスペースのような複数プロジェクト開発** を意図しています。

- **プロジェクト配置**: `projects/` 配下に複数のリポジトリを配置
  - シンボリックリンクまたはクローンで配置
  - 例: `projects/app-frontend/`, `projects/api-backend/`, `projects/shared-lib/`
- **共通AI設定**: すべてのプロジェクトに対して統一された AI エージェント設定（`.cursor/`, `.claude/`, `.codex/`）が適用される
- **横断的開発**: プロジェクト間を横断した機能開発・リファクタリングが可能
- **統合管理**: ワークスペースレベルで Kiro Spec、Steering、ルール、スキルを一元管理

各プロジェクトは独立したリポジトリとして git 管理されつつ、AI 開発環境は ai-workspace で統一されます。

## rulesync

このワークスペースは **rulesync** を使用して AI エージェント設定を管理しています。

- **編集正本**: `.rulesync/` で管理
- **生成先**: `.cursor/`, `.claude/`, `.codex/`
- **コマンド**: `rulesync generate` で各エージェントディレクトリに展開

詳細な管理対象は `rulesync.jsonc` を参照してください。

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

When running `/kiro:steering` (Bootstrap or Sync mode), you MUST analyze `projects/` subdirectories:

**Bootstrap Mode**:

1. Check if `projects/` exists and contains subdirectories (symlinks or clones)
2. For each project in `projects/`:
   - Read `README.md` and project overview documentation
   - Identify tech stack (language, framework, runtime)
   - Extract architecture patterns (layered, feature-first, DDD, etc.)
   - Note naming conventions, import strategies
3. Merge patterns from all projects into steering files:
   - `tech.md`: Common frameworks, standards across projects
   - `structure.md`: Cross-project organization patterns
   - `product.md`: If projects share domain/purpose

**Sync Mode**:

- Check if new projects added to `projects/`
- Verify existing steering reflects current project patterns
- Report drift if projects diverged from steering

**Why**: This workspace manages multiple development repositories. Steering must capture patterns from actual codebases, not just workspace-level config.
