# build.sh - Docker Image Building

## Description

The script switches the Docker context to Minikube and builds Docker images for three microservices (Front, Back, Reader) directly in Minikube Docker without using an external registry.

## Prerequisites

- Minikube installed and running
- Docker installed in the system
- Java 21+ for local verification (optional)

## Usage

```bash
./scripts/build.sh
```

## Execution Process

1. **Docker context switch**: executes `eval $(minikube docker-env)` to direct Docker commands to Minikube
2. **Image building**: for each application (front, back, reader):
   - Uses multi-stage Dockerfile
   - Stage 1: Gradle 8.5 + JDK 21 build JAR
   - Stage 2: IBM Semeru Runtime JRE 21 run application
3. **Tagging**: images are tagged with version `0.1.0`
4. **Output**: list of built images

## Results

Built images are available in Minikube Docker:
- `front:0.1.0`
- `back:0.1.0`
- `reader:0.1.0`

Images are ready for use in Kubernetes without needing to push to an external registry.

## Notes

- The script does not require internet connectivity after the first pull of base images (gradle, IBM Semeru)
- Images contain only runtime (without source code and build dependencies)
- For production environment, adaptation is required to work with external registry

## Possible Errors

| Error | Solution |
|-------|----------|
| Command not found: minikube | Minikube is not installed or not in PATH |
| Cannot connect to Docker daemon | Minikube is not running (`minikube start`) |
| Failed to build image | Check Dockerfile presence in specified paths |
