# ===== Builder stage =====
FROM python:3.11-slim-bookworm AS builder

WORKDIR /app

COPY requirements/prod.txt requirements.txt
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Download grpc_health_probe
RUN apt-get update && apt-get install -y curl \
    && curl -L https://github.com/grpc-ecosystem/grpc-health-probe/releases/download/v0.4.11/grpc_health_probe-linux-arm64 \
        -o /grpc_health_probe \
    && echo "c90f9894f49bab503b22936df1adf5251f7291e26edbf40de549a70b4ebaba70  /grpc_health_probe" | sha256sum -c - \
    && chmod +x /grpc_health_probe \
    && apt-get clean


# ===== Runtime stage =====
FROM python:3.11-slim-bookworm

WORKDIR /app

# Copy only runtime dependencies
COPY --from=builder /install /usr/local
COPY --from=builder /grpc_health_probe /usr/local/bin/grpc_health_probe

COPY serving /app/serving

ENV PYTHONPATH="/app"

EXPOSE 50051

CMD ["python", "serving/service/server.py"]

