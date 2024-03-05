import time

import numpy

import database
import asyncio
import pickle
import numpy as np
import os
from path import Path

from sklearn.ensemble import IsolationForest
from sklearn import preprocessing
import sys
import database
from pyod.models import pca
# directory reach
directory = Path(__file__).abspath()
# setting path
sys.path.append(directory.parent.parent)

server = database.PostgresServer()
models_path = "models"
model = None


def find_or_create_folder(root_dir, target_folder):
    for root, dirs, files in os.walk(root_dir):
        if target_folder in dirs:
            return os.path.join(root, target_folder)
    # If the folder doesn't exist, create it
    new_folder_path = os.path.join(root_dir, target_folder)
    os.makedirs(new_folder_path)
    return new_folder_path


class Model():
    def __init__(self, **config):
        self.config = config
        print(config)
        super().__init__(**config)


class Operations:
    def __init__(self):
        self.postgres = database.PostgresServer()
        self.postgres.connect()
        self.progress = 0
        self.model_config = {'n_ensemble': 5, 'n_estimators': 2, 'verbose': 2, 'batch_size': 1, 'hidden_dim': [128,64], 'activation': 'relu'}
        #model = Model(**model_config)
        self.is_training_enabled = True

    async def start_training(self, user_id: int, model_id: int):

        user_folder_path = find_or_create_folder(models_path, str(user_id))
        model_folder_path = find_or_create_folder(user_folder_path, str(model_id))
        try:
            server.connect()
        except Exception as e:
            print('Cant connect to DB: ', e)
        self.is_training_enabled = True

        model_info = server.get_model(user_id, model_id)[0]
        data_size = model_info[3]
        train_data = server.get_data(user_id, model_id, data_size)
        print(data_size)
        print('-----------------------------------')
        train_data = np.array(train_data)[:, 3:-1]
        train_data = np.asarray(train_data, dtype=np.float32)
        #train_data = preprocessing.normalize(train_data)
        print(train_data)
        input_size = train_data.shape[1]
        # preprocess data
        nan_indices = np.isnan(train_data).any(axis=1)
        train_data = train_data[~nan_indices]
        print(train_data.shape)
        model = pca.PCA()

        #model.
        model.fit(train_data)
        self.progress = 1
        self.postgres.set_model_trained(user_id, model_id)

        # save the model
        pickle.dump(model, open(model_folder_path+"\\model.pkl", 'wb'))

        return True

    async def predict(self, user_id: int, model_id: int, row) -> numpy.ndarray:
        row = [row]
        rand = np.random.randint(0,8)
        if rand == 0:
            row = np.random.rand(1,3)
        model = pickle.load(open(f"models/{user_id}/{model_id}/model.pkl", 'rb'))
        prediction = model.decision_function(row)
        return prediction

    async def stop_training(self, user_id: int, model_id: int):
        self.is_training_enabled = False

    async def get_progress(self, user_id: int, model_id: int):
        print(self.progress)
        return True, self.progress

    def check_if_model_is_trained(self, user_id: int, model_id: int):
        pass


