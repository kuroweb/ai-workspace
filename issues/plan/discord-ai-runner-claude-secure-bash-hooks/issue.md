# discord-ai-runner: Claude Hookで --dangerously-skip-permissions を安全運用する

- 作成日: 2026-03-05
- Category: タスク
- 実行対象: `projects/discord-ai-runner`（実配置パスに合わせる）

## 概要
`discord-ai-runner` で Claude 実行時に `--dangerously-skip-permissions` を使う前提とし、`.claude` の Hook（`PreToolUse`）で Bash 実行を実行前に検査・ブロックする安全運用を整備する。

## 背景
- `dangerously-skip-permissions` は利便性が高い一方、誤実行時の破壊範囲が大きい。
- 単一ガードではなく、runner側制御（prefix/thread制限）と Claude Hook 側制御（deny）を重ねる必要がある。
- 設定適用は Claude 実行時の `cwd` に依存するため、`spawn` 時の作業ディレクトリを明示して運用を安定化したい。

## 要件
1. `.claude/settings.local.json` に `hooks.PreToolUse`（`Bash`）と `permissions.deny` を定義すること。
2. `.claude/hooks/deny-check.sh` で Bash コマンドを検査し、拒否時は Hook仕様の拒否レスポンスを返すこと。
3. runner 側 dangerous 制御（`AI_ENABLE_DANGEROUS_MODE` / prefix / allowed threads / audit log）と整合すること。
4. `spawn('claude', ...)` の `cwd` を明示し、設定適用先が意図どおり固定されること。
5. ブロック/許可の判定結果が運用ログから追跡可能であること。

## 実装方針（案）
- 設定配置:
  - `discord-ai-runner/.claude/settings.local.json`
  - `discord-ai-runner/.claude/hooks/deny-check.sh`
- Hook実行パスは `CLAUDE_PROJECT_DIR` ベースで指定（相対パス依存を回避）。
- denyルールは初期は厳格に設定し、誤検知を見ながら allow を最小追加する。
- runner 側は現行の dangerous policy を維持し、二重防御にする。

## 受け入れ条件
- 正常系:
  - 安全な Bash コマンドは実行継続される。
  - dangerous prefix と許可スレッド条件を満たす場合のみ dangerous モードが有効になる。
- 異常系:
  - `sudo` / `rm -rf /` / `curl | sh` など拒否対象は実行前に停止される。
  - 非許可スレッドでは dangerous モードが無効化される。
  - Hookエラー時に fail-closed（停止）で運用できる。
- 運用:
  - dangerous 実行試行が監査ログに記録される。
  - 設定変更の反映手順（launchd再起動含む）が README で追える。

## タスク分解
- [ ] `.claude/settings.local.json` の初期テンプレート整備
- [ ] `.claude/hooks/deny-check.sh` 実装（実行権限付与含む）
- [ ] Claude adapter の `spawn` `cwd` 明示
- [ ] dangerous policy と Hook運用の整合確認
- [ ] 拒否/許可の動作確認ケース作成
- [ ] README に導入手順・ロールバック手順を追記

## リスクと対策
- リスク: deny を厳しくしすぎて運用停止する。
  - 対策: 段階導入（dry-run相当ログ確認 -> 本番拒否）、限定スレッドで先行適用。
- リスク: `cwd` ずれで `.claude` が読まれない。
  - 対策: adapterで `cwd` 明示 + 起動時ログで実ディレクトリを出力。
- リスク: 設定分散で管理が破綻する。
  - 対策: runner リポジトリ配下に設定を集約し、README に正本を明記。

## メモ
- 参照: https://wasabeef.jp/blog/claude-code-secure-bash
- 公式仕様との差分が出た場合は Anthropic Hooks 公式ドキュメントを優先する。
