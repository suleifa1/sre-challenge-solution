# deploy-helm.sh - Helm Charts Deployment

## Description

Deploys five independent Helm charts in the correct order. Uses `helm upgrade --install` for idempotent deployment. Automatically generates self-signed TLS certificates for Ingress.

## Prerequisites

- Kubernetes cluster running (eg. Minikube with Calico for NetworkPolicy support: `minikube start --cni=calico`)
- kubectl configured
- Helm 3.x installed
- Docker images built (`./scripts/build_minikube.sh`)
- openssl installed (for TLS certificate generation)

## Required Environment Variables

```bash
export DB_USERNAME=postgres
export DB_PASSWORD=your_password
./scripts/deploy-helm.sh
```

Both variables are required. The script will exit with an error if they are not set.

## Deployment Order

| Step | Component | Namespace | Notes |
| --- | --- | --- | --- |
| 1 | PostgreSQL | postgres | StatefulSet + PVC for data persistence |
| 2 | Kafka | kafka | StatefulSet + PVC, KRaft mode, topic created via Helm hook |
| 3 | Back | demo-back | Waits for PostgreSQL + Kafka via init containers |
| 4 | Front | demo-front | Waits for Kafka, HTTPS via Ingress |
| 5 | Reader | demo-reader | Waits for PostgreSQL + Back schema creation |

## What the Script Does

1. **Lints** all Helm charts (`helm lint`)
2. **Generates** self-signed TLS certificates for `front.local` and `reader.local`
3. **Deploys** each chart with credentials passed via `--set` (never stored in git)
4. **Cleans up** temporary certificate files on exit (via `trap`)

## Ordering Mechanism

`--wait` flag is not used. Ordering is ensured by:
- Init containers (`busybox nc`) verify dependency availability before app starts
- Kafka topic created via Helm `post-install` hook after Kafka is ready
- Back creates DB schema via Hibernate (`ddl-auto: update`)
- Reader validates schema presence (`ddl-auto: validate`)

## Security

- DB credentials passed via `--set` at deploy time, never committed to git
- TLS certificates generated locally and passed via `--set-file`, never committed to git
- NetworkPolicy enforced when `networkPolicy.enabled: true` (requires Calico CNI)

## Idempotency

Safe to re-run — `helm upgrade --install` updates existing releases without errors. Kafka topic created with `--if-not-exists`.

## Verify Deployment

```bash
kubectl get pods -A
./scripts/test_E2E.sh
```

## Cleanup

```bash
./scripts/teardown.sh
```

## Troubleshooting

| Error | Solution |
| --- | --- |
| `DB_PASSWORD is required` | Export env vars before running |
| Pending pods | Check PVC status: `kubectl get pvc -A` |
| Failed init containers | Check dependency logs: `kubectl logs -n <ns> <pod> -c <init-container>` |
| NetworkPolicy blocking traffic | Ensure Calico CNI: `minikube start --cni=calico` |
| TLS errors | Re-run deploy script to regenerate certificates |