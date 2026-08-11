#!/usr/bin/env bash
# k3s embedded datastore (SQLite/kine) health check.
#
# 2026-08-11 incident (docs/incident-log.md): while debugging an unrelated
# Harbor/Kyverno issue on k3d-k8s-lab-server-0 (25 days uptime at the time), `docker
# logs` showed "Slow SQL" warnings for basic kine-table queries (SELECT MAX(id),
# compact_rev_key lookups) taking 1-48 SECONDS instead of sub-millisecond, alongside
# apiserver TLS handshake timeouts, "FinishRequest ... context deadline exceeded", and
# "apiserver was unable to write a JSON response: http: Handler timeout" — i.e. kine
# query latency was degrading the WHOLE control plane, not just one pod. Root cause,
# confirmed live: k3s's kine background compactor normally runs every ~5 min (visible
# as "COMPACT compacted from X to Y" log lines) but had gone completely silent — no
# COMPACT line of any kind, success or failure — for 16 STRAIGHT DAYS, after a burst of
# "Compact failed: failed to record compact revision: sql: transaction has already been
# committed or rolled back" errors on 2026-07-25. state.db had grown to 505MB with an
# 82MB uncheckpointed WAL. A k3s server restart earlier that same day had only bought
# ~6 hours of healthy compaction before it silently died again — so a restart is not a
# durable fix on its own, only a way to buy time. See docs/DR.md's "Recovery cookbook"
# for remediation options and docs/incident-log.md for the full incident record.
#
# This script talks to the k3d server container directly via `docker logs`/`docker
# exec` — deliberately NOT via kubectl. The entire point of this check is to catch
# datastore degradation that is ITSELF the reason kubectl/apiserver calls are timing
# out, so a kubectl-based health check cannot be trusted to diagnose it (during the
# incident above, `kubectl get nodes` failed with a TLS handshake timeout while this
# script's docker-log checks still worked fine).
#
# Checks three signals, read-only (never writes to or vacuums the datastore — per
# ADR-0004 and docs/DR.md, live datastore surgery is a deliberate interactive-session
# call, never something to automate blind):
#   1. state.db (+ -wal/-shm) size on disk — informational unless STATE_DB_MAX_MB is set
#      (there's no single "too big" threshold: an empty lab and one with weeks of
#      ArgoCD/Kyverno churn have very different healthy baselines).
#   2. Gap since the last successful "COMPACT compacted from X to Y" log line — the
#      actual root-cause signal above. Failing past COMPACT_GAP_MAX_MIN (default 30;
#      k3s's internal cadence is ~5 min) means the background compactor has stalled.
#   3. Count of "Slow SQL" warnings in the most recent SLOW_SQL_TAIL_LINES log lines
#      (default 5000) — a handful during a genuinely large sync burst can be normal;
#      SLOW_SQL_WARN (default 5) or more sub/multi-second warnings signals the same
#      degradation class as the incident above.
#
# `docker logs --since` was tried first and found unreliable in this lab's Colima/k3d
# setup (returned zero lines even for a window with confirmed activity, no clock skew
# involved) — so recency is derived by parsing log timestamps directly instead of
# trusting the docker CLI's own time filtering.
#
# Deliberately NOT wired into `make ci` — it needs a live k3d container (`docker
# logs`/`docker exec`), which the clusterless CI gate cannot reach (ROADMAP rule #2).
# Run it by hand, or via `make health` (informational section, mirrors
# ondemand-budget-check.sh's role in lab-health-check.sh).
#
# Usage:
#   k3s-datastore-health-check.sh                        report against k8s-lab (blue)
#   CLUSTER=k8s-lab-green k3s-datastore-health-check.sh   report against green
set -uo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
ok()   { printf '  %s✓%s %s\n' "$G" "$Z" "$1"; }
bad()  { printf '  %s✗%s %s\n' "$R" "$Z" "$1"; }
note() { printf '      %s%s%s\n' "$Y" "$1" "$Z"; }

CLUSTER="${CLUSTER:-k8s-lab}"
CONTAINER="k3d-${CLUSTER}-server-0"
COMPACT_GAP_MAX_MIN="${COMPACT_GAP_MAX_MIN:-30}"
SLOW_SQL_TAIL_LINES="${SLOW_SQL_TAIL_LINES:-5000}"
SLOW_SQL_WARN="${SLOW_SQL_WARN:-5}"
STATE_DB_MAX_MB="${STATE_DB_MAX_MB:-0}"   # 0 = report only, never fail on size alone

