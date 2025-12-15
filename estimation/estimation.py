from abc import ABC, abstractmethod
from pandas import DataFrame
import lightgbm as lgb
import pandas as pd
from sklearn.metrics import mean_squared_error
import numpy as np
from prophet import Prophet

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
    """
    Autoregressive multi-step stock forecaster (real-world mode).

    - Uses past price changes in a sliding window to predict next-day change.
    - Trains on ALL available historical samples (no train/test split).
    - Forecasts `horizon` steps beyond the last date in the dataframe.
    """

    def __init__(self, horizon: int = 21, window_size: int = 10):
        self.horizon = horizon
        self.window_size = window_size
        self.model = None

    # Preprocess
    def preprocess_data(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Ensure sorted by date and add a Change column.
        Expects df to have at least a 'Close' column.
        """
        df = df.copy()
        df = df.sort_index()
        df["Change"] = df["Close"].diff()
        return df

    # Build training data (ALL data)
    def build_training_data(self, df: pd.DataFrame):
        """
        Build X_train, y_train using a sliding window of past changes.

        Returns:
          X_train, y_train,
          last_close (last close in df),
          last_window (last `window_size` changes ending at last row),
          forecast_index (future dates to label forecasts, if possible)
        """
        df = self.preprocess_data(df)
        closes = df["Close"].values
        changes = df["Change"].values
        N = len(df)

        if N <= self.window_size + 1:
            raise ValueError(
                f"Not enough data: need > {self.window_size + 1} rows, have {N}"
            )

        X_list = []
        y_list = []

        # Build training samples: predict change[t] from previous `window_size` changes.
        for t in range(self.window_size, N):
            window = changes[t - self.window_size: t]  # shape (window_size,)
            target = changes[t]  # change at time t

            # Skip if any NaNs in window/target
            if np.any(np.isnan(window)) or np.isnan(target):
                continue

            X_list.append(window)
            y_list.append(target)

        if not X_list:
            raise ValueError("No valid training samples (too many NaNs or too little data).")

        X_train = np.array(X_list)  # (num_samples, window_size)
        y_train = np.array(y_list)  # (num_samples,)

        # Last known close is the most recent close in df
        last_close = float(closes[-1])

        # Last window of changes ending at the last row
        last_window = changes[-self.window_size:]
        if np.any(np.isnan(last_window)):
            raise ValueError("Not enough clean history to build last window of changes.")

        # Try to create a future index. If index isn't datetime-like, fall back to a RangeIndex.
        idx = df.index
        if isinstance(idx, pd.DatetimeIndex) and len(idx) >= 2:
            inferred = pd.infer_freq(idx)
            if inferred is not None:
                forecast_index = pd.date_range(start=idx[-1], periods=self.horizon + 1, freq=inferred)[1:]
            else:
                # fallback: use last step as delta
                step = idx[-1] - idx[-2]
                forecast_index = pd.DatetimeIndex([idx[-1] + step * (i + 1) for i in range(self.horizon)])
        else:
            forecast_index = pd.RangeIndex(start=0, stop=self.horizon, step=1)

        return X_train, y_train, last_close, last_window, forecast_index

    # Train model
    def train(self, X_train: np.ndarray, y_train: np.ndarray):
        """
        Train a LightGBM regressor on (X_train, y_train).
        """
        model = lgb.LGBMRegressor(
            n_estimators=500,
            learning_rate=0.05,
            num_leaves=31,
            subsample=0.9,
            colsample_bytree=0.9,
            max_depth=-1,
            reg_alpha=0.0,
            reg_lambda=0.0,
            min_child_samples=20,
        )
        model.fit(X_train, y_train)
        self.model = model

    # Autoregressive forecast
    def forecast(self, last_close: float, last_window: np.ndarray):
        """
        Roll forward autoregressively for `self.horizon` steps.

        last_close: last known close price (most recent close in df).
        last_window: np.array of shape (window_size,) with the most recent
                     `window_size` daily changes ending at the last row.
        """
        if self.model is None:
            raise RuntimeError("Model is not trained. Call train() first.")

        window_buf = last_window.astype(float).copy()
        preds_changes = []
        preds_prices = []

        current_close = float(last_close)
        feature_names = [str(i) for i in range(self.window_size)]

        for _ in range(self.horizon):
            X_input = pd.DataFrame([window_buf], columns=feature_names)
            pred_change = float(self.model.predict(X_input)[0])

            preds_changes.append(pred_change)

            # Update price
            current_close = current_close + pred_change
            preds_prices.append(current_close)

            # Slide window and append this predicted change
            window_buf = np.roll(window_buf, -1)
            window_buf[-1] = pred_change

        return np.array(preds_prices), np.array(preds_changes)

    def estimate(self, df: pd.DataFrame):
        """
        Full pipeline (real-world mode):
          - Train on ALL available data
          - Forecast `horizon` future prices beyond the dataset

        Returns:
          predicted_price_series, (None for real_price_series in real-world mode)
        """
        X_train, y_train, last_close, last_window, forecast_index = self.build_training_data(df)

        self.train(X_train, y_train)

        pred_prices, pred_changes = self.forecast(last_close, last_window)

        out = pd.DataFrame(
            {
                "predicted_price": pred_prices,
                "predicted_change": pred_changes,
            },
            index=forecast_index,
        )

        # No "real_data" / no holdout comparison in real-world mode
        return out["predicted_price"], None


""" 
LINEAR REGRESSION (less accurate short-term, more accurate long term) 
"""
class LongEstimation(Estimation):

    def __init__(self, horizon: int = 90):
        """
        horizon: number of future days to forecast
        """
        self.horizon = horizon

    # PREPROCESSING
    def preprocess_data(self, data: DataFrame) -> DataFrame:
        """
        Clean and convert to Prophet's required ds/y format.
        Prophet requires columns:
            ds = datetime
            y  = target value (closing price)
        """
        df = data.copy()

        # Ensure index or Date column is proper datetime
        if "Date" in df.columns:
            df["Date"] = pd.to_datetime(df["Date"])
            df = df.rename(columns={"Date": "ds", "Close": "y"})
        else:
            df = df.rename_axis("ds").reset_index()
            df["ds"] = pd.to_datetime(df["ds"])
            df = df.rename(columns={"Close": "y"})

        # Prophet does not allow NaN in y
        df = df.dropna(subset=["y"])

        # Must be sorted
        df = df.sort_values("ds").reset_index(drop=True)

        return df

    # MAIN ESTIMATION
    def estimate(self, stock_data: DataFrame) -> DataFrame:
        """
        Runs full pipeline:
        - preprocess data
        - fit Prophet
        - predict future prices
        - merge prediction results into a returned DataFrame
        """

        # 1. Preprocess
        df = self.preprocess_data(stock_data)

        # 2. Fit Prophet model
        model = Prophet(
            daily_seasonality=True,
            weekly_seasonality=True,
            yearly_seasonality=True,
            changepoint_prior_scale=0.1
        )
        model.fit(df)

        # 3. Create future dataframe for forecasting
        future = model.make_future_dataframe(periods=self.horizon, include_history=False)

        # 4. Predict
        forecast = model.predict(future)

        # 5. Extract what matters
        predictions = forecast[["ds", "yhat", "yhat_lower", "yhat_upper"]].copy()
        predictions.index.name = "Date"

        # 6. Merge predictions back with original data
        # merged = df.merge(predictions, on="ds", how="right")
        predictions.set_index("ds", inplace=True)

        return predictions