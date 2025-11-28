FROM envoyproxy/envoy:v1.30-latest
COPY envoy.yaml /etc/envoy/envoy.yaml
CMD ["envoy", "-c", "/etc/envoy/envoy.yaml", "--service-cluster", "inference-proxy"]

