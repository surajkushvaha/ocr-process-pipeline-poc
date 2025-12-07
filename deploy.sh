#!/bin/bash

# OCR Pipeline Deployment Script
# Unified script for all deployment scenarios (Linux/macOS)

show_help() {
    echo ""
    echo "=== OCR Pipeline Deployment Script ==="
    echo ""
    echo "Usage:"
    echo "  ./deploy.sh <target> <environment>"
    echo ""
    echo "Targets:"
    echo "  docker-compose   Deploy using Docker Compose (recommended for local dev)"
    echo "  k8s              Deploy to Kubernetes (Docker Desktop/Minikube/Kind)"
    echo "  help             Show this help message"
    echo ""
    echo "Environments:"
    echo "  dev              Development with hot reload (default)"
    echo "  prod             Production optimized build"
    echo ""
    echo "Examples:"
    echo "  ./deploy.sh docker-compose dev"
    echo "  ./deploy.sh k8s prod"
    echo "  ./deploy.sh docker-compose    # dev by default"
    echo ""
}

deploy_docker_compose() {
    local env=$1
    local compose_file="compose.yaml"
    local env_name="Production"
    
    if [ "$env" == "dev" ]; then
        compose_file="compose.dev.yaml"
        env_name="Development"
    fi
    
    echo ""
    echo "=== Docker Compose Deployment ($env_name) ==="
    echo ""
    
    # Check Docker
    echo "1. Checking Docker..."
    if ! docker version &> /dev/null; then
        echo "   Docker is not running!"
        echo "   Please start Docker first."
        exit 1
    fi
    docker_version=$(docker version --format '{{.Server.Version}}' 2>/dev/null)
    echo "   Docker is running: v$docker_version"
    
    # Stop existing
    echo ""
    echo "2. Stopping existing containers..."
    docker-compose -f $compose_file down 2>/dev/null
    echo "   Cleanup complete"
    
    # Build
    echo ""
    echo "3. Building Docker images..."
    echo "   This may take several minutes..."
    if docker-compose -f $compose_file build; then
        echo "   Images built successfully"
    else
        echo "   Build failed!"
        exit 1
    fi
    
    # Start
    echo ""
    echo "4. Starting services..."
    if docker-compose -f $compose_file up -d; then
        echo "   Services started"
    else
        echo "   Failed to start services!"
        exit 1
    fi
    
    # Wait and status
    echo ""
    echo "5. Waiting for services..."
    sleep 10
    
    echo ""
    echo "6. Service Status:"
    docker-compose -f $compose_file ps
    
    # Success
    echo ""
    echo "=== Deployment Complete! ==="
    echo ""
    echo "Access your application:"
    if [ "$env" == "dev" ]; then
        echo "   Flask:     http://localhost:5000"
        echo "   Angular:   http://localhost:4200 (hot reload)"
        echo "   Postgres:  localhost:5432"
        echo "   Redis:     localhost:6379"
    else
        echo "   Nginx:     http://localhost"
        echo "   Flask:     http://localhost:5000"
        echo "   Postgres:  localhost:5432"
        echo "   Redis:     localhost:6379"
    fi
    echo ""
    echo "Useful commands:"
    echo "   View logs:    docker-compose -f $compose_file logs -f"
    echo "   Stop:         docker-compose -f $compose_file down"
    echo "   Restart:      docker-compose -f $compose_file restart"
    echo ""
}

