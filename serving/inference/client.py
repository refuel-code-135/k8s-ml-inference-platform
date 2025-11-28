import grpc
from serving.api.gen import inference_pb2
from serving.api.gen import inference_pb2_grpc


def main():
    channel = grpc.insecure_channel("localhost:50051")
    stub = inference_pb2_grpc.InferenceServiceStub(channel)

    req = inference_pb2.InferRequest(text="hello")
    res = stub.Infer(req)
    print("Response:", res.result)


if __name__ == "__main__":
    main()

