#!/bin/bash
docker pull ollama/ollama:latest
docker build -f Dockerfile.ollama -t devprom/ollama:latest .
docker push devprom/ollama:latest
