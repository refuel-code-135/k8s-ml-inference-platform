import lightgbm as lgb
from .helper import generate_dummy_data, save_model

def train_lightgbm():
    X, y = generate_dummy_data()

    train_data = lgb.Dataset(X, label=y)
    params = {"objective": "binary"}

    model = lgb.train(params, train_data, num_boost_round=10)
    save_model(model)

    print("LightGBM model trained.")

