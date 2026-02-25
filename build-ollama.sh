#!/bin/bash
cat << _EOF_ > Dockerfile
FROM ollama/ollama:latest

# Script to pull models on first run
COPY <<'EOF' /entrypoint.sh
#!/bin/bash
set -e

# Start Ollama server in background
ollama serve &
SERVER_PID=$!

# Wait for server to be ready
until curl -s http://localhost:11434/api/tags > /dev/null 2>&1; do
    sleep 1
done

# Pull required models if not present
MODELS="nomic-embed-text"
for model in $MODELS; do
    if ! ollama list | grep -q "$model"; then
        echo "Pulling $model..."
        ollama pull "$model"
    fi
done

# Keep server running
wait $SERVER_PID
EOF

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
_EOF_

docker pull ollama/ollama:latest
docker build -t devprom/ollama:latest .
docker push devprom/ollama:latest
