#!/usr/bin/env bash
set -e

CLUSTER_NAME="ml-serving"
KIND_CONFIG="dev/kind/cluster.yaml"

echo "=== (1) Kind クラスタ削除（存在するなら） ==="
kind delete cluster --name "${CLUSTER_NAME}" || true

echo "=== (2) Kind クラスタ作成 ==="
kind create cluster --name "${CLUSTER_NAME}" --config "${KIND_CONFIG}"

echo "=== (3) gRPC Server Docker イメージ作成 ==="
docker build -t grpc-server:latest -f infra/docker/grpc-server/Dockerfile .

echo "=== (4) Kind ノードへ Docker イメージをロード ==="
kind load docker-image grpc-server:latest --name "${CLUSTER_NAME}"

echo "=== (5) Envoy の descriptor Secret 再作成 ==="
kubectl delete secret envoy-descriptor -n default --ignore-not-found
kubectl create secret generic envoy-descriptor \
  --from-file=infra/envoy/inference_descriptor.pb \
  -n default

echo "=== (6) Kubernetes マニフェスト適用 ==="
kubectl apply -f infra/k8s/grpc-server/
kubectl apply -f infra/k8s/envoy/

echo "=== (7) Deployment 再起動（冪等） ==="
for d in $(kubectl get deploy -n default -o name); do
  kubectl rollout restart -n default $d
done

echo "=== (8) 状態確認 ==="
kubectl get nodes
kubectl get pods -A
kubectl get svc -A

echo "=== 完了！クラスタはクリーンに再構築されました ==="