command -v docker >/dev/null 2>&1 || { echo "docker not installed — cannot check k3s datastore health"; exit 2; }
docker inspect "$CONTAINER" >/dev/null 2>&1 || {
  bad "container $CONTAINER not running — is the cluster up?"
  note "make up (blue), or CLUSTER=k8s-lab-green $(basename "$0") for the green cluster"
  exit 2
}

printf '%s== k3s embedded datastore health (%s) ==%s\n' "$B" "$CONTAINER" "$Z"
fail=0

# --- 1. state.db (+ WAL/SHM) size -----------------------------------------------
DB_PATH=/var/lib/rancher/k3s/server/db/state.db
DB_BYTES="$(docker exec "$CONTAINER" sh -c "stat -c '%s' '$DB_PATH' 2>/dev/null")"
if [ -z "$DB_BYTES" ]; then
  bad "could not read state.db from $CONTAINER — is it using the default sqlite/kine datastore (not etcd)?"
  fail=1
else
  DB_MB=$(( DB_BYTES / 1024 / 1024 ))
  for suffix in "" -wal -shm; do
    b="$(docker exec "$CONTAINER" sh -c "stat -c '%s' '${DB_PATH}${suffix}' 2>/dev/null")"
    [ -n "$b" ] && note "state.db${suffix:-}: $(( b / 1024 / 1024 ))MB"
  done
  if [ "$STATE_DB_MAX_MB" -gt 0 ] && [ "$DB_MB" -gt "$STATE_DB_MAX_MB" ]; then
    bad "state.db is ${DB_MB}MB, over the configured STATE_DB_MAX_MB=${STATE_DB_MAX_MB}MB"
    fail=1
  else
    ok "state.db size: ${DB_MB}MB"
  fi
fi

# --- 2. gap since the last successful compaction ---------------------------------
# Full-log scan (docker logs --since proved unreliable here) — on a long-running,
# rarely-restarted node the log can be large, so this can take several seconds; that
# cost is itself informative (a very slow scan alongside a stale COMPACT line is
# consistent with the same disk-contention symptoms this check exists to catch).
LAST_COMPACT_LINE="$(docker logs "$CONTAINER" 2>&1 | grep -F 'COMPACT compacted from' | tail -1)"
if [ -z "$LAST_COMPACT_LINE" ]; then
  bad "no successful 'COMPACT compacted' log line found anywhere in current container logs"
  note "the background compactor may never have run, or logs have rotated past it"
  fail=1
else
  LAST_TS="$(printf '%s' "$LAST_COMPACT_LINE" | grep -oE '^time="[^"]+"' | sed 's/time="//;s/"$//')"
  LAST_EPOCH="$(date -u -d "$LAST_TS" +%s 2>/dev/null || date -u -jf '%Y-%m-%dT%H:%M:%SZ' "$LAST_TS" +%s 2>/dev/null)"
  if [ -z "$LAST_EPOCH" ]; then
    note "could not parse last compaction timestamp ('$LAST_TS') — skipping gap check"
  else
    GAP_MIN=$(( ( $(date -u +%s) - LAST_EPOCH ) / 60 ))
    if [ "$GAP_MIN" -gt "$COMPACT_GAP_MAX_MIN" ]; then
      bad "last successful compaction was ${GAP_MIN}min ago ($LAST_TS) — over COMPACT_GAP_MAX_MIN=${COMPACT_GAP_MAX_MIN}min"
      note "the background compactor has likely stalled — see docs/DR.md recovery cookbook (k3s embedded datastore)"
      fail=1
    else
      ok "last successful compaction ${GAP_MIN}min ago ($LAST_TS)"
    fi
  fi
fi

# --- 3. recent Slow SQL warning volume --------------------------------------------
SLOW_COUNT="$(docker logs --tail "$SLOW_SQL_TAIL_LINES" "$CONTAINER" 2>&1 | grep -c 'level=warning msg="Slow SQL' || true)"
if [ "$SLOW_COUNT" -ge "$SLOW_SQL_WARN" ]; then
  bad "$SLOW_COUNT 'Slow SQL' warnings in the last $SLOW_SQL_TAIL_LINES log lines (threshold $SLOW_SQL_WARN)"
  note "kine queries are running multi-second, not sub-millisecond — see docs/DR.md recovery cookbook"
  fail=1
else
  ok "$SLOW_COUNT 'Slow SQL' warnings in the last $SLOW_SQL_TAIL_LINES log lines"
fi

echo
if [ "$fail" -eq 0 ]; then
  printf '%s%sDATASTORE HEALTH: PASS%s\n' "$B" "$G" "$Z"
else
  printf '%s%sDATASTORE HEALTH: FAIL%s — see docs/DR.md recovery cookbook (k3s embedded datastore) for remediation options.\n' "$B" "$R" "$Z"
fi
exit "$fail"
