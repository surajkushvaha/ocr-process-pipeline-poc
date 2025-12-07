# OCR Pipeline Deployment Script
# Unified script for all deployment scenarios

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('docker-compose', 'k8s', 'help')]
    [string]$Target = 'help',
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('prod', 'dev')]
    [string]$Environment = 'dev'
)

function Show-Help {
    Write-Host ""
    Write-Host "=== OCR Pipeline Deployment Script ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\deploy.ps1 -Target <target> -Environment <env>" -ForegroundColor White
    Write-Host ""
    Write-Host "Targets:" -ForegroundColor Yellow
    Write-Host "  docker-compose   Deploy using Docker Compose (recommended for local dev)" -ForegroundColor White
    Write-Host "  k8s              Deploy to Kubernetes (Docker Desktop/Minikube/Kind)" -ForegroundColor White
    Write-Host "  help             Show this help message" -ForegroundColor White
    Write-Host ""
    Write-Host "Environments:" -ForegroundColor Yellow
    Write-Host "  dev              Development with hot reload (default)" -ForegroundColor White
    Write-Host "  prod             Production optimized build" -ForegroundColor White
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  .\deploy.ps1 -Target docker-compose -Environment dev" -ForegroundColor Cyan
    Write-Host "  .\deploy.ps1 -Target k8s -Environment prod" -ForegroundColor Cyan
    Write-Host "  .\deploy.ps1 -Target docker-compose              # dev by default" -ForegroundColor Cyan
    Write-Host ""
}

function Deploy-DockerCompose {
    param([string]$Env)
    
    $composeFile = if ($Env -eq 'dev') { 'compose.dev.yaml' } else { 'compose.yaml' }
    $envName = if ($Env -eq 'dev') { 'Development' } else { 'Production' }
    
    Write-Host ""
    Write-Host "=== Docker Compose Deployment ($envName) ===" -ForegroundColor Cyan
    Write-Host ""
    
    # Check Docker
    Write-Host "1. Checking Docker..." -ForegroundColor Yellow
    try {
        $dockerVersion = docker version --format '{{.Server.Version}}' 2>$null
        if ($dockerVersion) {
            Write-Host "   Docker is running: v$dockerVersion" -ForegroundColor Green
        } else {
            throw "Docker not responding"
        }
    } catch {
        Write-Host "   Docker is not running!" -ForegroundColor Red
        Write-Host "   Please start Docker Desktop first." -ForegroundColor Cyan
        exit 1
    }
    
    # Stop existing
    Write-Host ""
    Write-Host "2. Stopping existing containers..." -ForegroundColor Yellow
    docker-compose -f $composeFile down 2>$null
    Write-Host "   Cleanup complete" -ForegroundColor Green
    
    # Build
    Write-Host ""
    Write-Host "3. Building Docker images..." -ForegroundColor Yellow
    Write-Host "   This may take several minutes..." -ForegroundColor Gray
    docker-compose -f $composeFile build
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   Images built successfully" -ForegroundColor Green
    } else {
        Write-Host "   Build failed!" -ForegroundColor Red
        exit 1
    }
    
    # Start
    Write-Host ""
    Write-Host "4. Starting services..." -ForegroundColor Yellow
    docker-compose -f $composeFile up -d
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   Services started" -ForegroundColor Green
    } else {
        Write-Host "   Failed to start services!" -ForegroundColor Red
        exit 1
    }
    
    # Wait and status
    Write-Host ""
    Write-Host "5. Waiting for services..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    
    Write-Host ""
    Write-Host "6. Service Status:" -ForegroundColor Yellow
    docker-compose -f $composeFile ps
    
    # Success
    Write-Host ""
    Write-Host "=== Deployment Complete! ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "Access your application:" -ForegroundColor Cyan
    if ($Env -eq 'dev') {
        Write-Host "   Flask:     http://localhost:5000" -ForegroundColor White
        Write-Host "   Angular:   http://localhost:4200 (hot reload)" -ForegroundColor White
        Write-Host "   Postgres:  localhost:5432" -ForegroundColor White
        Write-Host "   Redis:     localhost:6379" -ForegroundColor White
    } else {
        Write-Host "   Nginx:     http://localhost" -ForegroundColor White
        Write-Host "   Flask:     http://localhost:5000" -ForegroundColor White
        Write-Host "   Postgres:  localhost:5432" -ForegroundColor White
        Write-Host "   Redis:     localhost:6379" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "Useful commands:" -ForegroundColor Cyan
    Write-Host "   View logs:    docker-compose -f $composeFile logs -f" -ForegroundColor White
    Write-Host "   Stop:         docker-compose -f $composeFile down" -ForegroundColor White
    Write-Host "   Restart:      docker-compose -f $composeFile restart" -ForegroundColor White
    Write-Host ""
}

