FROM python:3.11-slim-bookworm

WORKDIR /app

COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY serving /app/serving

ENV PYTHONPATH="/app"

# Install grpc_health_probe
RUN apt-get update && apt-get install -y curl \
    && curl -L https://github.com/grpc-ecosystem/grpc-health-probe/releases/download/v0.4.11/grpc_health_probe-linux-arm64 \
        -o /usr/local/bin/grpc_health_probe \
    && chmod +x /usr/local/bin/grpc_health_probe \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

EXPOSE 50051

CMD ["python", "serving/service/server.py"]

