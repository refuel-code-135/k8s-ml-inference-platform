from serving.core.loaders.base_loader import BaseModelLoader


class LightGBMModelLoader(BaseModelLoader):

    class MockModel:
        def predict(self, inputs):
            # NOTE : Always return fixed output for testing
            return ["mock_prediction"]

    def __init__(self, model_path: str):
        self.model_path = model_path
        self._model = None

    def load(self):
        if self._model is None:
            print(f"[MockModelLoader] Loading mock model from {self.model_path}")
            self._model = self.MockModel()
        return self._model
