import grpc
from concurrent import futures
import signal
import sys

from serving.api.gen import inference_pb2
from serving.api.gen import inference_pb2_grpc

from serving.core.predictor import Predictor


class InferenceService(inference_pb2_grpc.InferenceServiceServicer):
    def __init__(self):
        self.predictor = Predictor()

    def Infer(self, request, context):
        input_text = request.text
        result_text = self.predictor.run(input_text)
        return inference_pb2.InferResponse(result=result_text)


def serve():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))

    inference_pb2_grpc.add_InferenceServiceServicer_to_server(
        InferenceService(), server
    )

    server.add_insecure_port("[::]:50051")
    server.start()

    print("Inference gRPC server started on port 50051")

    # Graceful shutdown handler
    def handle_sigterm(*args):
        print("Received SIGTERM. Shutting down gracefully...")
        server.stop(0)
        sys.exit(0)

    signal.signal(signal.SIGTERM, handle_sigterm)

    try:
        # Official recommended blocking call
        server.wait_for_termination()
    except KeyboardInterrupt:
        print("KeyboardInterrupt received. Stopping server...")
        server.stop(0)


if __name__ == "__main__":
    serve()
