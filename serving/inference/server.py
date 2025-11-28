import grpc
from concurrent import futures
import time

from serving.api.gen import inference_pb2
from serving.api.gen import inference_pb2_grpc


class InferenceService(inference_pb2_grpc.InferenceServiceServicer):
    def Infer(self, request, context):
        text = request.text
        result = f"Echo: {text}"
        return inference_pb2.InferResponse(result=result)


def serve():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    inference_pb2_grpc.add_InferenceServiceServicer_to_server(
        InferenceService(), server
    )
    server.add_insecure_port("[::]:50051")
    print("🚀 gRPC Inference Server is running on port 50051")
    server.start()
    try:
        while True:
            time.sleep(86400)
    except KeyboardInterrupt:
        server.stop(0)


if __name__ == "__main__":
    serve()

