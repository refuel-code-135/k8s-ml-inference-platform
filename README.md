# k8s-ml-inference-platform

## Architecture Overview

```mermaid
sequenceDiagram
    autonumber

    participant Client as REST Client (curl)
    participant Ingress as NGINX Ingress Controller (Pod)
    participant EnvoySvc as Envoy (k8s Service) 
    participant Envoy as Envoy L7 proxy (Pod)
    participant GrpcSvc as gRPC-server (k8s Service) 
    participant Grpc as Python gRPC-server (Pod)

    Client->>Ingress: HTTP POST /v1/infer (JSON)
    Ingress->>EnvoySvc: HTTP request
    EnvoySvc->>Envoy: Forward to Envoy Pod
    Envoy->>Envoy: JSON -> gRPC transcoding
    Envoy->>GrpcSvc: gRPC request
    GrpcSvc->>Grpc: Forward to server pod
    Grpc-->>Envoy: gRPC response
    Envoy->>Envoy: gRPC -> JSON transcoding
    Envoy-->>Ingress: JSON response
    Ingress-->>Client: HTTP response (JSON)

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

#### OTEL: Data Collection Phase


```mermaid

sequenceDiagram
    autonumber

    participant App as Application Pod
    participant Collector as OpenTelemetry Collector (k8s DaemonSet)
    participant Tempo as Tempo Storage (MinIO)

    App ->> App: start spans using OpenTelemetry SDK
    App ->> Collector: export trace data using OpenTelemetry SDK over OpenTelemetry Protocol (OTLP)
    Collector ->> Tempo: store trace data

```

#### OTEL: Data Visualization Phase


```mermaid

sequenceDiagram
    participant Browser
    participant Grafana
    participant Tempo as Tempo Storage (MinIO)

    Browser ->> Grafana: open dashboard
    Grafana ->> Tempo: query traces (TraceQL)
    Tempo -->> Grafana: trace query result
    Grafana -->> Browser: render trace view


```


### MinIO

http://localhost:9001/browser/tempo-traces

```
kubectl port-forward deployment/minio 9001:9001
```
