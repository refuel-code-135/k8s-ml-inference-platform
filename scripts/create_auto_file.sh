#rm -rf venv
#python3 -m venv venv

source venv/bin/activate
pip install -r requirements/dev.txt

protoc \
    -I serving/api/proto \
    -I serving/api/proto/google/api \
    --include_imports \
    --include_source_info \
    --descriptor_set_out=config/envoy/inference_descriptor.pb \
    serving/api/proto/inference.proto