function Deploy-Kubernetes {
    param([string]$Env)
    
    $k8sFile = if ($Env -eq 'dev') { 'k8s/deployment-dev.yaml' } else { 'k8s/deployment.yaml' }
    $namespace = if ($Env -eq 'dev') { 'ocr-pipeline-dev' } else { 'ocr-pipeline' }
    $imageName = if ($Env -eq 'dev') { 'ocr-pipeline:dev' } else { 'ocr-pipeline:latest' }
    $envName = if ($Env -eq 'dev') { 'Development' } else { 'Production' }
    
    Write-Host ""
    Write-Host "=== Kubernetes Deployment ($envName) ===" -ForegroundColor Cyan
    Write-Host ""
    
    # Check kubectl
    Write-Host "1. Checking kubectl..." -ForegroundColor Yellow
    try {
        $kubectlVersion = kubectl version --client --short 2>$null
        if ($kubectlVersion) {
            Write-Host "   kubectl is installed" -ForegroundColor Green
        } else {
            throw "kubectl not found"
        }
    } catch {
        Write-Host "   kubectl not installed!" -ForegroundColor Red
        exit 1
    }
    
    # Check cluster
    Write-Host ""
    Write-Host "2. Verifying cluster connection..." -ForegroundColor Yellow
    try {
        $context = kubectl config current-context 2>$null
        if ($context) {
            Write-Host "   Connected to cluster: $context" -ForegroundColor Green
        } else {
            throw "No cluster context"
        }
    } catch {
        Write-Host "   Not connected to any cluster!" -ForegroundColor Red
        Write-Host "   Start Docker Desktop Kubernetes or Minikube first." -ForegroundColor Cyan
        exit 1
    }
    
    # Cleanup
    Write-Host ""
    Write-Host "3. Cleaning up existing deployment..." -ForegroundColor Yellow
    kubectl delete -f $k8sFile 2>$null
    Start-Sleep -Seconds 5
    Write-Host "   Cleanup complete" -ForegroundColor Green
    
    # Build image
    Write-Host ""
    Write-Host "4. Building Docker image ($imageName)..." -ForegroundColor Yellow
    
    $dockerfile = if ($Env -eq 'dev') { 'Dockerfile.dev' } else { 'Dockerfile' }
    docker build -t $imageName -f $dockerfile .
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   Image built successfully" -ForegroundColor Green
    } else {
        Write-Host "   Build failed!" -ForegroundColor Red
        exit 1
    }
    
    # Apply
    Write-Host ""
    Write-Host "5. Applying Kubernetes configuration..." -ForegroundColor Yellow
    kubectl apply -f $k8sFile
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   Configuration applied" -ForegroundColor Green
    } else {
        Write-Host "   Failed to apply configuration!" -ForegroundColor Red
        exit 1
    }
    
    # Wait for pods
    Write-Host ""
    Write-Host "6. Waiting for pods to be ready..." -ForegroundColor Yellow
    Write-Host "   (Timeout: 180 seconds)" -ForegroundColor Gray
    
    $timeout = 180
    $elapsed = 0
    $ready = $false
    
    while ($elapsed -lt $timeout) {
        $pods = kubectl get pods -n $namespace -o json 2>$null | ConvertFrom-Json
        if ($pods.items) {
            $allReady = $true
            foreach ($pod in $pods.items) {
                $podReady = $false
                foreach ($condition in $pod.status.conditions) {
                    if ($condition.type -eq "Ready" -and $condition.status -eq "True") {
                        $podReady = $true
                        break
                    }
                }
                if (-not $podReady) {
                    $allReady = $false
                    break
                }
            }
            
            if ($allReady) {
                $ready = $true
                break
            }
        }
        
        Start-Sleep -Seconds 5
        $elapsed += 5
        Write-Host "   Waiting... ($elapsed / $timeout seconds)" -ForegroundColor Gray
    }
    
    if ($ready) {
        Write-Host "   All pods are ready!" -ForegroundColor Green
    } else {
        Write-Host "   Timeout waiting for pods" -ForegroundColor Yellow
        Write-Host "   Pods may still be starting..." -ForegroundColor Gray
    }
    
    # Status
    Write-Host ""
    Write-Host "7. Deployment Status:" -ForegroundColor Yellow
    kubectl get all -n $namespace
    
    # Check issues
    Write-Host ""
    Write-Host "8. Checking for issues..." -ForegroundColor Yellow
    $issues = kubectl get pods -n $namespace --field-selector=status.phase!=Running,status.phase!=Succeeded -o json 2>$null | ConvertFrom-Json
    
    if ($issues.items -and $issues.items.Count -gt 0) {
        Write-Host "   Some pods have issues:" -ForegroundColor Yellow
        kubectl get pods -n $namespace --field-selector=status.phase!=Running,status.phase!=Succeeded
        Write-Host ""
        Write-Host "   Check logs with:" -ForegroundColor Cyan
        Write-Host "   kubectl logs -f deployment/flask-app-deployment -n $namespace" -ForegroundColor White
    } else {
        Write-Host "   No issues detected" -ForegroundColor Green
    }
    
    # Success
    Write-Host ""
    Write-Host "=== Deployment Complete! ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "Access your application:" -ForegroundColor Cyan
    Write-Host "   kubectl port-forward -n $namespace svc/flask-app-service 5000:5000" -ForegroundColor White
    Write-Host "   Then open: http://localhost:5000" -ForegroundColor White
    Write-Host ""
    Write-Host "Useful commands:" -ForegroundColor Cyan
    Write-Host "   View pods:        kubectl get pods -n $namespace" -ForegroundColor White
    Write-Host "   View logs:        kubectl logs -f deployment/flask-app-deployment -n $namespace" -ForegroundColor White
    Write-Host "   Delete:           kubectl delete -f $k8sFile" -ForegroundColor White
    Write-Host ""
}

# Main script logic
if ($Target -eq 'help') {
    Show-Help
    exit 0
}

if ($Target -eq 'docker-compose') {
    Deploy-DockerCompose -Env $Environment
} elseif ($Target -eq 'k8s') {
    Deploy-Kubernetes -Env $Environment
}
