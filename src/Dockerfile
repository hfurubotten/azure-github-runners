FROM ghcr.io/actions/actions-runner:2.335.1

USER root

# Install dependencies in start.sh (jq + curl already usually present, but ensure)
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    jq \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install more tools that's needed on your runner here

# add start script for the runner in filesystem
COPY start.sh start.sh
RUN chmod +x start.sh

USER runner

ENTRYPOINT ["./start.sh"]
