# Part 2: Containerized Kubernetes Cluster

This directory contains everything needed to run the entire Kubernetes cluster inside a Docker container using k3d.

## Quick Start

### Build the container:
```bash
docker build -t wiki-cluster .
```

### Run the container (with --privileged flag):
```bash
docker run --privileged -p 8080:8080 wiki-cluster
```

**Note**: The `--privileged` flag is required for Docker-in-Docker (DinD) to work properly.

## What's Inside

### Root Level Files:
- **Dockerfile**: Builds the container with k3d, kubectl, Helm, and Docker-in-Docker
- **entrypoint.sh**: Script that:
  - Starts Docker daemon
  - Builds wiki-service image
  - Creates k3d cluster
  - Deploys all services via Helm
  - Exposes everything on port 8080

### Directories:
- **wiki-service/**: FastAPI service (same as Part 1)
- **wiki-chart/**: Helm chart with all components (same as Part 1)

## Accessing Services

Once the container is running, all services are accessible on **port 8080**:

- **FastAPI Users**: `http://localhost:8080/users`
- **FastAPI Posts**: `http://localhost:8080/posts`  
- **Grafana Dashboard**: `http://localhost:8080/grafana/d/creation-dashboard-678/creation`
  - Username: `admin`
  - Password: `admin`

## Testing

After the container starts (wait ~2-3 minutes for everything to deploy):

```bash
# Test FastAPI
curl http://localhost:8080/users
curl -X POST http://localhost:8080/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Alice"}'

# Access Grafana in browser
open http://localhost:8080/grafana/d/creation-dashboard-678/creation
```

## Troubleshooting

### Container won't start:
- Ensure Docker is running on your host
- Check that port 8080 is not already in use
- Verify you're using `--privileged` flag

### Services not accessible:
- Wait a few minutes for all pods to be ready
- Check container logs: `docker logs <container-id>`
- Inside container: `kubectl get pods` to see status

### View cluster status:
```bash
# Get container ID
docker ps

# Execute commands inside container
docker exec -it <container-id> kubectl get pods
docker exec -it <container-id> kubectl get svc
docker exec -it <container-id> kubectl get ingress
```

## Architecture

```
Host Machine (Port 8080)
    ↓
Docker Container (--privileged)
    ├── Docker-in-Docker (dockerd)
    └── k3d Cluster
        ├── NGINX Ingress Controller (Port 80)
        ├── FastAPI Service
        ├── PostgreSQL
        ├── Prometheus
        └── Grafana
```

All traffic flows: Host:8080 → k3d LoadBalancer:80 → Ingress → Services

