#!/usr/bin/env bash
# projects/*/.codex/{skills,memories,prompts} を
# ワークスペース側 .codex/*/projects/<project>/ に symlink 同期する。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECTS_DIR="${WORKSPACE_ROOT}/projects"

sync_subdir() {
  local subdir="$1"
  local projects_root="${WORKSPACE_ROOT}/.codex/${subdir}/projects"

  # 毎回フルリビルドして、削除・リネームされたプロジェクト由来の取り残しを防ぐ。
  rm -rf "${projects_root}"
  mkdir -p "${projects_root}"
  if [[ ! -d "${PROJECTS_DIR}" ]]; then
    return
  fi

  while IFS= read -r project_dir; do
    local project_name
    project_name="$(basename "${project_dir}")"
    local project_subdir="${project_dir}/.codex/${subdir}"
    local link_root="${projects_root}/${project_name}"

    if [[ ! -d "${project_subdir}" ]]; then
      continue
    fi

    mkdir -p "${link_root}"
    while IFS= read -r entry_path; do
      local entry_name
      entry_name="$(basename "${entry_path}")"
      local link_path="${link_root}/${entry_name}"
      local rel_target="../../../../projects/${project_name}/.codex/${subdir}/${entry_name}"
      ln -sfn "${rel_target}" "${link_path}"
    done < <(find "${project_subdir}" -mindepth 1 -maxdepth 1)
  done < <(find "${PROJECTS_DIR}" -mindepth 1 -maxdepth 1 -type d)
}

# Codex は projects/*/.codex 配下を自動探索しないため、
# ワークスペース側 .codex/*/projects に symlink を張って明示的に読ませる。
sync_subdir "skills"
sync_subdir "memories"
sync_subdir "prompts"
