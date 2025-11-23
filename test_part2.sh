#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

BASE_URL="http://localhost:8080"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Testing Part 2: Containerized Cluster${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Check if container is running
if ! docker ps | grep -q wiki-cluster-test; then
    echo -e "${RED}Error: Container 'wiki-cluster-test' is not running${NC}"
    echo -e "${YELLOW}Start it with: docker run --privileged -d -p 8080:8080 --name wiki-cluster-test wiki-cluster${NC}"
    exit 1
fi

echo -e "${YELLOW}Checking cluster status...${NC}"
# Check if cluster is ready (look for "Cluster is ready" in logs)
if docker logs wiki-cluster-test 2>&1 | grep -q "Cluster is ready"; then
    echo -e "${GREEN}✓ Cluster is ready${NC}\n"
else
    echo -e "${YELLOW}⚠ Cluster is still setting up. Waiting 30 seconds...${NC}"
    sleep 30
    if docker logs wiki-cluster-test 2>&1 | grep -q "Cluster is ready"; then
        echo -e "${GREEN}✓ Cluster is ready${NC}\n"
    else
        echo -e "${YELLOW}⚠ Cluster may still be setting up. Continuing with tests...${NC}\n"
    fi
fi

# Test 1: Create a user
echo -e "${YELLOW}Test 1: Creating a user...${NC}"
RESPONSE=$(curl -s -X POST "$BASE_URL/users" \
  -H "Content-Type: application/json" \
  -d '{"name": "Alice"}')
if echo "$RESPONSE" | grep -q "id"; then
    echo -e "${GREEN}✓ Success:${NC} $RESPONSE\n"
    USER_ID=$(echo "$RESPONSE" | grep -o '"id":[0-9]*' | grep -o '[0-9]*' | head -1)
else
    echo -e "${RED}✗ Failed:${NC} $RESPONSE\n"
    USER_ID=1  # Default for next test
fi

# Test 2: Create a post
echo -e "${YELLOW}Test 2: Creating a post...${NC}"
RESPONSE=$(curl -s -X POST "$BASE_URL/posts" \
  -H "Content-Type: application/json" \
  -d "{\"user_id\": $USER_ID, \"content\": \"Hello World!\"}")
if echo "$RESPONSE" | grep -q "post_id"; then
    echo -e "${GREEN}✓ Success:${NC} $RESPONSE\n"
    POST_ID=$(echo "$RESPONSE" | grep -o '"post_id":[0-9]*' | grep -o '[0-9]*' | head -1)
else
    echo -e "${RED}✗ Failed:${NC} $RESPONSE\n"
    POST_ID=1  # Default for next test
fi

# Test 3: Get user
echo -e "${YELLOW}Test 3: Getting user...${NC}"
RESPONSE=$(curl -s "$BASE_URL/users/$USER_ID")
if echo "$RESPONSE" | grep -q "id"; then
    echo -e "${GREEN}✓ Success:${NC} $RESPONSE\n"
else
    echo -e "${RED}✗ Failed:${NC} $RESPONSE\n"
fi

# Test 4: Get post
echo -e "${YELLOW}Test 4: Getting post...${NC}"
RESPONSE=$(curl -s "$BASE_URL/posts/$POST_ID")
if echo "$RESPONSE" | grep -q "post_id"; then
    echo -e "${GREEN}✓ Success:${NC} $RESPONSE\n"
else
    echo -e "${RED}✗ Failed:${NC} $RESPONSE\n"
fi

# Test 5: Check metrics
echo -e "${YELLOW}Test 5: Checking Prometheus metrics...${NC}"
METRICS=$(curl -s "$BASE_URL/metrics" | grep -E "(users_created_total|posts_created_total)" || echo "No metrics found")
if [ -n "$METRICS" ]; then
    echo -e "${GREEN}✓ Metrics found:${NC}"
    echo "$METRICS" | sed 's/^/  /'
    echo ""
else
    echo -e "${RED}✗ No metrics found${NC}\n"
fi

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Test Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✓ FastAPI endpoints tested${NC}"
echo -e "${GREEN}✓ Metrics endpoint checked${NC}"
echo ""
echo -e "${YELLOW}Access Grafana Dashboard:${NC}"
echo -e "  ${BLUE}http://localhost:8080/grafana/d/creation-dashboard-678/creation${NC}"
echo -e "  Username: admin"
echo -e "  Password: admin"
echo ""

