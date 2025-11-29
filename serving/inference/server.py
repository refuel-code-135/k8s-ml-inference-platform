import grpc
from concurrent import futures
import time

from serving.api.gen import inference_pb2
from serving.api.gen import inference_pb2_grpc

from grpc_health.v1 import health, health_pb2, health_pb2_grpc


class InferenceService(inference_pb2_grpc.InferenceServiceServicer):
    def Infer(self, request, context):
        text = request.text
        result = f"Echo: {text}"
        return inference_pb2.InferResponse(result=result)


def serve():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))

    # Register your inference service
    inference_pb2_grpc.add_InferenceServiceServicer_to_server(
        InferenceService(), server
    )

    # Register health check service
    health_servicer = health.HealthServicer()
    health_pb2_grpc.add_HealthServicer_to_server(health_servicer, server)

    # Mark services as SERVING
    health_servicer.set('', health_pb2.HealthCheckResponse.SERVING)
    health_servicer.set('inference.v1.InferenceService', health_pb2.HealthCheckResponse.SERVING)

    server.add_insecure_port("[::]:50051")
    server.start()

    try:
        while True:
            time.sleep(86400)
    except KeyboardInterrupt:
        server.stop(0)


if __name__ == "__main__":
    serve()

