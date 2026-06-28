# Scripts Documentation

This section contains documentation for each deployment and testing script.

## Contents

### Deployment and Management

| Script | Description |
|--------|---------|
| [build.sh](build.sh.md) | Build Docker images in Minikube |
| [deploy-helm.sh](deploy-helm.sh.md) | Deploy all Helm charts |
| [teardown.sh](teardown.sh.md) | Remove all deployed resources |

### Testing

| Script | Description |
|--------|---------|
| [test_E2E.sh](test_E2E.sh.md) | End-to-End testing of the system |

## Execution Order

### Initial Deployment

1. **build.sh** — build Docker images
2. **deploy-helm.sh** — deploy system
3. **test_E2E.sh** — verify functionality

### Re-deployment

```bash
./scripts/deploy-helm.sh  # Updates existing resources (idempotent)
./scripts/test_E2E.sh     # Verify functionality
```

### Cleanup

```bash
./scripts/teardown.sh  # Remove all resources
```

## Requirements

- Minikube (for local development)
- Kubernetes 1.19+
- Helm 3.x
- kubectl
- curl
- Docker (for Minikube)

## Troubleshooting

See the "Possible errors" section in documentation for each script.

## Additional Information

- **SOLUTION.md** — general description of architecture and solution
- **DEPLOYMENT.md** — detailed deployment information
- **CI_PIPELINE.md** — CI/CD pipeline information
