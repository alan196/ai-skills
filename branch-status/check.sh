#!/bin/bash
# ponytail: todo el chequeo de branch en un solo comando; la IA solo razona si algo sale mal
set -u
cd "${1:-.}" || exit 1
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "no-git-repo"; exit 0; }

warn=""
git fetch --quiet 2>/dev/null || warn=" warn=fetch_fallo(offline?)"

branch=$(git rev-parse --abbrev-ref HEAD)
wip=$([ -n "$(git status --porcelain)" ] && echo si || echo no)

if git rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
  read -r behind ahead <<<"$(git rev-list --left-right --count '@{u}...HEAD')"
  upstream="ahead=$ahead behind=$behind"
else
  upstream="upstream=no(sin_push)"
fi

default=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')
if [ -z "$default" ]; then
  for b in production main master; do
    git show-ref -q "refs/remotes/origin/$b" && { default=$b; break; }
  done
fi

merged=""
if [ -n "$default" ] && [ "$branch" != "$default" ]; then
  if git merge-base --is-ancestor HEAD "origin/$default" 2>/dev/null; then
    merged=" merged_en_$default=si"
  else
    merged=" merged_en_$default=no"
  fi
fi

echo "branch=$branch $upstream wip=$wip$merged$warn"
