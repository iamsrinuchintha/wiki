# Wiki K3d Local Runner

This project allows you to build and run the `wiki-k3d` Docker image locally for testing.

## Quick Start

### Build the image

```bash
docker build -t wiki-k3d:latest .
```

### Run the container

```bash
docker run -it --rm \
  --privileged \
  --cgroupns=host \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  -p 8080:8080 \
  --name wiki-local \
  wiki-k3d:latest
```

Service will be available at:
**[http://localhost:8080](http://localhost:8080)**

---

## Test the API

Run:

```bash
./test_api.sh
```

This verifies that the container is up and responding.

---

## Explanation of Docker Flags

* `--privileged` — required for running k3d or processes that need deeper system access
* `--cgroupns=host` — exposes the host cgroup namespace
* `-v /sys/fs/cgroup:/sys/fs/cgroup:rw` — mounts cgroup filesystem for k3d/k3s compatibility
* `-p 8080:8080` — exposes the service outside the container

---

## Cleanup

The container automatically removes itself on exit because of `--rm`.

To stop manually:

```bash
docker stop wiki-local
```
