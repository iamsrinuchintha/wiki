# Part 2 Implementation Summary

## Directory Structure

```
/
├── Dockerfile                    # Root Dockerfile for k3d cluster
├── entrypoint.sh                 # Script to initialize and run the cluster
├── .dockerignore                # Files to exclude from Docker build
├── wiki-service/                 # Same as Part 1
│   ├── Dockerfile
│   ├── .dockerignore
│   ├── pyproject.toml
│   └── app/
│       └── ...
└── wiki-chart/                   # Same as Part 1
    ├── Chart.yaml
    ├── values.yaml
    ├── .helmignore
    └── templates/
        └── ...
```

## Components

### Root Dockerfile
- **Base Image**: `docker:dind` (Docker-in-Docker)
- **Installs**: kubectl, Helm, k3d
- **Copies**: wiki-service and wiki-chart directories
- **Exposes**: Port 8080

### entrypoint.sh
The entrypoint script:
1. Starts Docker daemon
2. Builds the wiki-service Docker image
3. Creates a k3d cluster with port mapping (8080:80)
4. Imports the wiki-service image into k3d
5. Installs NGINX Ingress Controller
6. Deploys the Helm chart
7. Waits for all pods to be ready
8. Keeps the container running

## Building and Running

### Build the image:
```bash
docker build -t wiki-cluster .
```

### Run the container (with --privileged flag):
```bash
docker run --privileged -p 8080:8080 wiki-cluster
```

## Accessing Services

Once the container is running, access services on port 8080:

- **FastAPI Users**: `http://localhost:8080/users`
- **FastAPI Posts**: `http://localhost:8080/posts`
- **Grafana Dashboard**: `http://localhost:8080/grafana/d/creation-dashboard-678/creation`
  - Username: `admin`
  - Password: `admin`

## Port Mapping

The k3d cluster is configured with:
- `--port "8080:80@loadbalancer"` - Maps host port 8080 to cluster port 80
- The NGINX Ingress Controller listens on port 80 inside the cluster
- All ingress routes are accessible through port 8080 on the host

## Notes

- The container must be run with `--privileged` flag for Docker-in-Docker to work
- The Docker socket is NOT mounted (as per requirements)
- All services are deployed within the k3d cluster inside the container
- The cluster persists as long as the container is running

