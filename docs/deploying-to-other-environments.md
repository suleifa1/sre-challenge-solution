# Deploying to Non-Minikube Environments

The solution is not Minikube-specific and can be deployed to any Kubernetes cluster (EKS, GKE, AKS, bare-metal, k3s, etc.).

## Cluster Requirements

**CNI with NetworkPolicy support**

The solution uses NetworkPolicy for network isolation. Your CNI plugin must support it. Popular options: Calico, Cilium, Weave. Default CNI in many managed clusters (EKS with VPC CNI, GKE) does not support NetworkPolicy out of the box — check your provider's documentation.

If NetworkPolicy is not required, set `networkPolicy.enabled: false` in each chart's `values.yaml`.

**Ingress Controller**

Front and Reader are exposed via Ingress. The solution uses `ingressClassName: nginx` — deploy any compatible Nginx Ingress controller or update `ingress.className` in values to match your environment.

**Storage**

PostgreSQL and Kafka use PersistentVolumeClaims (`ReadWriteOnce`). A storage provisioner must be available in the cluster. Most managed clusters provide one by default (EBS on EKS, GCE PD on GKE, Azure Disk on AKS). For bare-metal, configure a provisioner manually.

## Image Registry

Build and push images to your registry before deploying:

```bash
docker build \
  -f sre-challenge/app/front/src/main/docker/Dockerfile \
  -t your-registry/front:0.1.0 \
  sre-challenge/
docker push your-registry/front:0.1.0
```

Repeat for `back` and `reader`.

Update `helm/*/values.yaml` for each app chart:

```yaml
app:
  image: your-registry/front:0.1.0
  imagePullPolicy: IfNotPresent
  imagePullSecrets:
    - name: registry-credentials
```

If your registry requires authentication, create a pull secret in each namespace:

```bash
kubectl create secret docker-registry registry-credentials \
  --docker-server=your-registry \
  --docker-username=your-username \
  --docker-password=your-password \
  --namespace demo-front
```

## Deploy

Once cluster requirements are met and images are pushed:

```bash
export DB_USERNAME=postgres
export DB_PASSWORD=your_password
./scripts/deploy-helm.sh
```

The deployment process is identical to Minikube from this point.