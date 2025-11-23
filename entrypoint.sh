#!/bin/bash
set -e

echo "Starting Docker daemon..."
# Start dockerd in background
dockerd > /var/log/dockerd.log 2>&1 &
DOCKER_PID=$!

# Wait for Docker daemon to be ready
echo "Waiting for Docker daemon to be ready..."
timeout=60
while ! docker info >/dev/null 2>&1; do
    if [ $timeout -eq 0 ]; then
        echo "Docker daemon failed to start"
        cat /var/log/dockerd.log
        exit 1
    fi
    sleep 1
    timeout=$((timeout - 1))
done
echo "Docker daemon is ready"

# Build the wiki-service Docker image
echo "Building wiki-service Docker image..."
cd /workspace/wiki-service
docker build -t wiki-service:latest .
echo "wiki-service image built successfully"

# Create k3d cluster with more lenient settings
echo "Creating k3d cluster..."
k3d cluster create wiki-cluster \
    --api-port 6443 \
    --port "8080:80@loadbalancer" \
    --wait \
    --timeout 600s \
    --k3s-arg '--disable=traefik@server:0' \
    --agents 0 \
    --kubeconfig-update-default=false \
    --image rancher/k3s:v1.28.5-k3s1

# Wait for cluster to be ready and set kubeconfig
echo "Waiting for k3d cluster to be ready..."
sleep 15  # Give k3s more time to start
export KUBECONFIG=$(k3d kubeconfig write wiki-cluster)
echo "KUBECONFIG set to: $KUBECONFIG"

# Wait for nodes to be ready
for i in {1..60}; do
    if kubectl get nodes 2>/dev/null | grep -q Ready; then
        echo "Cluster is ready!"
        kubectl get nodes
        break
    fi
    echo "Waiting for cluster... ($i/60)"
    sleep 5
done

# Ensure KUBECONFIG is set for all subsequent commands
export KUBECONFIG=$(k3d kubeconfig write wiki-cluster)

# Import the wiki-service image into k3d
echo "Importing wiki-service image into k3d cluster..."
k3d image import wiki-service:latest -c wiki-cluster

# Ensure KUBECONFIG is set
export KUBECONFIG=$(k3d kubeconfig write wiki-cluster)

# Install NGINX Ingress Controller for k3d
echo "Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

# Wait for ingress controller namespace
sleep 5

# Wait for ingress controller to be ready
echo "Waiting for NGINX Ingress Controller to be ready..."
for i in {1..30}; do
    if kubectl get pods -n ingress-nginx | grep -q Running; then
        echo "Ingress controller is ready"
        break
    fi
    echo "Waiting for ingress controller... ($i/30)"
    sleep 2
done

# # Patch ingress controller to use hostNetwork for k3d
# kubectl patch deployment ingress-nginx-controller -n ingress-nginx --type='json' \
#     -p='[{"op": "add", "path": "/spec/template/spec/hostNetwork", "value": true}]' || true

# # Restart ingress controller
# kubectl rollout restart deployment ingress-nginx-controller -n ingress-nginx
# kubectl rollout status deployment ingress-nginx-controller -n ingress-nginx --timeout=120s || true

# Ensure KUBECONFIG is set
export KUBECONFIG=$(k3d kubeconfig write wiki-cluster)

kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission

# Install Helm chart
echo "Installing Helm chart..."
cd /workspace
helm install wiki ./wiki-chart --wait --timeout=300s

# Wait for all pods to be ready
echo "Waiting for all pods to be ready..."
max_attempts=60
attempt=0
while [ $attempt -lt $max_attempts ]; do
    ready_pods=$(kubectl get pods --no-headers 2>/dev/null | grep -c "Running" || echo "0")
    total_pods=$(kubectl get pods --no-headers 2>/dev/null | wc -l || echo "0")
    if [ "$ready_pods" -ge 4 ] && [ "$total_pods" -ge 4 ]; then
        echo "All pods are ready!"
        break
    fi
    echo "Waiting for pods... ($ready_pods/$total_pods ready) - attempt $((attempt+1))/$max_attempts"
    sleep 5
    attempt=$((attempt + 1))
done

# Show status
echo ""
echo "=========================================="
echo "Cluster status:"
echo "=========================================="
kubectl get pods
echo ""
kubectl get svc
echo ""
kubectl get ingress
echo ""

# Check if services are accessible
echo "Checking service endpoints..."
kubectl get endpoints

echo ""
echo "=========================================="
echo "Cluster is ready!"
echo "=========================================="
echo "Access the services on port 8080:"
echo "  - FastAPI Users: http://localhost:8080/users"
echo "  - FastAPI Posts: http://localhost:8080/posts"
echo "  - Grafana Dashboard: http://localhost:8080/grafana/d/creation-dashboard-678/creation"
echo "    (Username: admin, Password: admin)"
echo "=========================================="
echo ""

# Keep the container running and show logs periodically
while true; do
    sleep 60
    echo "$(date): Cluster is running..."
done

