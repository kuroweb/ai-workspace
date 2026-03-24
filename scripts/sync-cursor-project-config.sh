#!/usr/bin/env bash
# projects/*/.cursor/{skills,rules,commands,agents} を
# ワークスペース側 .cursor/*/projects/<project>/ に symlink 同期する。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECTS_DIR="${WORKSPACE_ROOT}/projects"

sync_subdir() {
  local subdir="$1"
  local projects_root="${WORKSPACE_ROOT}/.cursor/${subdir}/projects"

  mkdir -p "${projects_root}"

  # projects/ 自体が無いときは同期対象が無いのでここで終了するが、
  # 過去の実行で作られた .cursor/*/projects/<name>/ が残ると誤解を招くため掃除する。
  if [[ ! -d "${PROJECTS_DIR}" ]]; then
    local orphan
    while IFS= read -r -d '' orphan; do
      rm -rf "${orphan}"
    done < <(find "${projects_root}" -mindepth 1 -maxdepth 1 -print0 2>/dev/null || true)
    return
  fi

  # projects/ に無い名前のミラーだけ削除（プロジェクト削除・リネームの取り残し）
  local stale_root
  while IFS= read -r -d '' stale_root; do
    local stale_name
    stale_name="$(basename "${stale_root}")"
    if [[ ! -d "${PROJECTS_DIR}/${stale_name}" ]]; then
      rm -rf "${stale_root}"
    fi
  done < <(find "${projects_root}" -mindepth 1 -maxdepth 1 -print0 2>/dev/null || true)

  local project_dir
  while IFS= read -r -d '' project_dir; do
    [[ -d "${project_dir}" ]] || continue
    local project_name
    project_name="$(basename "${project_dir}")"
    local project_subdir="${project_dir}/.cursor/${subdir}"
    local link_root="${projects_root}/${project_name}"

    if [[ ! -d "${project_subdir}" ]]; then
      [[ -e "${link_root}" ]] && rm -rf "${link_root}"
      continue
    fi

    mkdir -p "${link_root}"

    # ソース側で消えたエントリに対応する symlink だけ削除（ln -sfn では消えない）
    local stale_link
    while IFS= read -r -d '' stale_link; do
      local entry_name
      entry_name="$(basename "${stale_link}")"
      if [[ ! -e "${project_subdir}/${entry_name}" && ! -L "${project_subdir}/${entry_name}" ]]; then
        rm -f "${stale_link}"
      fi
    done < <(find "${link_root}" -mindepth 1 -maxdepth 1 -print0 2>/dev/null || true)

    local entry_path
    while IFS= read -r -d '' entry_path; do
      local entry_name
      entry_name="$(basename "${entry_path}")"
      local link_path="${link_root}/${entry_name}"
      local rel_target="../../../../projects/${project_name}/.cursor/${subdir}/${entry_name}"
      ln -sfn "${rel_target}" "${link_path}"
    done < <(find "${project_subdir}" -mindepth 1 -maxdepth 1 -print0)
  done < <(find "${PROJECTS_DIR}" -mindepth 1 -maxdepth 1 -print0)
}

# Cursor が projects/*/.cursor を自動でマージしない場合に、
# ワークスペース側 .cursor/*/projects に symlink を張って集約する。
sync_subdir "skills"
sync_subdir "rules"
sync_subdir "commands"
sync_subdir "agents"
