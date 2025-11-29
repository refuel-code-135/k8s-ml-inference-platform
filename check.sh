#!/usr/bin/env bash
set -e

MODE="$1"

echo "=== Showing all resources ==="
kubectl get all

echo
echo "=== Cluster nodes ==="
if [ "$MODE" = "detail" ]; then
  kubectl get nodes -o wide
else
  kubectl get nodes
fi

echo
echo "=== Pods across all namespaces ==="
if [ "$MODE" = "detail" ]; then
  kubectl get pods -A -o wide
else
  kubectl get pods -A
fi

echo
echo "=== Services ==="
if [ "$MODE" = "detail" ]; then
  kubectl get svc -o wide
else
  kubectl get svc
fi

echo
echo "=== Sending inference request ==="
curl -X POST http://localhost:30080/v1/infer \
  -H "Content-Type: application/json" \
  -d '{"text":"hello envoy"}'
echo

