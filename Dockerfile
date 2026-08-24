# 1. Start with a lightweight, secure Linux base image
FROM debian:stable-slim

# 2. Install only the specific network utilities your script needs
RUN apt-get update && apt-get install -y \
    bash \
    iputils-ping \
    dnsutils \
    iproute2 \
    sed \
    coreutils \
    && rm -rf /var/lib/apt/lists/*

# 3. Create a workspace directory inside the container
WORKDIR /app

# 4. Copy your script from your computer into the container
COPY netcheck.sh /app/netcheck.sh

# 5. Make the script executable inside the container
RUN chmod +x /app/netcheck.sh

# 6. Tell Docker to execute your script automatically when it starts
ENTRYPOINT ["/app/netcheck.sh"]