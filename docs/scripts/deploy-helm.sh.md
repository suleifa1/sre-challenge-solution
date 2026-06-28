# deploy-helm.sh - Helm Charts Deployment

## Description

The script deploys five Helm charts in the correct order, ensuring proper initialization of all system components. Uses `helm upgrade --install` command for idempotent deployment.

## Prerequisites

- Kubernetes cluster running (Minikube, EKS, GKE or other)
- kubectl configured and has cluster access
- Helm 3.x installed
- Docker images built and available (see build.sh)

## Usage

```bash
./scripts/deploy-helm.sh
```

## Execution Process

The script deploys components sequentially in the following order:

### 1. PostgreSQL (namespace: postgres)
- Creates `postgres` namespace
- Deploys PostgreSQL Deployment and Service
- Service available at: `postgresql.postgres.svc.cluster.local:5432`

### 2. Kafka (namespace: kafka)
- Creates `kafka` namespace
- Deploys Kafka Deployment and Service
- After deployment, Helm hook creates Kafka topic `testCommand` (32 partitions, replication factor 1)
- Service available at: `kafka.kafka.svc.cluster.local:9092`

### 3. Back (namespace: demo-back)
- Creates `demo-back` namespace
- Init container waits for PostgreSQL and Kafka availability
- Deploys Back Deployment with ConfigMap and Secret
- Back creates DB schema via Hibernate on first run
- Service available at: `back.demo-back.svc.cluster.local:8082`

### 4. Front (namespace: demo-front)
- Creates `demo-front` namespace
- Init container waits for Kafka availability
- Deploys Front Deployment with ConfigMap and Ingress
- Available through Ingress on host `front.local`

### 5. Reader (namespace: demo-reader)
- Creates `demo-reader` namespace
- Init container waits for PostgreSQL and Back availability (to verify schema presence)
- Deploys Reader Deployment with ConfigMap, Secret and Ingress
- Available through Ingress on host `reader.local`

## Idempotency

The script is fully idempotent. Re-running:
- Updates existing Helm releases
- Does not create duplicate resources
- Applies new values from `values.yaml` if they were changed

## Verification of Results

After successful script execution, use the test script to verify functionality:

```bash
./scripts/test_E2E.sh
```

The script will check the availability of all components, correctness of interactions between services, and data processing integrity.

## Configuration

Deployment parameters are defined in `helm/*/values.yaml` of each chart:
- Resources (CPU, memory)
- Image versions
- Dependencies (FQDN addresses of services)
- Application configuration

## Clean

To rollback deployment use `teardown.sh` script or manually:

```bash
helm uninstall <release-name> -n <namespace>
```

## Possible Errors

| Error | Solution |
|-------|----------|
| Helm release conflict | Use `helm uninstall` before re-deploying |
| Pending pods | Check cluster resources (`kubectl top nodes`) |
| Failed init containers | Verify dependency availability (PostgreSQL, Kafka) |
