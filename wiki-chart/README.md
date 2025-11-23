# Wiki Chart

Helm chart for deploying the Wikipedia-like API service with FastAPI, PostgreSQL, Prometheus, and Grafana.

## Components

- **FastAPI**: API service for users and posts
- **PostgreSQL**: Database for storing data
- **Prometheus**: Metrics collection from FastAPI
- **Grafana**: Visualization dashboard for metrics

## Installation

1. Build the FastAPI Docker image:
```bash
cd wiki-service
docker build -t wiki-service:latest .
```

2. Install the Helm chart:
```bash
helm install wiki ./wiki-chart
```

## Configuration

Edit `values.yaml` to customize:
- FastAPI image name: `fastapi.image_name`
- Resource limits
- Database credentials
- Grafana admin credentials

## Access

After installation, access the services through the Ingress:

- FastAPI: `/users/*`, `/posts/*`
- Grafana Dashboard: `/grafana/d/creation-dashboard-678/creation`
  - Username: `admin`
  - Password: `admin`

## Resource Limits

Total cluster resources:
- CPU: 1.4 CPU (within 2 CPU limit)
- Memory: 1.5GB (within 4GB limit)
- Storage: 4GB (within 5GB limit)

