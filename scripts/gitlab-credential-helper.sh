#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
TOKEN_FILE="$ROOT/gitlab/.gitlab-token"

action="${1:-get}"
host=""
username=""

while IFS='=' read -r key value; do
  [ -z "${key:-}" ] && break
  case "$key" in
    host) host="$value" ;;
    username) username="$value" ;;
  esac
done

case "$action" in
  get)
    [ "$host" = "localhost:8929" ] || exit 0
    [ "$username" = "root" ] || exit 0
    [ -s "$TOKEN_FILE" ] || exit 0
    printf 'username=root\n'
    printf 'password=%s\n' "$(cat "$TOKEN_FILE")"
    ;;
  store|erase)
    exit 0
    ;;
esac
