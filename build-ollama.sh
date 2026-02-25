cat << _EOF_ > Dockerfile
FROM ollama/ollama:latest

COPY ollama/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
_EOF_

docker pull ollama/ollama:latest
docker build -t devprom/ollama:latest .
docker push devprom/ollama:latest
