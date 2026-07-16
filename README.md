# SRE Challenge - Solution

## Solution Architecture

The solution consists of 5 independent Helm charts, each deployed in a separate namespace:

```
helm/
├── postgres/                    (namespace: postgres)
├── kafka/                       (namespace: kafka)
├── back/                        (namespace: demo-back)
├── front/                       (namespace: demo-front)
└── reader/                      (namespace: demo-reader)
```

Each chart contains standard K8s resources: Deployment/StatefulSet, Service, ConfigMap, Secret, NetworkPolicy, Ingress (where applicable).

## Component Versions

The following versions are used in this solution:

| Component | Version |
|-----------|---------|
| Minikube | v1.37.0 |
| Kubernetes | v1.34.0 (Server), v1.34.1 (Client) |
| Helm | 3.x |
| Docker | latest |
| Java | 21+ |
| Gradle | 8.5 |
| Spring Boot | 3.5.6 |
| Kotlin | 1.9.25 |
| PostgreSQL | 16 |
| Apache Kafka | 3.7.0 (KRaft mode) |
| IBM Semeru Runtime JRE | open-21.0.11.0-jre-jammy |

### Architecture Rationale

**Separation into independent charts:**
- Independent lifecycle management for each component
- Namespace isolation provides separation of concerns
- Cross-namespace communication via FQDN (Service DNS)
- Simplified scaling of individual components

**Cross-namespace communication:**
Dependencies between components are defined in `values.yaml` of each chart as FQDN addresses:
```yaml
dependencies:
  postgres:
    host: postgresql.postgres.svc.cluster.local
    port: 5432
```

## Deployment Order

Deployment is performed sequentially by the `deploy-helm.sh` script:

```
1. PostgreSQL    (namespace: postgres)
2. Kafka         (namespace: kafka) → Helm hook creates topic
3. Back          (namespace: demo-back) → waits for postgres + kafka
4. Front         (namespace: demo-front) → waits for kafka
5. Reader        (namespace: demo-reader) → waits for back
```

**Ordering mechanism:**
- Init containers (`busybox nc`) verify dependency availability
- Kafka init job (Helm hook `post-install`) creates topic with `--if-not-exists` flag (idempotent)
- Back creates DB schema via Hibernate (`ddl-auto: update`)
- Reader verifies schema presence (`ddl-auto: validate`)

The `--wait` flag is not required, as init containers ensure proper ordering within the cluster.

## Docker Images

Dockerfiles use two-stage builds (multi-stage build):
- **Stage 1**: Gradle 8.5 + JDK 21 (compilation and JAR build)
- **Stage 2**: IBM Semeru Runtime JRE `open-21.0.11.0-jre-jammy` (pinned tag)

Images run as non-root user (`appuser`, UID 1000) and contain only runtime without source code and build dependencies.

## Security

- **Non-root containers**: all pods run as UID 1000 (`runAsNonRoot: true`)
- **Dropped capabilities**: `allowPrivilegeEscalation: false`, all Linux capabilities dropped
- **Secrets**: DB credentials passed via `--set` at deploy time, never stored in git
- **TLS**: HTTPS termination at Ingress with auto-generated self-signed certificates
- **NetworkPolicy**: ingress-only restrictions per component (requires Calico CNI: `minikube start --cni=calico`)

## Persistence

PostgreSQL and Kafka run as **StatefulSet** with **PersistentVolumeClaims** — data survives pod restarts and rolling upgrades.

## Deployment
### Local Deployment (Minikube)

**Prerequisites:**

```bash
minikube start --cni=calico
minikube addons enable ingress
minikube addons enable storage-provisioner
minikube addons enable default-storageclass
```

**Required environment variables:**

```bash
export DB_USERNAME=postgres
export DB_PASSWORD=your_password
```

> For deployment to other Kubernetes environments (EKS, GKE, AKS, bare-metal) see [docs/deploying-to-other-environments.md](docs/deploying-to-other-environments.md)

1. Build Docker images:
   ```bash
   ./scripts/build_minikube.sh
   ```
   Builds Front, Back, Reader images directly in Minikube (no external registry required).

2. Deploy Helm charts:
   ```bash
   ./scripts/deploy-helm.sh
   ```
   Lints charts, generates TLS certificates, deploys all components in correct order.

3. Verify status:
   ```bash
   kubectl get pods -A
   ./scripts/test_E2E.sh
   ```

### Production Adaptation

Recommended changes for production deployment:

1. **Container registry** — use Docker Hub, ECR, GCR or private registry
2. **Image** — update `app.image` in `helm/*/values.yaml`
3. **ImagePullPolicy** — change from `Never` to `IfNotPresent`
4. **imagePullSecrets** — add registry credentials if needed:
   ```yaml
   app:
     imagePullSecrets:
       - name: registry-credentials
   ```
5. **Secrets** — use Sealed Secrets or External Secrets Operator instead of `--set`
6. **NetworkPolicy** — already implemented, requires Calico or Cilium CNI
7. **TLS** — replace self-signed certs with cert-manager + Let's Encrypt
8. **Network access** — Ingress NGINX was retired by SIG Network in March 2026, migration to Gateway API (HTTPRoute) is recommended for production

## Network Access

**Ingress:**
Front and Reader use Nginx Ingress (built-in to Minikube) for external access with TLS termination.

**Access:**
- Add to `/etc/hosts`: `127.0.0.1 front.local reader.local`
- Front: `https://front.local`
- Reader: `https://reader.local`
- Or use port-forward via Ingress controller:
  ```bash
  kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8443:443
  curl -k https://localhost:8443/health -H "Host: front.local"
  ```

## Helper Scripts

The following scripts are provided for deployment and testing automation:

- **build_minikube.sh** — build images in Minikube (local only, no registry)
- **deploy-helm.sh** — deploy all 5 charts in proper order
- **teardown.sh** — remove all deployed resources
- **test_E2E.sh** — end-to-end tests of the application

For detailed information on each script, see [docs/scripts/](docs/scripts/)

## Deployment Idempotency

Deployment is fully idempotent:
- `helm upgrade --install` is safe on re-execution
- Kafka topic created with `--if-not-exists` flag
- Database migrations (Back: `ddl-auto: update`, Reader: `ddl-auto: validate`)

Re-running `deploy-helm.sh` updates existing resources without errors.

## Scaling

### Current State

Each microservice (Front, Back, Reader) is deployed with a fixed number of replicas:

```yaml
replicaCount: 1
```

Horizontal Pod Autoscaling (HPA) is not configured in the current solution.

### Scaling Adaptation

To add HPA, the following is required:

1. **Metrics Server** in the cluster:
   ```bash
   minikube addons enable metrics-server
   ```

2. **HPA resources** for each service (Front, Back, Reader):
   ```yaml
   apiVersion: autoscaling/v2
   kind: HorizontalPodAutoscaler
   metadata:
     name: front-hpa
     namespace: demo-front
   spec:
     scaleTargetRef:
       apiVersion: apps/v1
       kind: Deployment
       name: front
     minReplicas: 1
     maxReplicas: 3
     metrics:
     - type: Resource
       resource:
         name: cpu
         target:
           type: Utilization
           averageUtilization: 70
   ```

PostgreSQL and Kafka do not require horizontal scaling in the context of this solution.

## Resource Cleanup

```bash
./scripts/teardown.sh
```

The script removes all Helm releases and namespaces.