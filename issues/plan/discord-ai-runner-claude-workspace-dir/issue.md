# discord-ai-runner: workspaceDir で追加 CLAUDE.md をロードする

- 作成日: 2026-03-08
- Category: タスク
- 実行対象: `discord-ai-runner-claude`

## 概要

Claude サブプロセス起動時に `workspaceDir`（例: `~/environment/ai-workspace`）を指定することで、そのディレクトリの `CLAUDE.md` を追加ロードできるようにする。

## 背景

- discord-ai-runner の cwd は `discord-ai-runner-claude` で固定し、bot 挙動ルールは discord-ai-runner の `CLAUDE.md` でコントロールする。
- 作業対象のプロジェクト（ai-workspace など）のルールも Claude に読ませたい。
- `--add-dir` + `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` で追加ディレクトリの `CLAUDE.md` をロードできることを確認済み。
- env var なしでは動作が不安定（モデルの自己申告が揺れる）なので env var は必須。

## 要件

1. `state.json` に `workspaceDir` フィールドを追加し、永続化・復元できること。
2. `workspaceDir` が設定されている場合、spawn 時に `--add-dir workspaceDir` を引数に追加すること。
3. spawn 時の env に `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` を付与すること。
4. `workspaceDir` が未設定の場合は従来動作と同じであること。

## 実装方針

- `state.ts`: `PersistedState` に `workspaceDir?: string` を追加し、load/save に対応。
- `adapter.ts`: `spawn` の第3引数 `env` に `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD: '1'` を追加。`workspaceDir` を受け取れるよう引数を拡張。
- `args.ts`: `workspaceDir` が渡された場合に `['--add-dir', workspaceDir]` を args に追加。

### 想定ファイル変更

```text
src/
├── adapters/
│   └── claude/
│       ├── adapter.ts   # spawn env + workspaceDir 受け渡し
│       └── args.ts      # --add-dir 追加
└── bot/
    └── state.ts         # workspaceDir フィールド追加
```

## 受け入れ条件

- `workspaceDir` を state.json に設定した状態で bot を起動すると、ai-workspace の `CLAUDE.md` が読み込まれる。
- `workspaceDir` 未設定時は従来と同じ動作（discord-ai-runner の `CLAUDE.md` のみ）。

## タスク分解

- [ ] `state.ts` に `workspaceDir` を追加
- [ ] `adapter.ts` に env と workspaceDir 受け渡しを追加
- [ ] `args.ts` に `--add-dir` 追加
- [ ] 動作確認（workspaceDir あり／なし）
