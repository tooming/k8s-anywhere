# Shared PostToolUse hook helper: extract tool_input.file_path (or .path) from
# the Claude Code hook JSON payload on stdin — sourced, not executed.
# Duplicated identically across 15 scripts/*-hook.sh scripts before this
# extraction; consolidated so a future payload-shape change only needs one edit.
hook_file_path() {
  local payload
  payload="$(cat 2>/dev/null || true)"
  printf '%s' "$payload" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || true
}
