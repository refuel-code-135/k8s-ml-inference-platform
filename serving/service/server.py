import grpc
from concurrent import futures
import signal
import sys

from serving.api.gen import inference_pb2
from serving.api.gen import inference_pb2_grpc

from serving.core.predictor import Predictor

from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter

from opentelemetry.instrumentation.grpc import GrpcInstrumentorServer

from opentelemetry.propagate import set_global_textmap
from opentelemetry.trace.propagation.tracecontext import TraceContextTextMapPropagator


def init_tracing():
    provider = TracerProvider()
    trace.set_tracer_provider(provider)

    exporter = OTLPSpanExporter(
        endpoint="http://otel-collector:4318/v1/traces",
    )
    processor = BatchSpanProcessor(exporter)
    provider.add_span_processor(processor)

    set_global_textmap(TraceContextTextMapPropagator())

    print("OTEL tracing initialized")


class InferenceService(inference_pb2_grpc.InferenceServiceServicer):
    def __init__(self):
        self.predictor = Predictor()
        self.tracer = trace.get_tracer(__name__)

    def Infer(self, request, context):
        # 手動で span を作成
        with self.tracer.start_as_current_span("Infer"):
            result_text = self.predictor.run(request.text)
            return inference_pb2.InferResponse(result=result_text)


def serve():
    init_tracing()

    GrpcInstrumentorServer().instrument()

    # === gRPC Server ===
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    inference_pb2_grpc.add_InferenceServiceServicer_to_server(
        InferenceService(), server
    )

    server.add_insecure_port("[::]:50051")
    server.start()
    print("Inference gRPC server started on port 50051")

    # Graceful shutdown
    def handle_sigterm(*args):
        print("Received SIGTERM. Shutting down gracefully...")
        server.stop(0)
        sys.exit(0)

    signal.signal(signal.SIGTERM, handle_sigterm)

    try:
        server.wait_for_termination()
    except KeyboardInterrupt:
        server.stop(0)


if __name__ == "__main__":
    serve()