deploy_kubernetes() {
    local env=$1
    local k8s_file="k8s/deployment.yaml"
    local namespace="ocr-pipeline"
    local image_name="ocr-pipeline:latest"
    local dockerfile="Dockerfile"
    local env_name="Production"
    
    if [ "$env" == "dev" ]; then
        k8s_file="k8s/deployment-dev.yaml"
        namespace="ocr-pipeline-dev"
        image_name="ocr-pipeline:dev"
        dockerfile="Dockerfile.dev"
        env_name="Development"
    fi
    
    echo ""
    echo "=== Kubernetes Deployment ($env_name) ==="
    echo ""
    
    # Check kubectl
    echo "1. Checking kubectl..."
    if ! command -v kubectl &> /dev/null; then
        echo "   kubectl not installed!"
        exit 1
    fi
    echo "   kubectl is installed"
    
    # Check cluster
    echo ""
    echo "2. Verifying cluster connection..."
    if ! kubectl cluster-info &> /dev/null; then
        echo "   Not connected to any cluster!"
        echo "   Start Docker Desktop Kubernetes or Minikube first."
        exit 1
    fi
    context=$(kubectl config current-context 2>/dev/null)
    echo "   Connected to cluster: $context"
    
    # Cleanup
    echo ""
    echo "3. Cleaning up existing deployment..."
    kubectl delete -f $k8s_file 2>/dev/null
    sleep 5
    echo "   Cleanup complete"
    
    # Build image
    echo ""
    echo "4. Building Docker image ($image_name)..."
    if docker build -t $image_name -f $dockerfile .; then
        echo "   Image built successfully"
    else
        echo "   Build failed!"
        exit 1
    fi
    
    # Apply
    echo ""
    echo "5. Applying Kubernetes configuration..."
    if kubectl apply -f $k8s_file; then
        echo "   Configuration applied"
    else
        echo "   Failed to apply configuration!"
        exit 1
    fi
    
    # Wait for pods
    echo ""
    echo "6. Waiting for pods to be ready..."
    echo "   (Timeout: 180 seconds)"
    
    timeout=180
    elapsed=0
    ready=false
    
    while [ $elapsed -lt $timeout ]; do
        all_ready=true
        pods=$(kubectl get pods -n $namespace -o json 2>/dev/null)
        
        if echo "$pods" | jq -e '.items | length > 0' &> /dev/null; then
            while read -r pod_status; do
                if [ "$pod_status" != "True" ]; then
                    all_ready=false
                    break
                fi
            done < <(echo "$pods" | jq -r '.items[].status.conditions[] | select(.type=="Ready") | .status')
            
            if [ "$all_ready" == "true" ]; then
                ready=true
                break
            fi
        fi
        
        sleep 5
        elapsed=$((elapsed + 5))
        echo "   Waiting... ($elapsed / $timeout seconds)"
    done
    
    if [ "$ready" == "true" ]; then
        echo "   All pods are ready!"
    else
        echo "   Timeout waiting for pods"
        echo "   Pods may still be starting..."
    fi
    
    # Status
    echo ""
    echo "7. Deployment Status:"
    kubectl get all -n $namespace
    
    # Check issues
    echo ""
    echo "8. Checking for issues..."
    issues=$(kubectl get pods -n $namespace --field-selector=status.phase!=Running,status.phase!=Succeeded -o json 2>/dev/null)
    
    if echo "$issues" | jq -e '.items | length > 0' &> /dev/null; then
        echo "   Some pods have issues:"
        kubectl get pods -n $namespace --field-selector=status.phase!=Running,status.phase!=Succeeded
        echo ""
        echo "   Check logs with:"
        echo "   kubectl logs -f deployment/flask-app-deployment -n $namespace"
    else
        echo "   No issues detected"
    fi
    
    # Success
    echo ""
    echo "=== Deployment Complete! ==="
    echo ""
    echo "Access your application:"
    echo "   kubectl port-forward -n $namespace svc/flask-app-service 5000:5000"
    echo "   Then open: http://localhost:5000"
    echo ""
    echo "Useful commands:"
    echo "   View pods:        kubectl get pods -n $namespace"
    echo "   View logs:        kubectl logs -f deployment/flask-app-deployment -n $namespace"
    echo "   Delete:           kubectl delete -f $k8s_file"
    echo ""
}

# Main script logic
TARGET=${1:-help}
ENVIRONMENT=${2:-dev}

case $TARGET in
    docker-compose)
        deploy_docker_compose $ENVIRONMENT
        ;;
    k8s)
        deploy_kubernetes $ENVIRONMENT
        ;;
    help|*)
        show_help
        ;;
esac
