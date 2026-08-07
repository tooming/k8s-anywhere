# Pin `gitlab-ce`/`gitlab-runner` to explicit versions (currently `:latest`)

(CHARTER **Core Values** §"Everything as code" + general hardening, mirroring
[ADR-0030](../decisions/adr-0030-pin-k3s-version-explicitly.md)'s explicit-pin
precedent; architect-fallback finding 2026-08-07, surfaced while researching
[ADR-0033](../decisions/adr-0033-gitlab-git-source-and-ci.md) — RFC #1073. **No
prerequisites — executor may pick up immediately.**) Verified directly (not assumed,
ADR-0004): `gitlab/docker-compose.yml` pins both the `gitlab` service
(`image: gitlab/gitlab-ce:latest`) and the `gitlab-runner` service
(`image: gitlab/gitlab-runner:latest`) to the floating `:latest` tag — the only two
always-on lab components still doing this; every other pinned dependency in this repo
(RabbitMQ, Valkey, Grafana, Tempo, Mimir, Loki, k3s itself per ADR-0030, etc.) uses an
explicit version tag. Un-pinned `:latest` means a routine `docker compose pull` +
`make gitlab-up` cycle can silently jump GitLab CE major versions with no PR, no
changelog review, and no rollback path recorded anywhere — the exact failure mode
ADR-0030 exists to prevent for k3s.

Pinned `gitlab/docker-compose.yml`'s `gitlab` service to `gitlab/gitlab-ce:19.2.1-ce.0`
and its `gitlab-runner` service to `gitlab/gitlab-runner:v19.2.1`. Added
`tests/gitlab-compose.bats` — a recurrence guard per CLAUDE.md's
bug-fix-prevents-recurrence rule, mirroring `tests/argocd-chart-pin.bats`'s exact-pin
assertion pattern — asserting neither service regresses to `:latest`, and that each
pins the exact version chosen here.

## Verification of the chosen versions (ADR-0004 — not assumed)

Fetched the Docker Hub tags API directly (this remote clusterless session cannot run
`docker compose pull` against a live daemon, so this is the closest real verification
available):

- `gitlab/gitlab-ce`'s `latest` tag's `tag_last_pushed` timestamp
  (`2026-07-29T10:47:20Z`) exactly matches `19.2.1-ce.0`'s own push timestamp
  (`2026-07-29T10:45:24Z`) — confirming `19.2.1-ce.0` is precisely what `:latest`
  itself resolves to today, so this pin changes nothing about what's actually running;
  it only removes the floating-tag footgun. (Newer-looking tags `18.11.9-ce.0`/
  `18.11.8-ce.0`, pushed 2026-08-05/06, are maintenance patches on the *prior* major
  release line, not the current major's newest release — not chosen, since pinning to
  an older major line would be a real regression, not a currency match.)
- `gitlab/gitlab-runner`'s `v19.2.1` tag exists and was pushed `2026-07-28T09:01:59Z`,
  one day ahead of the matching `gitlab-ce` release — aligned major.minor.patch with
  the `gitlab-ce` pin above, following GitLab's own convention of releasing CE and
  Runner on matching version numbers.

## Rollback path

Revert both pins; the next `make gitlab-up` re-pulls whatever `:latest` resolves to at
that time. This remote session cannot verify the pinned tags actually start healthy
end-to-end (GitLab CE's omnibus reconfigure, GitLab Runner's registration) — that's
the next `make gitlab-up` run's job, the same caveat pattern as every other
currency-bump PR in this repo.

## PR

(filled in after PR creation)
