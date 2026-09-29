#!/usr/bin/env bash
# Symlink the skills in this repo's submodules into an OpenCode skills directory.

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
target="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills"
uninstall=0

usage() {
  cat <<'EOF'
Usage:
  ./install.sh                 install globally (~/.config/opencode/skills)
  ./install.sh --project DIR   install into DIR/.opencode/skills
  ./install.sh --target DIR    install into DIR directly
  ./install.sh --uninstall     remove links created by this script (combine with a target flag)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project|--target)
      [[ $# -ge 2 ]] || { echo "$1 needs a directory" >&2; exit 2; }
      if [[ "$1" == "--project" ]]; then
        [[ -d "$2" ]] || { echo "not a directory: $2" >&2; exit 2; }
        target="$2/.opencode/skills"
      else
        target="$2"
      fi
      shift 2 ;;
    --uninstall) uninstall=1; shift ;;
    -h|--help)   usage; exit 0 ;;
    *)           echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

# A skill is <submodule>/<name>/SKILL.md; OpenCode requires <name> to match the frontmatter name.
skills=()
for skill_md in "$repo_dir"/*/*/SKILL.md; do
  if [[ -f "$skill_md" ]]; then skills+=("$(dirname "$skill_md")"); fi
done

if [[ ${#skills[@]} -eq 0 ]]; then
  echo "No skills found. Run: git submodule update --init" >&2
  exit 1
fi

[[ $uninstall -eq 1 ]] || mkdir -p "$target"

status=0
for src in "${skills[@]}"; do
  dest="$target/$(basename "$src")"
  # Only touch symlinks that point into this repo.
  ours=0
  if [[ -L "$dest" && "$(readlink "$dest")" == "$repo_dir"/* ]]; then ours=1; fi

  if [[ $uninstall -eq 1 ]]; then
    if [[ $ours -eq 1 ]]; then
      rm "$dest"; echo "removed  $dest"
    elif [[ -e "$dest" || -L "$dest" ]]; then
      echo "skipped  $dest (not linked by this script)"
    fi
  elif [[ $ours -eq 1 && "$(readlink "$dest")" == "$src" ]]; then
    echo "ok       $dest"
  elif [[ $ours -eq 1 ]]; then
    ln -sfn "$src" "$dest"; echo "relinked $dest -> $src"
  elif [[ -e "$dest" || -L "$dest" ]]; then
    echo "conflict $dest exists and was not created by this script; skipping" >&2
    status=1
  else
    ln -s "$src" "$dest"; echo "linked   $dest -> $src"
  fi
done

exit $status
