# Dockerfile for running k3d cluster with the wiki service
FROM docker:dind

# Install necessary tools
RUN apk add --no-cache \
    curl \
    bash \
    git \
    openssl \
    ca-certificates \
    iptables \
    ip6tables \
    && rm -rf /var/cache/apk/*

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/

# Install Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install k3d
RUN curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Set working directory
WORKDIR /workspace

# Copy wiki-service and wiki-chart directories
COPY wiki-service/ ./wiki-service/
COPY wiki-chart/ ./wiki-chart/

# Copy helper scripts
COPY entrypoint.sh ./entrypoint.sh
RUN chmod +x ./entrypoint.sh

# Expose port 8080
EXPOSE 8080

# Start Docker daemon and run entrypoint
ENTRYPOINT ["/workspace/entrypoint.sh"]

