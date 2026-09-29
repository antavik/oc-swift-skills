#!/usr/bin/env bash
# Pull the latest upstream changes into every submodule.
# Updated submodule pointers are left unstaged; review and commit them yourself.

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

git submodule update --init --remote

# Compares the submodule commits now checked out against those recorded in HEAD.
summary="$(git submodule summary)"

if [[ -z "$summary" ]]; then
  echo "Already up to date."
else
  echo "$summary"
fi
