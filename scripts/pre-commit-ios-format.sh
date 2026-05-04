#!/usr/bin/env sh
set -e

staged_files=$(git diff --cached --name-only --diff-filter=ACMR | grep -E '^apps/ios/(Project\.swift|Tuist/Package\.swift|Sources/.+\.swift|Tests/.+\.swift)$' || true)

if [ -z "$staged_files" ]; then
  exit 0
fi

if ! command -v swiftformat >/dev/null 2>&1; then
  echo "pre-commit: SwiftFormat is required for iOS changes."
  echo "Install it with: brew install swiftformat"
  exit 1
fi

unstaged_files=""
while IFS= read -r file; do
  [ -z "$file" ] && continue
  if ! git diff --quiet -- "$file"; then
    unstaged_files="${unstaged_files}${file}\n"
  fi
done <<EOF
$staged_files
EOF

if [ -n "$unstaged_files" ]; then
  echo "pre-commit: these staged iOS files also have unstaged changes:"
  printf "%b" "$unstaged_files"
  echo "Please stage or stash them, then commit again."
  exit 1
fi

echo "pre-commit: formatting staged iOS files with SwiftFormat"
while IFS= read -r file; do
  [ -z "$file" ] && continue
  swiftformat --config apps/ios/.swiftformat "$file"
  git add -- "$file"
done <<EOF
$staged_files
EOF
