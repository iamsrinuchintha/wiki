# Testing Part 2: Containerized Kubernetes Cluster

## Prerequisites

- Docker installed and running
- Port 8080 available on your host machine

## Step 1: Build the Container

```bash
cd /Users/srinu/Documents/projects/BespokeLabs/nebula-aurora-assignment
docker build -t wiki-cluster .
```

## Step 2: Run the Container

```bash
docker run --privileged -p 8080:8080 --name wiki-cluster-test wiki-cluster
```

**Important**: The `--privileged` flag is required for Docker-in-Docker to work.

## Step 3: Monitor Setup Progress

In another terminal, watch the logs:

```bash
docker logs -f wiki-cluster-test
```

Wait for the message: **"Cluster is ready!"** (this takes 3-5 minutes)

## Step 4: Test the Services

### Test FastAPI - Create a User

```bash
curl -X POST "http://localhost:8080/users" \
  -H "Content-Type: application/json" \
  -d '{"name": "Alice"}'
```

**Expected Response:**
```json
{"id":1,"name":"Alice","created_time":"2025-11-22T..."}
```

### Test FastAPI - Create a Post

```bash
curl -X POST "http://localhost:8080/posts" \
  -H "Content-Type: application/json" \
  -d '{"user_id": 1, "content": "Hello World!"}'
```

**Expected Response:**
```json
{"post_id":1,"content":"Hello World!","user_id":1,"created_time":"2025-11-22T..."}
```

### Test FastAPI - Get User

```bash
curl "http://localhost:8080/users/1"
```

### Test FastAPI - Get Post

```bash
curl "http://localhost:8080/posts/1"
```

### Test Prometheus Metrics

```bash
curl "http://localhost:8080/metrics" | grep -E "(users_created_total|posts_created_total)"
```

**Expected Output:**
```
# HELP users_created_total Total number of users created
# TYPE users_created_total counter
users_created_total 1.0
# HELP posts_created_total Total number of posts created
# TYPE posts_created_total counter
posts_created_total 1.0
```

### Test Grafana Dashboard

Open in your browser:
```
http://localhost:8080/grafana/d/creation-dashboard-678/creation
```

**Login Credentials:**
- Username: `admin`
- Password: `admin`

You should see a dashboard showing the rate of users and posts creation over time.

## Step 5: Check Cluster Status (Inside Container)

```bash
# Get into the container
docker exec -it wiki-cluster-test bash

# Inside the container, check pods
kubectl get pods

# Check services
kubectl get svc

# Check ingress
kubectl get ingress

# Check logs of a specific pod
kubectl logs <pod-name>

# Exit container
exit
```

## Step 6: View Container Logs

```bash
# View all logs
docker logs wiki-cluster-test

# Follow logs in real-time
docker logs -f wiki-cluster-test

# View last 100 lines
docker logs --tail 100 wiki-cluster-test
```

## Troubleshooting

### Container won't start
- Check if port 8080 is already in use: `lsof -i :8080`
- Ensure Docker is running: `docker ps`
- Verify `--privileged` flag is used

### Services not accessible
- Wait 3-5 minutes for cluster setup to complete
- Check logs: `docker logs wiki-cluster-test`
- Verify pods are running: `docker exec -it wiki-cluster-test kubectl get pods`

### k3d cluster creation fails
- Check Docker daemon is running inside container
- Increase timeout in entrypoint.sh if needed
- Check system resources (CPU, memory)

### FastAPI returns errors
- Check if PostgreSQL is ready: `docker exec -it wiki-cluster-test kubectl get pods | grep postgresql`
- Check FastAPI logs: `docker exec -it wiki-cluster-test kubectl logs <fastapi-pod-name>`

### Grafana not accessible
- Verify ingress is configured: `docker exec -it wiki-cluster-test kubectl get ingress`
- Check Grafana pod status: `docker exec -it wiki-cluster-test kubectl get pods | grep grafana`
- Check Grafana logs: `docker exec -it wiki-cluster-test kubectl logs <grafana-pod-name>`

## Cleanup

```bash
# Stop and remove container
docker stop wiki-cluster-test
docker rm wiki-cluster-test

# Remove image (optional)
docker rmi wiki-cluster
```

## Quick Test Script

Save this as `test_part2.sh`:

```bash
#!/bin/bash

echo "Waiting for cluster to be ready..."
sleep 180  # Wait 3 minutes

echo "Testing FastAPI - Create User"
curl -X POST "http://localhost:8080/users" \
  -H "Content-Type: application/json" \
  -d '{"name": "TestUser"}'

echo -e "\n\nTesting FastAPI - Create Post"
curl -X POST "http://localhost:8080/posts" \
  -H "Content-Type: application/json" \
  -d '{"user_id": 1, "content": "Test post"}'

echo -e "\n\nTesting Metrics"
curl -s "http://localhost:8080/metrics" | grep -E "(users_created_total|posts_created_total)"

echo -e "\n\nTest complete! Access Grafana at: http://localhost:8080/grafana/d/creation-dashboard-678/creation"
```

Make it executable and run:
```bash
chmod +x test_part2.sh
./test_part2.sh
```

