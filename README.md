# k8s-ml-inference-platform

## Architecture Overview

```mermaid
sequenceDiagram
    autonumber

    participant Client as REST Client (curl)
    participant Ingress as ingress-nginx
    participant EnvoySvc as Service: envoy
    participant Envoy as Envoy Proxy
    participant GrpcSvc as Service: gRPC-server
    participant Grpc as Python gRPC-server

    Client->>Ingress: HTTP POST /v1/infer (JSON)
    Ingress->>EnvoySvc: HTTP request
    EnvoySvc->>Envoy: Forward to Envoy Pod
    Envoy->>Envoy: JSON --> gRPC transcoding
    Envoy->>GrpcSvc: gRPC request
    GrpcSvc->>Grpc: Forward to server pod
    Grpc-->>Envoy: gRPC response
    Envoy->>Envoy: gRPC --> JSON transcoding
    Envoy-->>Client: JSON response
```

## Requirements

Install the following tools:

```bash
brew install colima      # Docker runtime for macOS
brew install kind        # Kubernetes-in-Docker
brew install kubectl     # Kubernetes CLI
```

## SetUp

```
colima start --arch aarch64

# create cluster if not exists ( idempotent )
sh scripts/restart.sh
```

## Monitoring

### Grafana

http://localhost:30091/

### Prometheus

http://localhost:30090/

```mermaid
sequenceDiagram
    autonumber

    participant Browser as Browser
    participant Grafana as Grafana
    participant Prometheus as Prometheus
    participant Target as Metrics Target

    Browser ->> Grafana: open dashboard
    Grafana ->> Prometheus: query metrics
    Prometheus ->> Target: scrape request
    Target -->> Prometheus: metrics data
    Prometheus -->> Grafana: query response
    Grafana -->> Browser: render dashboard
```

### Loki

```mermaid

sequenceDiagram
    autonumber

    participant Browser as Browser
    participant Grafana as Grafana
    participant MLAPI as ML API Pod
    participant ContainersLog as containers log
    participant LokiAgent as Loki Agent DaemonSet
    participant LokiStorage as Loki Storage

    MLAPI ->> MLAPI: write logs to stdout
    MLAPI ->> ContainersLog: logs written by node runtime

    LokiAgent ->> ContainersLog: retrieve log file data
    ContainersLog -->> LokiAgent: return log content

    LokiAgent ->> LokiStorage: push logs
    Browser ->> Grafana: open dashboard
    Grafana ->> LokiStorage: log query
    LokiStorage -->> Grafana: query response
    Grafana -->> Browser: render dashboard
```


### OpenTelemetry (OTEL)

```mermaid

sequenceDiagram
    autonumber

    participant Browser as Browser
    participant Grafana as Grafana
    participant MLAPI as ML API Pod
    participant OTELSDK as OTEL SDK
    participant Collector as OTEL Collector
    participant Tempo as Tempo Storage (Traces)

    MLAPI ->> OTELSDK: generate trace spans
    OTELSDK ->> Collector: push trace data (OTLP)

    Collector ->> Tempo: forward trace data (OTLP)
    Tempo -->> Collector: ack

    Browser ->> Grafana: open dashboard
    Grafana ->> Tempo: trace query
    Tempo -->> Grafana: query response
    Grafana -->> Browser: render trace view

```

### MinIO

http://localhost:9001/browser/tempo-traces

```
kubectl port-forward deployment/minio 9001:9001
```
