import warnings
import yfinance as yf
from pandas import DataFrame


# Docs for return values:
# https://ranaroussi.github.io/yfinance/reference/api/yfinance.Ticker.html#yfinance.Ticker

class DataManager:
    def __init__(self):
        self.data = None
        self.tickers = []

    def update_data(self):
        if len(self.tickers) == 0:
            warnings.warn("No tickers are being tracked. Add a ticker using fetch_new_ticker()")
        else:
            self.data = yf.Tickers(tickers=self.tickers).download() # might want to increase more than 1m

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

    # return data for only specific ticker
    def get_ticker_data(self, ticker: str) -> DataFrame:
        return self.data.xs(ticker.upper(), axis=1, level=1)