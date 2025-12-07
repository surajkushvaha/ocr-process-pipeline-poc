# Docker & Kubernetes Setup Guide for OCR Pipeline POC

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Quick Start Options](#quick-start)
3. [Docker Commands](#docker-commands)
4. [Kubernetes Commands](#kubernetes-commands)
5. [Troubleshooting](#troubleshooting)

## Prerequisites

### 1. Install Docker Desktop
```powershell
# Using Chocolatey
choco install docker-desktop

# After installation, start Docker Desktop and enable Kubernetes in settings
```

Verify installation:
```powershell
docker --version
docker-compose --version
```

### 2. Install Kubernetes Tools

**Option A: kubectl (Required for all K8s options)**
```powershell
choco install kubernetes-cli
kubectl version --client
```

**Option B: Minikube (Recommended for local development)**
```powershell
choco install minikube
minikube version
```

**Option C: Kind (Alternative - Kubernetes in Docker)**
```powershell
choco install kind
kind version
```

**Note:** Docker Desktop includes Kubernetes. You can enable it in:
`Docker Desktop Settings > Kubernetes > Enable Kubernetes`

### 3. Verify Setup
```powershell
# Check Docker
docker ps

# Check Kubernetes
kubectl cluster-info

# Check available contexts
kubectl config get-contexts
```

## Quick Start

### Option 1: Docker Compose (Recommended for Development)

**Production Mode:**
```powershell
# Start all services (Flask, Nginx, Redis, PostgreSQL)
docker-compose -f compose.yaml up -d

# View logs
docker-compose -f compose.yaml logs -f

# Stop services
docker-compose -f compose.yaml down
```

**Development Mode (with hot reload):**
```powershell
# Start with code hot-reloading
docker-compose -f compose.dev.yaml up

# This will expose:
# - Flask backend on http://localhost:5000
# - Angular frontend on http://localhost:4200
# - Code changes automatically reload
```

**Access Points:**
- Production: http://localhost (via Nginx)
- Development: 
  - Flask: http://localhost:5000
  - Angular: http://localhost:4200
  - Redis: localhost:6379
  - PostgreSQL: localhost:5432

### Option 2: Docker Desktop Kubernetes (Easiest K8s Setup)

```powershell
# 1. Enable Kubernetes in Docker Desktop
# Go to Docker Desktop > Settings > Kubernetes > Enable Kubernetes

# 2. Verify Kubernetes is running
kubectl cluster-info

# 3. Build Docker images
.\build-docker.ps1

# 4. Deploy to Kubernetes
.\deploy-k8s.ps1 -Environment dev

# 5. Check deployment status
kubectl get pods -n ocr-pipeline-dev
kubectl get services -n ocr-pipeline-dev

# 6. Access the application
kubectl port-forward -n ocr-pipeline-dev svc/flask-app-service-dev 5000:5000 4200:4200

# Then access:
# - Flask: http://localhost:5000
# - Angular: http://localhost:4200
```

### Option 3: Kubernetes with Minikube

```powershell
# 1. Start Minikube with sufficient resources
minikube start --driver=docker --cpus=4 --memory=8192

# 2. Verify cluster is running
kubectl get nodes

# 3. Build Docker images
.\build-docker.ps1

# 4. Load images into Minikube (important!)
minikube image load ocr-pipeline:latest
minikube image load ocr-pipeline:dev

# 5. Deploy to Kubernetes
.\deploy-k8s.ps1 -Environment dev

# 6. Wait for pods to be ready
kubectl get pods -n ocr-pipeline-dev -w

# 7. Access the application
minikube service flask-app-service-dev -n ocr-pipeline-dev

# Or use port forwarding
kubectl port-forward -n ocr-pipeline-dev svc/flask-app-service-dev 5000:5000 4200:4200

# 8. (Optional) Open Minikube dashboard
minikube dashboard
```

**Useful Minikube Commands:**
```powershell
# Stop cluster (preserves state)
minikube stop

# Start existing cluster
minikube start

# Delete cluster
minikube delete

# View cluster IP
minikube ip

# SSH into cluster
minikube ssh
```

### Option 4: Kubernetes with Kind

```powershell
# 1. Create a Kind cluster
kind create cluster --name ocr-cluster

# 2. Verify cluster
kubectl cluster-info --context kind-ocr-cluster

# 3. Build Docker images
.\build-docker.ps1

# 4. Load images into Kind cluster
kind load docker-image ocr-pipeline:latest --name ocr-cluster
kind load docker-image ocr-pipeline:dev --name ocr-cluster

# 5. Deploy to Kubernetes
.\deploy-k8s.ps1 -Environment dev

# 6. Check deployment status
kubectl get pods -n ocr-pipeline-dev -w

# 7. Port forward to access (Kind doesn't have LoadBalancer by default)
kubectl port-forward -n ocr-pipeline-dev svc/flask-app-service-dev 5000:5000 4200:4200

# Access at:
# - Flask: http://localhost:5000
# - Angular: http://localhost:4200
```

**Useful Kind Commands:**
```powershell
# List clusters
kind get clusters

# Delete cluster
kind delete cluster --name ocr-cluster

# Export cluster logs
kind export logs --name ocr-cluster
```

## Which Option Should I Choose?

| Option | Best For | Pros | Cons |
|--------|----------|------|------|
| **Docker Compose** | Quick development, testing | Simple, fast setup | Not production-like |
| **Docker Desktop K8s** | Learning K8s, small projects | Built-in, easy | Limited resources |
| **Minikube** | Full K8s features locally | Feature-rich, addons | More resource-heavy |
| **Kind** | CI/CD, testing K8s configs | Lightweight, fast | Requires port-forwarding |

**Recommendation:** Start with **Docker Compose** for development, then move to **Docker Desktop K8s** or **Minikube** when you need Kubernetes features.

## Docker Commands Reference

### Building Images

```powershell
# Build both production and development images
.\build-docker.ps1

# Or build manually:

# Production image (optimized, multi-stage build)
docker build -t ocr-pipeline:latest -f Dockerfile .

# Development image (with Node.js for hot reload)
docker build -t ocr-pipeline:dev -f Dockerfile.dev .

# Build with no cache (clean build)
docker build --no-cache -t ocr-pipeline:latest -f Dockerfile .

# View built images
docker images | Select-String "ocr-pipeline"
```

### Running Containers

```powershell
# Run production container
docker run -d -p 5000:5000 --name ocr-app ocr-pipeline:latest

# Run with environment variables
docker run -d -p 5000:5000 `
  -e FLASK_ENV=production `
  -e PORT=5000 `
  --name ocr-app ocr-pipeline:latest

# Run with volume mounts (for persistent data)
docker run -d -p 5000:5000 `
  -v ${PWD}/uploads:/app/uploads `
  -v ${PWD}/logs:/app/logs `
  --name ocr-app ocr-pipeline:latest

# Run interactively (for debugging)
docker run -it --rm ocr-pipeline:latest /bin/bash

# View running containers
docker ps

# View all containers (including stopped)
docker ps -a

# Stop container
docker stop ocr-app

# Remove container
docker rm ocr-app

# View container logs
docker logs ocr-app
docker logs -f ocr-app  # Follow logs in real-time
```

### Docker Compose Commands

```powershell
# Start all services in detached mode
docker-compose -f compose.yaml up -d

# Start and view logs
docker-compose -f compose.yaml up

# View logs of specific service
docker-compose -f compose.yaml logs -f flask-app

# Stop all services
docker-compose -f compose.yaml down

# Stop and remove volumes (clean slate)
docker-compose -f compose.yaml down -v

# Rebuild and restart services
docker-compose -f compose.yaml up -d --build

# Scale a service
docker-compose -f compose.yaml up -d --scale flask-app=3

# List running services
docker-compose -f compose.yaml ps

# Execute command in running container
docker-compose -f compose.yaml exec flask-app bash

# View resource usage
docker-compose -f compose.yaml top
```

### Image Management

```powershell
# List all images
docker images

# Remove specific image
docker rmi ocr-pipeline:latest

# Remove unused images
docker image prune

# Remove all unused images
docker image prune -a

# Tag image for registry
docker tag ocr-pipeline:latest myregistry.com/ocr-pipeline:v1.0

# Push to registry
docker push myregistry.com/ocr-pipeline:v1.0

# Pull from registry
docker pull myregistry.com/ocr-pipeline:v1.0
```

### Container Management

```powershell
# Inspect container
docker inspect ocr-app

# View container stats (resource usage)
docker stats ocr-app

# Copy files from container
docker cp ocr-app:/app/logs/app.log ./local-app.log

# Copy files to container
docker cp ./config.json ocr-app:/app/config.json

# Export container as tar
docker export ocr-app > ocr-app.tar

# Restart container
docker restart ocr-app

# Pause/unpause container
docker pause ocr-app
docker unpause ocr-app
```

## Kubernetes Commands Reference

### Basic Deployment

```powershell
# Deploy using script (recommended)
.\deploy-k8s.ps1 -Environment dev     # Development
.\deploy-k8s.ps1 -Environment prod    # Production

# Or deploy manually
kubectl apply -f k8s/deployment-dev.yaml
kubectl apply -f k8s/deployment.yaml

# Check deployment status
kubectl get deployments -n ocr-pipeline
kubectl get deployments -n ocr-pipeline-dev

# Check pods
kubectl get pods -n ocr-pipeline
kubectl get pods -n ocr-pipeline-dev -w  # Watch in real-time

# Check services
kubectl get services -n ocr-pipeline
kubectl get svc -n ocr-pipeline  # Short form

# Check all resources in namespace
kubectl get all -n ocr-pipeline

# Get detailed information
kubectl describe deployment flask-app-deployment -n ocr-pipeline
kubectl describe pod <pod-name> -n ocr-pipeline
```

### Viewing Logs

```powershell
# View logs of a deployment
kubectl logs -f deployment/flask-app-deployment -n ocr-pipeline

# View logs of a specific pod
kubectl logs <pod-name> -n ocr-pipeline

# View logs from previous container (if crashed)
kubectl logs <pod-name> -n ocr-pipeline --previous

# View logs from all pods with label
kubectl logs -l app=flask-app -n ocr-pipeline --all-containers=true

# Tail last 100 lines
kubectl logs <pod-name> -n ocr-pipeline --tail=100

# Stream logs from multiple pods
kubectl logs -f -l app=flask-app -n ocr-pipeline
```

### Accessing Pods

```powershell
# Execute command in pod
kubectl exec -it <pod-name> -n ocr-pipeline -- /bin/bash

# Run single command
kubectl exec <pod-name> -n ocr-pipeline -- ls -la /app

# Port forward to access service locally
kubectl port-forward svc/flask-app-service 5000:5000 -n ocr-pipeline

# Port forward to access pod
kubectl port-forward <pod-name> 5000:5000 -n ocr-pipeline

# Copy files from pod
kubectl cp <pod-name>:/app/logs/app.log ./app.log -n ocr-pipeline

# Copy files to pod
kubectl cp ./config.json <pod-name>:/app/config.json -n ocr-pipeline
```

### Scaling Applications

```powershell
# Manual scaling
kubectl scale deployment flask-app-deployment --replicas=5 -n ocr-pipeline

# View current replicas
kubectl get deployment flask-app-deployment -n ocr-pipeline

# Check Horizontal Pod Autoscaler (HPA) status
kubectl get hpa -n ocr-pipeline

# Describe HPA
kubectl describe hpa flask-app-hpa -n ocr-pipeline

# Edit HPA configuration
kubectl edit hpa flask-app-hpa -n ocr-pipeline

# Delete HPA (manual scaling only)
kubectl delete hpa flask-app-hpa -n ocr-pipeline
```

### Updates and Rollbacks

```powershell
# Update container image
kubectl set image deployment/flask-app-deployment `
  flask-app=ocr-pipeline:v2 -n ocr-pipeline

# Check rollout status
kubectl rollout status deployment/flask-app-deployment -n ocr-pipeline

# View rollout history
kubectl rollout history deployment/flask-app-deployment -n ocr-pipeline

# Rollback to previous version
kubectl rollout undo deployment/flask-app-deployment -n ocr-pipeline

# Rollback to specific revision
kubectl rollout undo deployment/flask-app-deployment --to-revision=2 -n ocr-pipeline

# Restart deployment (recreate all pods)
kubectl rollout restart deployment/flask-app-deployment -n ocr-pipeline

# Pause rollout
kubectl rollout pause deployment/flask-app-deployment -n ocr-pipeline

# Resume rollout
kubectl rollout resume deployment/flask-app-deployment -n ocr-pipeline
```

### Configuration Management

```powershell
# View ConfigMaps
kubectl get configmaps -n ocr-pipeline
kubectl describe configmap flask-app-config -n ocr-pipeline

# Edit ConfigMap
kubectl edit configmap flask-app-config -n ocr-pipeline

# Create ConfigMap from file
kubectl create configmap app-config --from-file=config.json -n ocr-pipeline

# View Secrets
kubectl get secrets -n ocr-pipeline
kubectl describe secret flask-app-secret -n ocr-pipeline

# Create Secret from literal
kubectl create secret generic db-secret `
  --from-literal=username=admin `
  --from-literal=password=secret123 `
  -n ocr-pipeline

# Create Secret from file
kubectl create secret generic tls-secret `
  --from-file=tls.crt=./cert.pem `
  --from-file=tls.key=./key.pem `
  -n ocr-pipeline

# Decode secret value
kubectl get secret flask-app-secret -n ocr-pipeline -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d
```

### Resource Management

```powershell
# View resource usage
kubectl top nodes
kubectl top pods -n ocr-pipeline

# View resource quotas
kubectl get resourcequota -n ocr-pipeline

# View persistent volumes
kubectl get pv
kubectl get pvc -n ocr-pipeline

# Describe PVC
kubectl describe pvc uploads-pvc -n ocr-pipeline

# View ingress
kubectl get ingress -n ocr-pipeline
kubectl describe ingress ocr-ingress -n ocr-pipeline
```

### Cleanup

```powershell
# Delete entire namespace (removes everything)
kubectl delete namespace ocr-pipeline
kubectl delete namespace ocr-pipeline-dev

# Delete specific deployment
kubectl delete deployment flask-app-deployment -n ocr-pipeline

# Delete using file
kubectl delete -f k8s/deployment.yaml
kubectl delete -f k8s/deployment-dev.yaml

# Delete all resources with label
kubectl delete all -l app=flask-app -n ocr-pipeline

# Force delete stuck pod
kubectl delete pod <pod-name> --force --grace-period=0 -n ocr-pipeline

# Delete all pods in namespace
kubectl delete pods --all -n ocr-pipeline
```

### Debugging and Troubleshooting

```powershell
# Get events (useful for debugging)
kubectl get events -n ocr-pipeline --sort-by='.lastTimestamp'

# Watch events in real-time
kubectl get events -n ocr-pipeline --watch

# Check node status
kubectl get nodes
kubectl describe node <node-name>

# Check cluster info
kubectl cluster-info
kubectl cluster-info dump

# Validate configuration file
kubectl apply --dry-run=client -f k8s/deployment.yaml

# Explain resource type
kubectl explain pod
kubectl explain deployment.spec

# Get API resources
kubectl api-resources

# Get API versions
kubectl api-versions
```

## Minikube Specific

```powershell
# Start with specific resources
minikube start --cpus=4 --memory=8192

# Enable ingress addon
minikube addons enable ingress

# Access service
minikube service flask-app-service -n ocr-pipeline

# Get dashboard
minikube dashboard

# Stop cluster
minikube stop

# Delete cluster
minikube delete
```

## Kind Specific

```powershell
# Create cluster with config
kind create cluster --config kind-config.yaml

# Load local image
kind load docker-image ocr-pipeline:latest

# Delete cluster
kind delete cluster --name ocr-cluster

# List clusters
kind get clusters
```

## Production Deployment Guide

### 1. Container Registry Setup

```powershell
# Login to Docker Hub
docker login

# Tag image with version
docker tag ocr-pipeline:latest <your-username>/ocr-pipeline:1.0.0
docker tag ocr-pipeline:latest <your-username>/ocr-pipeline:latest

# Push to Docker Hub
docker push <your-username>/ocr-pipeline:1.0.0
docker push <your-username>/ocr-pipeline:latest

# For private registry:
docker login myregistry.com
docker tag ocr-pipeline:latest myregistry.com/ocr-pipeline:1.0.0
docker push myregistry.com/ocr-pipeline:1.0.0
```

Update deployment to use registry image:
```yaml
# In k8s/deployment.yaml
spec:
  containers:
  - name: flask-app
    image: <your-username>/ocr-pipeline:1.0.0  # or myregistry.com/...
    imagePullPolicy: Always
```

### 2. Environment Configuration

**Create production secrets:**
```powershell
# Create from environment file
kubectl create secret generic flask-app-secret `
  --from-env-file=.env.production `
  -n ocr-pipeline

# Or create from literals
kubectl create secret generic flask-app-secret `
  --from-literal=POSTGRES_USER=prod_user `
  --from-literal=POSTGRES_PASSWORD=super_secret_password `
  --from-literal=SECRET_KEY=your-secret-key-here `
  -n ocr-pipeline
```

**Create TLS certificates for HTTPS:**
```powershell
# Create TLS secret
kubectl create secret tls tls-secret `
  --cert=path/to/tls.crt `
  --key=path/to/tls.key `
  -n ocr-pipeline

# Update ingress to use TLS
# Edit k8s/deployment.yaml ingress section
```

### 3. Persistent Storage Configuration

**For cloud providers, update StorageClass:**

**AWS (EKS):**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: uploads-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gp3  # or gp2
  resources:
    requests:
      storage: 50Gi
```

**Azure (AKS):**
```yaml
storageClassName: managed-premium
```

**Google Cloud (GKE):**
```yaml
storageClassName: pd-ssd
```

### 4. Resource Limits

Update resource limits for production:
```yaml
resources:
  requests:
    memory: "1Gi"
    cpu: "500m"
  limits:
    memory: "2Gi"
    cpu: "1000m"
```

### 5. Monitoring and Logging

**Install Prometheus & Grafana:**
```powershell
# Add Prometheus Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus
helm install prometheus prometheus-community/kube-prometheus-stack `
  --namespace monitoring --create-namespace

# Access Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Default credentials: admin / prom-operator
```

**Install metrics-server (for HPA):**
```powershell
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

**Configure application logging:**
```yaml
# Add to deployment
spec:
  containers:
  - name: flask-app
    env:
    - name: LOG_LEVEL
      value: "INFO"
    - name: LOG_FORMAT
      value: "json"
```

### 6. Security Best Practices

**Network Policies:**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: flask-app-netpol
  namespace: ocr-pipeline
spec:
  podSelector:
    matchLabels:
      app: flask-app
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: nginx
    ports:
    - protocol: TCP
      port: 5000
```

**Pod Security:**
```yaml
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
  containers:
  - name: flask-app
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
```

### 7. High Availability

**Multiple replicas across zones:**
```yaml
spec:
  replicas: 3
  template:
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - flask-app
              topologyKey: topology.kubernetes.io/zone
```

### 8. Backup Strategy

**Database backups:**
```powershell
# Create CronJob for backups
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgres-backup
  namespace: ocr-pipeline
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: postgres:15-alpine
            command:
            - /bin/sh
            - -c
            - pg_dump -h postgres-service -U \$POSTGRES_USER \$POSTGRES_DB > /backup/backup-\$(date +%Y%m%d).sql
            envFrom:
            - secretRef:
                name: flask-app-secret
            volumeMounts:
            - name: backup
              mountPath: /backup
          restartPolicy: OnFailure
          volumes:
          - name: backup
            persistentVolumeClaim:
              claimName: backup-pvc
EOF
```

### 9. CI/CD Integration

**GitHub Actions example:**
```yaml
# .github/workflows/deploy.yml
name: Build and Deploy

on:
  push:
    branches: [main]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Build Docker image
      run: docker build -t ocr-pipeline:${{ github.sha }} .
    
    - name: Push to registry
      run: |
        echo ${{ secrets.DOCKER_PASSWORD }} | docker login -u ${{ secrets.DOCKER_USERNAME }} --password-stdin
        docker push ocr-pipeline:${{ github.sha }}
    
    - name: Deploy to Kubernetes
      run: |
        kubectl set image deployment/flask-app-deployment flask-app=ocr-pipeline:${{ github.sha }} -n ocr-pipeline
```

### 10. Health Checks and Readiness

Ensure proper health endpoints in Flask:
```python
@app.route('/health')
def health():
    return jsonify({"status": "healthy"}), 200

@app.route('/ready')
def ready():
    # Check database connection, etc.
    return jsonify({"status": "ready"}), 200
```

## Troubleshooting Guide

### Docker Issues

#### Container won't start
```powershell
# Check container logs
docker logs <container-id>

# Check last 50 lines
docker logs --tail 50 <container-id>

# Run container interactively to debug
docker run -it --rm ocr-pipeline:latest /bin/bash

# Check if port is already in use
netstat -ano | findstr :5000

# Inspect container configuration
docker inspect <container-id>
```

#### Build failures
```powershell
# Build with verbose output
docker build --progress=plain -t ocr-pipeline:latest .

# Build without cache
docker build --no-cache -t ocr-pipeline:latest .

# Check Docker disk space
docker system df

# Clean up unused resources
docker system prune -a
```

#### Network issues
```powershell
# List Docker networks
docker network ls

# Inspect network
docker network inspect bridge

# Test connectivity between containers
docker exec <container-id> ping <other-container-name>

# Check container IP
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' <container-id>
```

### Kubernetes Issues

#### Pod won't start / CrashLoopBackOff
```powershell
# Check pod status and events
kubectl describe pod <pod-name> -n ocr-pipeline

# View logs from crashed container
kubectl logs <pod-name> -n ocr-pipeline --previous

# Check events
kubectl get events -n ocr-pipeline --sort-by='.lastTimestamp' | Select-Object -Last 20

# Common causes:
# 1. Image pull errors - check image name and registry access
# 2. Resource limits - pod can't get required CPU/memory
# 3. Configuration errors - check ConfigMaps and Secrets
# 4. Application errors - check application logs
```

#### Image Pull Errors
```powershell
# Check image pull secrets
kubectl get secrets -n ocr-pipeline

# Verify image exists locally (for Minikube/Kind)
docker images | Select-String "ocr-pipeline"

# For Minikube, load image again
minikube image load ocr-pipeline:latest

# For Kind, load image again
kind load docker-image ocr-pipeline:latest --name ocr-cluster

# Check if image pull policy is correct
kubectl get deployment flask-app-deployment -n ocr-pipeline -o yaml | Select-String "imagePullPolicy"
```

#### Service not accessible
```powershell
# Check service endpoints
kubectl get endpoints -n ocr-pipeline

# If no endpoints, pods might not match service selector
kubectl get pods --show-labels -n ocr-pipeline
kubectl describe service flask-app-service -n ocr-pipeline

# Test service from within cluster
kubectl run test-pod --rm -i --tty --image=busybox -- /bin/sh
# Then inside pod: wget -O- http://flask-app-service.ocr-pipeline:5000/health

# Port forward for direct testing
kubectl port-forward svc/flask-app-service 5000:5000 -n ocr-pipeline
```

#### Persistent Volume issues
```powershell
# Check PV and PVC status
kubectl get pv
kubectl get pvc -n ocr-pipeline

# Describe PVC for events
kubectl describe pvc uploads-pvc -n ocr-pipeline

# Common issues:
# - No storage class available
# - Insufficient resources
# - Access mode mismatch
```

#### Resource constraints
```powershell
# Check node resources
kubectl describe nodes

# Check pod resource usage
kubectl top pods -n ocr-pipeline

# View resource quotas
kubectl describe resourcequota -n ocr-pipeline

# If pod is evicted due to resources:
# 1. Increase node resources
# 2. Reduce pod resource requests
# 3. Scale down other applications
```

### Common Error Messages

#### "Error: ImagePullBackOff"
**Solution:**
```powershell
# For local images, ensure they're loaded:
minikube image load ocr-pipeline:latest
# or
kind load docker-image ocr-pipeline:latest --name ocr-cluster

# Set imagePullPolicy to IfNotPresent or Never in deployment
```

#### "Error: CrashLoopBackOff"
**Solution:**
```powershell
# View container logs
kubectl logs <pod-name> -n ocr-pipeline

# Common causes:
# 1. Application error on startup
# 2. Missing environment variables
# 3. Port already in use
# 4. Health check failing too quickly
```

#### "Error: CreateContainerConfigError"
**Solution:**
```powershell
# Usually means ConfigMap or Secret is missing
kubectl get configmap -n ocr-pipeline
kubectl get secret -n ocr-pipeline

# Create missing resources
kubectl apply -f k8s/deployment.yaml
```

#### "Error: pending (FailedScheduling)"
**Solution:**
```powershell
# Not enough resources available
kubectl describe pod <pod-name> -n ocr-pipeline

# Solutions:
# 1. Reduce resource requests in deployment
# 2. Add more nodes to cluster
# 3. Scale down other deployments
```

### Docker Compose Issues

#### Services won't start
```powershell
# Check service logs
docker-compose -f compose.yaml logs

# Validate compose file
docker-compose -f compose.yaml config

# Start services one by one
docker-compose -f compose.yaml up postgres
docker-compose -f compose.yaml up redis
docker-compose -f compose.yaml up flask-app
```

#### Port conflicts
```powershell
# Check what's using the port
netstat -ano | findstr :5000

# Kill process using port (use PID from above)
taskkill /PID <process-id> /F

# Or change port in compose.yaml
```

### Performance Issues

#### High memory usage
```powershell
# Check container stats
docker stats

# Check pod resource usage
kubectl top pods -n ocr-pipeline

# Solutions:
# 1. Increase memory limits
# 2. Optimize application code
# 3. Scale horizontally instead of vertically
```

#### Slow builds
```powershell
# Use BuildKit for faster builds
$env:DOCKER_BUILDKIT=1
docker build -t ocr-pipeline:latest .

# Use multi-stage builds (already implemented in Dockerfile)
# Use .dockerignore to exclude unnecessary files
```

## Development Workflow Best Practices

### Local Development with Docker Compose

**Recommended workflow:**
```powershell
# 1. Start development environment
docker-compose -f compose.dev.yaml up

# This provides:
# - Automatic code reloading (both Flask and Angular)
# - Local PostgreSQL and Redis
# - Volume mounts for live code changes

# 2. Make code changes in your editor
# Changes are automatically detected and reloaded

# 3. View logs
docker-compose -f compose.dev.yaml logs -f flask-app

# 4. Run tests
docker-compose -f compose.dev.yaml exec flask-app pytest

# 5. Stop when done
docker-compose -f compose.dev.yaml down
```

### Testing Changes in Kubernetes

```powershell
# 1. Make code changes

# 2. Rebuild Docker image
.\build-docker.ps1

# 3. For Minikube - load new image
minikube image load ocr-pipeline:latest

# 4. Restart deployment to use new image
kubectl rollout restart deployment/flask-app-deployment -n ocr-pipeline

# 5. Watch rollout
kubectl rollout status deployment/flask-app-deployment -n ocr-pipeline

# 6. Check logs
kubectl logs -f deployment/flask-app-deployment -n ocr-pipeline
```

### Rapid Development Tips

**Use Skaffold for automatic rebuilds:**
```powershell
# Install Skaffold
choco install skaffold

# Create skaffold.yaml
# Then run:
skaffold dev

# Skaffold will automatically:
# - Rebuild images on code changes
# - Redeploy to Kubernetes
# - Stream logs
```

**Use Tilt for better dev experience:**
```powershell
# Install Tilt
choco install tilt

# Create Tiltfile
# Then run:
tilt up

# Provides:
# - Web UI for logs and resources
# - Fast rebuilds
# - Live updates
```

## Useful Tools and Commands

### Docker

```powershell
# Clean up everything
docker system prune -a --volumes

# See disk usage
docker system df

# Remove all stopped containers
docker container prune

# Remove unused networks
docker network prune

# Remove unused volumes
docker volume prune

# Export/Import images
docker save ocr-pipeline:latest > ocr-pipeline.tar
docker load < ocr-pipeline.tar
```

### Kubernetes

```powershell
# Switch context
kubectl config use-context docker-desktop
kubectl config use-context minikube

# View current context
kubectl config current-context

# Create namespace
kubectl create namespace dev
kubectl create namespace staging
kubectl create namespace prod

# Set default namespace
kubectl config set-context --current --namespace=ocr-pipeline

# Quick debugging pod
kubectl run debug --rm -i --tty --image=nicolaka/netshoot -- /bin/bash

# Generate YAML from running resource
kubectl get deployment flask-app-deployment -n ocr-pipeline -o yaml > backup.yaml

# Edit resource directly
kubectl edit deployment flask-app-deployment -n ocr-pipeline
```

## Cheat Sheets

### Docker Quick Reference

| Command | Description |
|---------|-------------|
| `docker ps` | List running containers |
| `docker ps -a` | List all containers |
| `docker images` | List images |
| `docker logs <id>` | View container logs |
| `docker exec -it <id> bash` | Access container shell |
| `docker stop <id>` | Stop container |
| `docker rm <id>` | Remove container |
| `docker rmi <image>` | Remove image |
| `docker-compose up -d` | Start services in background |
| `docker-compose down` | Stop and remove services |
| `docker-compose logs -f` | Follow logs |

### Kubernetes Quick Reference

| Command | Description |
|---------|-------------|
| `kubectl get pods` | List pods |
| `kubectl describe pod <name>` | Pod details |
| `kubectl logs <pod>` | View pod logs |
| `kubectl exec -it <pod> -- bash` | Access pod shell |
| `kubectl get svc` | List services |
| `kubectl get deployments` | List deployments |
| `kubectl scale deployment <name> --replicas=3` | Scale deployment |
| `kubectl rollout restart deployment/<name>` | Restart deployment |
| `kubectl port-forward <pod> 8080:80` | Port forward |
| `kubectl delete pod <name>` | Delete pod |

## Additional Resources

### Documentation
- Docker: https://docs.docker.com/
- Kubernetes: https://kubernetes.io/docs/
- Minikube: https://minikube.sigs.k8s.io/docs/
- Kind: https://kind.sigs.k8s.io/

### Tutorials
- Docker Getting Started: https://docs.docker.com/get-started/
- Kubernetes Basics: https://kubernetes.io/docs/tutorials/kubernetes-basics/
- Docker Compose: https://docs.docker.com/compose/gettingstarted/

### Tools
- Lens (Kubernetes IDE): https://k8slens.dev/
- K9s (Terminal UI): https://k9scli.io/
- Dive (Docker image explorer): https://github.com/wagoodman/dive

## Summary

This guide covers:
✅ Complete setup instructions for Docker and Kubernetes  
✅ Multiple deployment options (Docker Compose, Minikube, Kind, Docker Desktop K8s)  
✅ Comprehensive command reference  
✅ Troubleshooting common issues  
✅ Production deployment best practices  
✅ Development workflow tips  

For quick start, use **Docker Compose** for development and **Minikube** or **Docker Desktop Kubernetes** for testing Kubernetes features locally.
