# Scripts Documentation

## Contents

### Deployment and Management

| Script | Description |
| --- | --- |
| [build_minikube.sh](build.sh.md) | Build Docker images directly in Minikube (local only) |
| [deploy-helm.sh](deploy-helm.sh.md) | Deploy all Helm charts |
| [teardown.sh](teardown.sh.md) | Remove all deployed resources |

### Testing

| Script | Description |
| --- | --- |
| [test_E2E.sh](test_E2E.sh.md) | End-to-End testing of the system |

## Execution Order

### Initial Deployment

```bash
# 1. Start Minikube with Calico (required for NetworkPolicy)
minikube start --cni=calico
minikube addons enable ingress

# 2. Build images
./scripts/build_minikube.sh

# 3. Deploy
export DB_USERNAME=postgres
export DB_PASSWORD=your_password
./scripts/deploy-helm.sh

# 4. Verify
./scripts/test_E2E.sh
```

### Re-deployment

```bash
./scripts/deploy-helm.sh  # idempotent
./scripts/test_E2E.sh
```

### Cleanup

```bash
./scripts/teardown.sh
```

## Requirements

- Minikube with Calico CNI (`minikube start --cni=calico`)
- Kubernetes 1.21+
- Helm 3.x
- kubectl
- curl
- Docker
- openssl (TLS certificate generation)