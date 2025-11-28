# k8s-ml-inference-platform


REST client --HTTP--> envoy --gRPC--> inference gRPC server
gRPC client --gRPC--> envoy --gRPC--> inference gRPC server

Step1:

Docker Desktop
https://www.docker.com/products/docker-desktop/

brew install kind
brew install kubectl
brew install k9s


cd dev/python
python3.11 -m venv venv      
source venv/bin/activate
pip install --upgrade pip

pip install -r requirements.txt


export PYTHONPATH=$(pwd)
