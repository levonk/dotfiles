#!/usr/bin/env bats

# Tests for scripts/sync/template-sync.bash base-directory handling

setup() {
  export TMPDIR="${TMPDIR:-/tmp}"
  export TEST_ROOT="$(mktemp -d "$TMPDIR/template-sync-test.XXXXXX")"
  export SCRIPT_PATH="$BATS_TEST_DIRNAME/../sync/template-sync.bash"
}

teardown() {
  rm -rf "$TEST_ROOT"
}

@test "falls back to CHEZMOI roots when base overrides unset" {
  local src_base="$TEST_ROOT/chez_templates"
  local dest_base="$TEST_ROOT/chez_dest"
  mkdir -p "$src_base/dot_config/ai/workflows"
  printf '# Default\n' > "$src_base/dot_config/ai/workflows/default.md"

  local config="$TEST_ROOT/default.jsonc"
  cat > "$config" <<'JSON'
[
  {
    "name": "default-job",
    "src": "dot_config/ai/workflows",
    "dest": [
      "dot_codeium/windsurf/global_workflows"
    ]
  }
]
JSON

  run env CHEZMOI_TEMPLATES_ROOT="$src_base" CHEZMOI_ROOT="$dest_base" \
    bash "$SCRIPT_PATH" --config "$config"
  [ "$status" -eq 0 ]

  local generated="$dest_base/dot_codeium/windsurf/global_workflows/default.md.tmpl"
  [ -f "$generated" ]

  local expected='{{ includeTemplate "dot_config/ai/workflows/default.md" . }}'
  run cat "$generated"
  [ "$status" -eq 0 ]
  [ "$output" = "$expected" ]
}

@test "honors SRC_BASE and DEST_BASE overrides" {
  local src_base="$TEST_ROOT/src-env"
  local dest_base="$TEST_ROOT/dest-env"
  mkdir -p "$src_base/dot_config/ai/workflows"
  printf '# Env\n' > "$src_base/dot_config/ai/workflows/env.md"

  local config="$TEST_ROOT/env.jsonc"
  cat > "$config" <<'JSON'
[
  {
    "name": "env-job",
    "src": "dot_config/ai/workflows",
    "dest": [
      "dot_codeium/windsurf/global_workflows"
    ]
  }
]
JSON

  run env SRC_BASE="$src_base" DEST_BASE="$dest_base" \
    CHEZMOI_TEMPLATES_ROOT="$TEST_ROOT/unused-src" CHEZMOI_ROOT="$TEST_ROOT/unused-dest" \
    bash "$SCRIPT_PATH" --config "$config"
  [ "$status" -eq 0 ]

  local generated="$dest_base/dot_codeium/windsurf/global_workflows/env.md.tmpl"
  [ -f "$generated" ]

  local expected='{{ includeTemplate "dot_config/ai/workflows/env.md" . }}'
  run cat "$generated"
  [ "$status" -eq 0 ]
  [ "$output" = "$expected" ]
}

@test "per-job src_base and dest_base override global settings" {
  local global_src="$TEST_ROOT/global-src"
  local global_dest="$TEST_ROOT/global-dest"
  mkdir -p "$global_src"
  mkdir -p "$global_dest"

  local job_src="$TEST_ROOT/job-specific-src"
  local job_dest="$TEST_ROOT/job-specific-dest"
  mkdir -p "$job_src/dot_config/ai/workflows"
  printf '# Override\n' > "$job_src/dot_config/ai/workflows/override.md"

  local config="$TEST_ROOT/job.jsonc"
  cat > "$config" <<JSON
[
  {
    "name": "job-override",
    "src_base": "$job_src",
    "dest_base": "$job_dest",
    "src": "dot_config/ai/workflows",
    "dest": [
      "dot_codeium/windsurf/global_workflows"
    ]
  }
]
JSON

  run env SRC_BASE="$global_src" DEST_BASE="$global_dest" \
    bash "$SCRIPT_PATH" --config "$config"
  [ "$status" -eq 0 ]

  local generated="$job_dest/dot_codeium/windsurf/global_workflows/override.md.tmpl"
  [ -f "$generated" ]

  local expected='{{ includeTemplate "dot_config/ai/workflows/override.md" . }}'
  run cat "$generated"
  [ "$status" -eq 0 ]
  [ "$output" = "$expected" ]

  [ ! -d "$global_dest/dot_codeium" ]
}
