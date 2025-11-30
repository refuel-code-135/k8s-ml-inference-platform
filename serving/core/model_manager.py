import os
from serving.core.loaders.lightgbm_loader import LightGBMModelLoader


class ModelManager:

    def __init__(self):
        self.model_path = "models/artifacts/lightgbm_model.pkl"

        # LightGBM Loader
        self.loader = LightGBMModelLoader(self.model_path)

    def get_model(self):
        """
        Returns the loaded model.
        Loader should do lazy loading (load only once).
        """
        return self.loader.load()
