import warnings
from datetime import datetime

import yfinance as yf
from pandas import DataFrame
import pandas as pd

from estimation.estimation import ShortEstimation, LongEstimation
from users.user_manager import UserManager


# Docs for return values:
# https://ranaroussi.github.io/yfinance/reference/api/yfinance.Ticker.html#yfinance.Ticker

class DataManager:
    def __init__(self):
        self.data = None
        self.tickers = []
        self.predictions = self.create_empty_predictions_df()
    
    @staticmethod
    def create_empty_predictions_df():
        """Create an empty predictions DataFrame with MultiIndex."""
        index = pd.MultiIndex(
            levels=[[], []],
            codes=[[], []],
            names=["Date", "Ticker"]
        )
        return DataFrame(index=index, columns=['predicted_price', 'yhat', 'yhat_lower', 'yhat_upper'])

    def update_preds(self, ticker, data: pd.Series):
        df_temp = pd.DataFrame(data, index=data.index)
        df_temp["Ticker"] = ticker
        df_temp = df_temp.set_index("Ticker", append=True)
        self.predictions = pd.concat([self.predictions, df_temp])

    def update_data(self):
        if len(self.tickers) == 0:
            warnings.warn("No tickers are being tracked. Add a ticker using fetch_new_ticker()")
        else:
            self.data = yf.Tickers(tickers=self.tickers)
            self.data = self.data.download(period="1y", interval="1d") # might want to increase more than 1m

    def fetch_new_ticker(self, ticker: str, auto_update=True):
        ticker = ticker.upper()
        ticker_info = yf.Ticker(ticker).info

        if len(ticker_info) <= 1:
            warnings.warn(f"No ticker found for {ticker}.")
            return None
        elif ticker not in self.tickers:
            self.tickers.append(ticker)
        else:
            warnings.warn(f"Already fetched ticker {ticker}, aborting.")
            return None

        # auto_update obtains new values for each stock...
        # maybe change that later by adding optional parameter to update only specific ticker(s)
        if auto_update:
            self.update_data()
            return self.get_ticker_data(ticker)

        return None # if auto_update is false

    # return data for only specific ticker, as well as add extra information
    def get_ticker_data(self, ticker: str) -> DataFrame:
        new_data = yf.Ticker(ticker).get_earnings_history()
        main_data = self.data.xs(ticker.upper(), axis=1, level=1)
        main_data = main_data.sort_index()
        new_data = new_data.sort_index().reset_index().rename(columns={'index': 'quarter'})

        # merge_asof: match each date with the most recent quarter date
        merged = pd.merge_asof(
            main_data.reset_index().rename(columns={'index': 'Date'}),
            new_data,
            left_on='Date',
            right_on='quarter',
            direction='backward'  # important: use the last known quarter
        )

        # Set index back
        merged = merged.set_index('Date')

        return merged.dropna()


class Manager:
    
    def __init__(self):
        # UML diagram componentd
        self.data: DataManager = DataManager()
        self.short_est: ShortEstimation = ShortEstimation()
        self.long_est: LongEstimation = LongEstimation()
        self.user_manager: UserManager = UserManager()
        
        # DateTime
        self.current_date: datetime = datetime.now()
        self.last_estimation: datetime = None
    
    def update_estimations(self, reset=False):
        if reset:
            # Clears previous predictions
            self.data.predictions = self.data.create_empty_predictions_df()
        
        # Updates data for every ticker
        self.data.update_data()
        
        # Run estimations for each ticker
        for ticker in self.data.tickers:
            ticker_data = self.data.get_ticker_data(ticker)
            
            # Short-term estimation
            pred_price, real_price = self.short_est.estimate(ticker_data)
            self.data.update_preds(ticker, pred_price)
        
        # Update last estimation
        self.last_estimation = datetime.now()
        
        return self.data.predictions