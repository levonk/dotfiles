#!/usr/bin/env bats

# Tests for scripts/sync/ai-sync.bash
# Focus: reference generation, flattening conflicts, warnings, and delete-stale

setup() {
  export TMPDIR="${TMPDIR:-/tmp}"
  export TEST_ROOT="$(mktemp -d "$TMPDIR/ai-sync-test.XXXXXX")"
  export CHEZMOI_ROOT="$TEST_ROOT/home/current"
  export CHEZMOI_TEMPLATES_ROOT="$CHEZMOI_ROOT/.chezmoitemplates"
  mkdir -p "$CHEZMOI_TEMPLATES_ROOT/dot_config/ai/workflows/software-dev/frontend-dev"
  mkdir -p "$CHEZMOI_TEMPLATES_ROOT/dot_config/ai/workflows/backend"
}

teardown() {
  rm -rf "$TEST_ROOT"
}

@test "basic generation creates flattened .md.tmpl with correct include" {
  # create source file
  cat > "$CHEZMOI_TEMPLATES_ROOT/dot_config/ai/workflows/software-dev/frontend-dev/frontend-node.md" <<'MD'
# Frontend Node
MD
  run env CHEZMOI_ROOT="$CHEZMOI_ROOT" CHEZMOI_TEMPLATES_ROOT="$CHEZMOI_TEMPLATES_ROOT" bash "$BATS_TEST_DIRNAME/../sync/ai-sync.bash" --verbose
  [ "$status" -eq 0 ]

  dst1="$CHEZMOI_ROOT/dot_codeium/windsurf/global_workflows/frontend-node.md.tmpl"
  dst2="$CHEZMOI_ROOT/dot_codeium/windsurf-next/global_workflows/frontend-node.md.tmpl"

  [ -f "$dst1" ]
  [ -f "$dst2" ]

  expected='{{ includeTemplate "dot_config/ai/workflows/software-dev/frontend-dev/frontend-node.md" . }}'
  run cat "$dst1"
  [ "$status" -eq 0 ]
  [ "$output" = "$expected" ]

  run cat "$dst2"
  [ "$status" -eq 0 ]
  [ "$output" = "$expected" ]
}

@test "flatten conflict: second same-basename writes disambiguated file and warns" {
  # existing first source
  echo '# A' > "$CHEZMOI_TEMPLATES_ROOT/dot_config/ai/workflows/software-dev/frontend-dev/frontend-node.md"
  run env CHEZMOI_ROOT="$CHEZMOI_ROOT" CHEZMOI_TEMPLATES_ROOT="$CHEZMOI_TEMPLATES_ROOT" bash "$BATS_TEST_DIRNAME/../sync/ai-sync.bash" --verbose
  [ "$status" -eq 0 ]

  # second source with same basename in different dir
  echo '# B' > "$CHEZMOI_TEMPLATES_ROOT/dot_config/ai/workflows/backend/frontend-node.md"
  errlog="$BATS_TEST_TMPDIR/err.log"
  run env CHEZMOI_ROOT="$CHEZMOI_ROOT" CHEZMOI_TEMPLATES_ROOT="$CHEZMOI_TEMPLATES_ROOT" bash "$BATS_TEST_DIRNAME/../sync/ai-sync.bash" --verbose 2>"$errlog"
  [ "$status" -eq 0 ]

  # candidate (basename) should still exist for first
  cand="$CHEZMOI_ROOT/dot_codeium/windsurf/global_workflows/frontend-node.md.tmpl"
  [ -f "$cand" ]

  # disambiguated file should exist for second
  disamb="$CHEZMOI_ROOT/dot_codeium/windsurf/global_workflows/backend_frontend-node.md.tmpl"
  [ -f "$disamb" ]

  # stderr warning should mention existing, includes target, attempted, writing
  run grep -E "flatten conflict: existing=.*frontend-node.md.tmpl" "$errlog"
  [ "$status" -eq 0 ]
}

@test "delete-stale removes tmpl when source is missing" {
  echo '# C' > "$CHEZMOI_TEMPLATES_ROOT/dot_config/ai/workflows/software-dev/frontend-dev/stale.md"
  run env CHEZMOI_ROOT="$CHEZMOI_ROOT" CHEZMOI_TEMPLATES_ROOT="$CHEZMOI_TEMPLATES_ROOT" bash "$BATS_TEST_DIRNAME/../sync/ai-sync.bash" --verbose
  [ "$status" -eq 0 ]

  tmpl="$CHEZMOI_ROOT/dot_codeium/windsurf/global_workflows/stale.md.tmpl"
  [ -f "$tmpl" ]

  rm -f "$CHEZMOI_TEMPLATES_ROOT/dot_config/ai/workflows/software-dev/frontend-dev/stale.md"
  run env CHEZMOI_ROOT="$CHEZMOI_ROOT" CHEZMOI_TEMPLATES_ROOT="$CHEZMOI_TEMPLATES_ROOT" bash "$BATS_TEST_DIRNAME/../sync/ai-sync.bash" --verbose --delete-stale
  [ "$status" -eq 0 ]

  [ ! -f "$tmpl" ]
}
