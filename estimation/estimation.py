from abc import ABC, abstractmethod
from pandas import DataFrame
import numpy as np
from sklearn import linear_model

class Estimation(ABC):
    @abstractmethod
    def preprocess_data(self, data: DataFrame) -> DataFrame:
        pass

    @abstractmethod
    def estimate(self, stock_data: DataFrame) -> DataFrame:
        pass

""" 
Gradient Boosting Models: LightGBM > CatBoost > XGBoost (may be more accurate short-term than polynomial)
OR
Random Forest Regression (second best)
"""
class ShortEstimation(Estimation):
    def __init__(self):
        self.predictions = DataFrame()

    def preprocess_data(self, data: DataFrame) -> DataFrame:
        pass

    def estimate(self, stock_data: DataFrame) -> DataFrame:
        pass

""" 
LINEAR REGRESSION (less accurate short-term, more accurate long term) 
Probably use Lasso or Elastic Net Regression (linear but better by reducing overfitting)
"""
class LongEstimation(Estimation):
    def __init__(self):
        self.predictions = DataFrame()

    def preprocess_data(self, data: DataFrame) -> DataFrame:
        pass

    def estimate(self, stock_data: DataFrame) -> DataFrame:
        pass