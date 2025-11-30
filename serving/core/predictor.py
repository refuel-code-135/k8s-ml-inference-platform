from serving.core.model_manager import ModelManager


class Predictor:
    def __init__(self):
        self.model_manager = ModelManager()

    def run(self, input_text: str):
        model = self.model_manager.get_model()

        result = model.predict([input_text])[0]

        return f"Predicted: {result}"
