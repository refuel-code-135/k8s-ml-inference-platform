#!/usr/bin/env bash
set -e

CLUSTER_NAME="ml-serving"
KIND_CONFIG="dev/kind/cluster.yaml"

colima start --arch aarch64

echo "=== Deleting existing Kind cluster (if any) ==="
kind delete cluster --name "${CLUSTER_NAME}" || true

echo "=== Creating Kind cluster ==="
kind create cluster --name "${CLUSTER_NAME}" --config "${KIND_CONFIG}"

echo "=== Installing Ingress-NGINX Controller ==="
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo "=== Waiting for ingress controller to be ready ==="
kubectl wait --namespace ingress-nginx \
  --for=condition=Ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s

echo "=== Building Docker images ==="
docker build --no-cache -t grpc-server:latest -f docker/grpc-server.Dockerfile .

echo "=== Loading images into Kind nodes ==="
kind load docker-image grpc-server:latest --name "${CLUSTER_NAME}"

docker pull ghcr.io/mlflow/mlflow:v2.0.1
kind load docker-image ghcr.io/mlflow/mlflow:v2.0.1 --name ml-serving


echo "=== Recreating Envoy descriptor secret ==="
kubectl delete secret envoy-descriptor -n default --ignore-not-found
kubectl create secret generic envoy-descriptor \
  --from-file=config/envoy/inference_descriptor.pb \
  -n default

echo "=== Applying MinIO manifests ==="
kubectl apply -f storage/minio/minio-persistent-volume-claim.yaml
kubectl apply -f storage/minio/minio-deployment.yaml
kubectl apply -f storage/minio/minio-service.yaml

echo "=== Waiting for MinIO to be ready ==="
kubectl wait --for=condition=Ready pod \
  -l app=minio \
  --timeout=120s

echo "=== Creating MinIO bucket: tempo-traces ==="
kubectl exec deployment/minio -- sh -c "
  mc alias set local http://localhost:9000 minio minio123 >/dev/null 2>&1
  mc mb -p local/tempo-traces >/dev/null 2>&1 || true
"


echo "=== Creating MinIO bucket: mlflow-artifacts ==="
kubectl exec deployment/minio -- sh -c "
  mc alias set local http://localhost:9000 minio minio123 >/dev/null 2>&1
  mc mb -p local/mlflow-artifacts >/dev/null 2>&1 || true
"

echo "=== Creating MLflow secrets ==="

kubectl create secret generic mlflow-minio-secret \
  --from-literal=accesskey=minio \
  --from-literal=secretkey=minio123 \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic mlflow-db-secret \
  --from-literal=uri="postgresql://mlflow_user:mlflow_password@db-service:5432/mlflow_db" \
  --dry-run=client -o yaml | kubectl apply -f -



echo "=== Applying application manifests ==="
kubectl apply -R -f manifests/

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

kubectl patch deployment metrics-server -n kube-system \
  --type='json' \
  -p='[
    {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"},
    {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-preferred-address-types=InternalIP"}
  ]'



echo "=== Restarting all manifests ==="
for d in $(kubectl get deploy -n default -o name); do
  kubectl rollout restart -n default "$d"
done

echo "=== Running cluster check ==="
sh scripts/check.sh

echo "=== Done! The cluster has been rebuilt cleanly ==="

