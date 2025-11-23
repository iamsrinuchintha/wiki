# Testing Guide for Wikipedia-like API Service

## Prerequisites

- Python 3.13 (as specified in `.python-version`)
- `uv` package manager (recommended) OR `pip` and `venv`

## Method 1: Using `uv` (Recommended)

### Step 1: Install Dependencies

```bash
# Install uv if you don't have it
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install project dependencies
uv sync
```

### Step 2: Run the FastAPI Server

```bash
# Activate the virtual environment created by uv
source .venv/bin/activate

# Run the server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

The server will start at `http://localhost:8000`

## Method 2: Using `pip` and `venv`

### Step 1: Create Virtual Environment

```bash
python3.13 -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
```

### Step 2: Install Dependencies

```bash
# Install from pyproject.toml
pip install -e .

# OR install dependencies manually
pip install fastapi uvicorn sqlalchemy aiosqlite prometheus-client pydantic greenlet
```

### Step 3: Run the FastAPI Server

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Step 3: Test the API

### Option A: Use the Provided Test Script

```bash
# Make sure the server is running on port 8000
# Update BASE_URL in test_api.sh if needed (default is port 8080)

# Make the script executable
chmod +x test_api.sh

# Run the test script
./test_api.sh
```

**Note:** The test script expects the server on port 8080 by default. Either:
- Change `BASE_URL` in `test_api.sh` to `http://localhost:8000`, OR
- Run the server on port 8080: `uvicorn app.main:app --reload --host 0.0.0.0 --port 8080`

### Option B: Manual Testing with curl

#### 1. Check Root Endpoint
```bash
curl http://localhost:8000/
```

#### 2. Create a User
```bash
curl -X POST "http://localhost:8000/users" \
  -H "Content-Type: application/json" \
  -d '{"name": "Alice"}'
```

#### 3. Get User by ID
```bash
curl http://localhost:8000/user/1
```

#### 4. Create a Post
```bash
curl -X POST "http://localhost:8000/posts" \
  -H "Content-Type: application/json" \
  -d '{"user_id": 1, "content": "Hello World! This is my first post."}'
```

#### 5. Get Post by ID
```bash
curl http://localhost:8000/posts/1
```

#### 6. Check Prometheus Metrics
```bash
curl http://localhost:8000/metrics
```

To see only the custom metrics:
```bash
curl http://localhost:8000/metrics | grep -E "(users_created_total|posts_created_total)"
```

### Option C: Use the Interactive API Documentation

1. Open your browser and go to: `http://localhost:8000/docs`
2. This opens Swagger UI where you can:
   - See all available endpoints
   - Test endpoints interactively
   - View request/response schemas

Alternatively, visit `http://localhost:8000/redoc` for ReDoc documentation.

## Step 4: Verify Database

After running the server, you should see a file `app.db` created in the project root (SQLite database).

To inspect the database:
```bash
# Install sqlite3 if not available
sqlite3 app.db

# In sqlite3 prompt:
.tables                    # List all tables
SELECT * FROM users;       # View all users
SELECT * FROM posts;       # View all posts
.quit                      # Exit
```

## Step 5: Monitor Metrics

### Check Metrics After Creating Users/Posts

1. Create a few users and posts using the API
2. Check metrics:
```bash
curl http://localhost:8000/metrics | grep -E "(users_created_total|posts_created_total)"
```

You should see output like:
```
# HELP users_created_total Total number of users created
# TYPE users_created_total counter
users_created_total 3.0
# HELP posts_created_total Total number of posts created
# TYPE posts_created_total counter
posts_created_total 2.0
```

## Troubleshooting

### Port Already in Use
If port 8000 is already in use:
```bash
# Find and kill the process
lsof -ti:8000 | xargs kill -9

# OR use a different port
uvicorn app.main:app --reload --host 0.0.0.0 --port 8001
```

### Database Locked Error
If you see database locked errors:
```bash
# Remove the existing database
rm app.db

# Restart the server (it will recreate the database)
```

### Module Not Found Errors
Make sure you're in the virtual environment:
```bash
# Check if you're in venv (should show .venv path)
which python

# If not, activate it
source .venv/bin/activate
```

### Python Version Issues
Ensure you're using Python 3.13:
```bash
python --version  # Should show Python 3.13.x
```

## Expected Test Results

After running the test script, you should see:
- ✓ Created 3 users
- ✓ Retrieved users by ID
- ✓ Created 3 posts
- ✓ Retrieved posts by ID
- ✓ Tested error handling (404s)
- ✓ Verified Prometheus metrics

## Next Steps

Once testing is complete, you can proceed with:
1. Creating the Dockerfile for containerization
2. Setting up PostgreSQL configuration
3. Creating the Helm chart for Kubernetes deployment

