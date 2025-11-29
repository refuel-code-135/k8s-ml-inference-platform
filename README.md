# k8s-ml-inference-platform


REST client --HTTP--> envoy --gRPC--> inference gRPC server
gRPC client --gRPC--> envoy --gRPC--> inference gRPC server

Step1:

Docker Desktop
https://www.docker.com/products/docker-desktop/

brew install kind
brew install kubectl
brew install k9s


cd /Users/shohei-ito/Documents/moving/repos/k8s-ml-inference-platform/dev/python;


API公開パターン（主要6パターン＋拡張4 = 10パターン）
REST → Envoy → gRPC → Inference Server（あなたの現在の構成）
gRPC → Envoy → gRPC → Inference Server（あなたの現在の構成）
REST → FastAPI → gRPC Client → gRPC Inference Server
REST → FastAPI（Python処理）→ Model（FastAPI内で直接推論）
REST → nginx → FastAPI（uvicorn/gunicorn）→ Python 推論
REST → nginx → Envoy → gRPC Server（nginx = 外部向けLB）
REST → FastAPI（uvicorn）→ Envoy（gRPC）→ Inference Server
REST → Envoy → FastAPI（gRPC Client）→ gRPC Inference Server
gRPC client → (直接) gRPC Inference Server（Envoy無し）
REST → gunicorn + UvicornWorker（FastAPI）→ Python Inference
