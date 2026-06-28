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

Each chart contains standard K8s resources: Deployment, Service, ConfigMap, Secret, Ingress (where applicable).

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
| Apache Kafka | 3.7.0 |
| IBM Semeru Runtime JRE | 21 |

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
- **Stage 2**: IBM Semeru Runtime JRE 21 (application runtime)

Resulting images contain only runtime without source code and build dependencies.

## Deployment

### Local Deployment (Minikube)

1. Switch Docker context to Minikube:
   ```bash
   eval $(minikube docker-env)
   ```

2. Build Docker images:
   ```bash
   ./scripts/build.sh
   ```
   The script switches Docker to Minikube and builds Front, Back, Reader images directly in Minikube (without external registry).

3. Deploy Helm charts:
   ```bash
   ./scripts/deploy-helm.sh
   ```
   The script executes `helm upgrade --install` for each chart in the specified order (idempotent).

4. Verify status:
   ```bash
   kubectl get pods -A
   kubectl get svc -A
   ```

### Production Adaptation

Recommended set of changes for deployment in production environment:

1. **Container registry**: use Docker Hub, ECR, GitHub Container Registry, or private registry
2. **ImagePullPolicy**: change from `Never` to `IfNotPresent` in `helm/*/values.yaml`
3. **Authentication**: add `imagePullSecrets` to Deployment if necessary
4. **CI/CD pipeline**: integrate image building and pushing to registry
5. **Network access**: Ingress (current solution) is marked as deprecated since Kubernetes 1.19. Migration to Gateway API using HTTPRoute is recommended for compatibility with future K8s versions. Requires Gateway API CRD and controller presence in the cluster.

## Network Access

**Ingress:**
Front and Reader use Nginx Ingress (built-in to Minikube) for external access.

**Configuration:**
```yaml
spec:
  rules:
  - host: front.local
    http:
      paths:
      - path: /
        backend:
          service:
            name: front
            port:
              number: 8080
```

**Access:**
- Add to `/etc/hosts`: `127.0.0.1 front.local reader.local`
- Or use port-forward: `kubectl port-forward -n demo-front svc/front 8080:8080`


## Helper Scripts

The following scripts are provided for deployment and testing automation:

- **build.sh** — switch to Minikube Docker and build images
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
   # For Minikube
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

