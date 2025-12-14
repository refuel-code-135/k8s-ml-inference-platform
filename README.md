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

#### Prometheus: Data Collection Phase

```mermaid
sequenceDiagram
    autonumber

    participant Prom as Prometheus
    participant TSDB as Prometheus (internal TSDB)
    participant Target as Metrics Target

    Prom ->> Target: GET /metrics (scrape)
    Target -->> Prom: metrics data
    Prom ->> TSDB: append metrics data

```

#### Prometheus: Data Visualization Phase

```mermaid
sequenceDiagram
    autonumber

    participant Browser as Browser
    participant Grafana as Grafana
    participant Prom as Prometheus
    participant TSDB as Prometheus (internal TSDB)

    Browser ->> Grafana: open dashboard
    Grafana ->> Prom: query metrics (PromQL)
    Prom ->> TSDB: read metrics data
    TSDB -->> Prom: query result
    Prom -->> Grafana: query response
    Grafana -->> Browser: render dashboard

```

### Loki

#### Loki: Data Collection Phase

```mermaid
sequenceDiagram
    autonumber

    participant App as Application Pod
    participant Runtime as Container Runtime (log files)
    participant Agent as Loki Agent (DaemonSet)
    participant Loki as Loki (Ingest)
    participant Storage as Loki Storage (MinIO)

    App ->> App: write logs to stdout/stderr
    App ->> Runtime: logs written by container runtime

    Agent ->> Runtime: read log files
    Runtime -->> Agent: log entries

    Agent ->> Loki: push log streams
    Loki ->> Storage: store log chunks

```

#### Loki: Data Visualization Phase


```mermaid

sequenceDiagram
    autonumber

    participant Browser as Browser
    participant Grafana as Grafana
    participant Loki as Loki (Query)
    participant Storage as Loki Storage (MinIO)

    Browser ->> Grafana: open dashboard
    Grafana ->> Loki: log query (LogQL)
    Loki ->> Storage: read log chunks
    Storage -->> Loki: log data
    Loki -->> Grafana: query response
    Grafana -->> Browser: render logs

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
