# Runbook — mint the `KUBECONFIG` Forgejo Actions secret for the O4 `verify-rejection` CI job

**Applies to:** `.forgejo/workflows/build-sign-push.yml`'s `verify-rejection` job
(CHARTER Objective O4, RFC #289). **Tracking issue:** #1229 (stays open until a
live-cluster session runs this and confirms a real workflow run completes).

## Prerequisite (already done, GitOps-managed)

The dedicated least-privilege RBAC is committed and synced by ArgoCD as part of
the `capstone` Application:

- `gitops/apps/capstone/ci-verify-rejection-rbac.yaml`
  - ServiceAccount `ci-verify-rejection` (namespace `capstone`)
  - Role `ci-verify-rejection` — `create`/`delete`/`get`/`list` on `pods`, in
    `capstone` only
  - RoleBinding `ci-verify-rejection`

Confirm it is live before continuing:

```bash
kubectl get sa,role,rolebinding ci-verify-rejection -n capstone
```

## Step 1 — mint a token for the ServiceAccount

`kubectl create token` issues a bound token. CI needs a long-lived one; the API
server caps the duration (`--service-account-max-token-expiration`, 1 year by
default), so this needs re-running on that cadence (or use the bound-Secret
variant in the appendix for a non-expiring token).

```bash
TOKEN=$(kubectl create token ci-verify-rejection -n capstone --duration=8760h)
```

## Step 2 — build the kubeconfig

Reuse the cluster's own CA and API server address so the kubeconfig validates
TLS normally:

```bash
CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')
API_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
CA_DATA=$(kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')

cat <<EOF > /tmp/ci-verify-rejection.kubeconfig
apiVersion: v1
kind: Config
clusters:
- name: ${CLUSTER_NAME}
  cluster:
    server: ${API_SERVER}
    certificate-authority-data: ${CA_DATA}
contexts:
- name: ci-verify-rejection
  context:
    cluster: ${CLUSTER_NAME}
    namespace: capstone
    user: ci-verify-rejection
current-context: ci-verify-rejection
users:
- name: ci-verify-rejection
  user:
    token: ${TOKEN}
EOF
```

Sanity-check it does exactly what the job needs and nothing more:

```bash
KUBECONFIG=/tmp/ci-verify-rejection.kubeconfig kubectl auth can-i create pods -n capstone   # yes
KUBECONFIG=/tmp/ci-verify-rejection.kubeconfig kubectl auth can-i delete pods -n capstone   # yes
KUBECONFIG=/tmp/ci-verify-rejection.kubeconfig kubectl auth can-i create deployments -n capstone   # no
KUBECONFIG=/tmp/ci-verify-rejection.kubeconfig kubectl auth can-i get secrets -n capstone   # no
```

## Step 3 — set the Forgejo Actions secret

Forgejo → the `lab/k8s-lab` repo → Settings → Actions → Secrets → Add Secret:

```
Name:  KUBECONFIG
Value: <contents of /tmp/ci-verify-rejection.kubeconfig>
```

Then `rm /tmp/ci-verify-rejection.kubeconfig`.

## Step 4 — trigger a run and confirm

Push any commit to `main` (or re-run the latest `build-sign-push` run from the
Forgejo Actions UI). Watch the `verify-rejection` job:

- **Expected PASS:** `PASS: unsigned image was correctly rejected at admission`
  — the `kubectl apply` of the unsigned test Pod is denied by Kyverno's
  `verifyImages` ClusterPolicy, and the job greps a real admission-webhook
  rejection reason out of the error.
- **Any other outcome** (Pod admitted, or denied for a non-Kyverno reason such
  as PSA or an RBAC `forbidden`) is a real failure that needs its own follow-up
  — do not paper over it by loosening RBAC.

If the job fails at the `kubectl apply` step with a NetworkPolicy-style
connection timeout to the API server (not an admission denial), the
forgejo-runner namespace's egress policy may need an allowance to
`kube-apiserver` — capture the exact error and open a follow-up; that is a
distinct concern from this credential.

## Step 5 — close the loop

Comment on issue #1229 with the observed job outcome (the PASS line, or the real
failure), then close it.

---

## Appendix — non-expiring token via a bound Secret

If re-minting yearly is undesirable, create a
`kubernetes.io/service-account-token` Secret and let the token controller
populate it. Keep this **out** of `gitops/` (ArgoCD's `selfHeal` on the
`capstone` app would fight the controller-populated `.data.token`); create it
directly:

```bash
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: ci-verify-rejection-token
  namespace: capstone
  annotations:
    kubernetes.io/service-account.name: ci-verify-rejection
type: kubernetes.io/service-account-token
EOF

TOKEN=$(kubectl get secret ci-verify-rejection-token -n capstone -o jsonpath='{.data.token}' | base64 -d)
```

Then continue from Step 2.
