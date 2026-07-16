# Documentation - SRE Challenge

### Scripts

- **[scripts/](scripts/)** — detailed documentation for each deployment script:
  - [build_minikube.sh](scripts/build.sh.md) — build Docker images (Minikube local only)
  - [deploy-helm.sh](scripts/deploy-helm.sh.md) — deploy Helm charts
  - [teardown.sh](scripts/teardown.sh.md) — remove resources
  - [test_E2E.sh](scripts/test_E2E.sh.md) — system testing
- **[deploying-to-other-environments.md](./deploying-to-other-environments.md)** - guide for deploying to non-Minikube clusters (EKS, GKE, AKS, bare-metal)
