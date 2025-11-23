# Part 1 Implementation Summary

## Directory Structure

```
/
├── wiki-service/
│   ├── Dockerfile
│   ├── .dockerignore
│   ├── pyproject.toml
│   └── app/
│       ├── __init__.py
│       ├── main.py
│       ├── database.py (updated for PostgreSQL)
│       ├── models.py
│       ├── schemas.py
│       └── metrics.py
│
└── wiki-chart/
    ├── Chart.yaml
    ├── values.yaml
    ├── .helmignore
    ├── README.md
    └── templates/
        ├── fastapi-deployment.yaml
        ├── postgresql-deployment.yaml
        ├── prometheus-configmap.yaml
        ├── prometheus-deployment.yaml
        ├── grafana-datasource-configmap.yaml
        ├── grafana-dashboard-configmap.yaml
        ├── grafana-deployment.yaml
        └── ingress.yaml
```

## Changes Made

### 1. wiki-service/
- **Dockerfile**: Created to build FastAPI service container
- **database.py**: Updated to use PostgreSQL with asyncpg driver
- **pyproject.toml**: Replaced `aiosqlite` with `asyncpg`
- **.dockerignore**: Added to exclude unnecessary files

### 2. wiki-chart/
- **Chart.yaml**: Helm chart metadata
- **values.yaml**: Configurable values including `fastapi.image_name`
- **FastAPI**: Deployment and Service for API
- **PostgreSQL**: Deployment, Service, and PVC for database
- **Prometheus**: Deployment, Service, ConfigMap, and PVC for metrics collection
- **Grafana**: Deployment, Service, ConfigMaps (datasource & dashboard), and PVC
- **Ingress**: Routes `/users/*`, `/posts/*` to FastAPI and `/grafana/*` to Grafana

## Resource Limits

- **Total CPU**: 1.4 CPU (within 2 CPU limit) ✓
- **Total Memory**: 1.5GB (within 4GB limit) ✓
- **Total Storage**: 4GB (within 5GB limit) ✓

## Grafana Dashboard

- **URL**: `/grafana/d/creation-dashboard-678/creation`
- **Username**: `admin`
- **Password**: `admin`
- **Metrics**: Shows rate of `users_created_total` and `posts_created_total` over time

## Building and Deploying

1. Build Docker image:
```bash
cd wiki-service
docker build -t wiki-service:latest .
```

2. Install Helm chart:
```bash
helm install wiki ./wiki-chart
```

3. Access services via Ingress:
- FastAPI: `/users/*`, `/posts/*`
- Grafana: `/grafana/d/creation-dashboard-678/creation`

