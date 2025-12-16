import warnings
from datetime import datetime
import os
import sys

import yfinance as yf
from pandas import DataFrame
import pandas as pd

from estimation.estimation import ShortEstimation, LongEstimation
from users.user_manager import UserManager

try:
    from db_manager import DatabaseManager
except ImportError:
    try:
        sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        from db_manager import DatabaseManager
    except ImportError:
        print("\n" + "="*60)
        print("ERROR: Cannot find db_manager.py")
        print("="*60)
        raise


class DataManager:
    def __init__(self, db_path='stocks1112.db'):
        self.data = None
        self.tickers = []
        self.predictions = self.create_empty_predictions_df()
        self.db = DatabaseManager(db_path)
        self.use_database = False
    
    @staticmethod
    def create_empty_predictions_df():
        """Create an empty predictions DataFrame with MultiIndex."""
        index = pd.MultiIndex(
            levels=[[], []],
            codes=[[], []],
            names=["Date", "Ticker"]
        )
        return DataFrame(index=index, columns=['predicted_price', 'predicted_change', 'yhat', 'yhat_lower', 'yhat_upper'])

    def update_preds(self, ticker, data):
        """
        Update predictions for a ticker.
        Handles both Series and DataFrame input.
        Merges new data with existing predictions instead of overwriting.
        """
        # Convert Series to DataFrame if needed
        if isinstance(data, pd.Series):
            df_temp = pd.DataFrame(data)
        else:
            df_temp = data.copy()
        
        # Add ticker column
        df_temp["Ticker"] = ticker
        df_temp = df_temp.set_index("Ticker", append=True)
        
        # Check if this ticker already has predictions
        existing_tickers = self.predictions.index.get_level_values('Ticker').unique()
        
        if ticker in existing_tickers:
            # Get existing data for this ticker
            existing_data = self.predictions.xs(ticker, level='Ticker')
            
            # Remove old data for this ticker
            self.predictions = self.predictions.drop(ticker, level='Ticker')
            
            # Merge new data with existing data (combine columns, update rows)
            # Use combine_first to keep existing values where new values are NaN
            merged = existing_data.combine_first(df_temp.droplevel('Ticker'))
            
            # Add ticker back as MultiIndex
            merged["Ticker"] = ticker
            merged = merged.set_index("Ticker", append=True)
            
            # Concatenate with predictions
            self.predictions = pd.concat([self.predictions, merged])
        else:
            # No existing data, just add it
            self.predictions = pd.concat([self.predictions, df_temp])
        
        # Sort by date
        self.predictions = self.predictions.sort_index()

    def update_data(self):
        """
        Update data for all tracked tickers.
        Tries yfinance first, falls back to database if rate limited.
        """
        if len(self.tickers) == 0:
            warnings.warn("No tickers are being tracked. Add a ticker using fetch_new_ticker()")
            return
        
        try:
            self.data = yf.Tickers(tickers=self.tickers)
            downloaded = self.data.download(period="1y", interval="1d", progress=False)
            
            if downloaded.empty:
                raise Exception("yfinance returned empty data")
            
            self.data = downloaded
            self.use_database = False
            print("✓ Successfully fetched data from yfinance")
            
        except Exception as e:
            print(f"⚠  yfinance API error: {e}")
            print("→ Falling back to local database...")
            
            if not self.db.connect():
                warnings.warn("Failed to connect to database. No data available.")
                return
            
            all_data = {}
            for ticker in self.tickers:
                ticker_data = self.db.get_ticker_data(ticker, period='1y')
                
                if not ticker_data.empty:
                    ticker_data.columns = pd.MultiIndex.from_product(
                        [ticker_data.columns, [ticker]]
                    )
                    all_data[ticker] = ticker_data
            
            if all_data:
                self.data = pd.concat(all_data.values(), axis=1)
                self.data.columns = self.data.columns.swaplevel(0, 1)
                self.use_database = True
                print(f"✓ Successfully loaded data from database for {len(all_data)} ticker(s)")
            else:
                warnings.warn("No data available from database for tracked tickers")

    def fetch_new_ticker(self, ticker: str, auto_update=True):
        """Add a new ticker to tracking list."""
        ticker = ticker.upper()
        
        if ticker in self.tickers:
            warnings.warn(f"Already tracking ticker {ticker}")
            return None
        
        ticker_valid = False
        
        try:
            ticker_info = yf.Ticker(ticker).info
            if len(ticker_info) > 1:
                ticker_valid = True
        except:
            pass
        
        if not ticker_valid:
            if self.db.ticker_exists(ticker):
                ticker_valid = True
                print(f"✓ Ticker {ticker} found in database")
        
        if not ticker_valid:
            warnings.warn(f"Ticker {ticker} not found in yfinance or database")
            return None
        
        self.tickers.append(ticker)
        
        if auto_update:
            self.update_data()
            return self.get_ticker_data(ticker)
        
        return None

    def get_ticker_data(self, ticker: str) -> DataFrame:
        """Get data for specific ticker with additional earnings info."""
        ticker = ticker.upper()
        
        if self.data is None:
            warnings.warn("No data loaded. Call update_data() first.")
            return DataFrame()
        
        try:
            if isinstance(self.data.columns, pd.MultiIndex):
                main_data = self.data[ticker]
            else:
                main_data = self.data
            
            main_data = main_data.sort_index()
            
            if 'Close' not in main_data.columns:
                warnings.warn(f"No 'Close' column found for {ticker}")
                return DataFrame()
            
            print(f"✓ Prepared ticker data for {ticker}: {len(main_data)} rows")
            
            new_data = None
            if not self.use_database:
                try:
                    new_data = yf.Ticker(ticker).get_earnings_history()
                    if not new_data.empty:
                        new_data = new_data.sort_index().reset_index().rename(columns={'index': 'quarter'})
                except:
                    pass
            
            if new_data is not None and not new_data.empty:
                main_data_reset = main_data.reset_index()
                date_col = main_data_reset.columns[0]
                
                merged = pd.merge_asof(
                    main_data_reset,
                    new_data,
                    left_on=date_col,
                    right_on='quarter',
                    direction='backward'
                )
                
                merged = merged.set_index(date_col)
                return merged.dropna(subset=['Close'])
            else:
                return main_data.dropna(subset=['Close'])
                
        except Exception as e:
            warnings.warn(f"Error getting ticker data for {ticker}: {e}")
            return DataFrame()


class Manager:
    
    def __init__(self, db_path='stocks1112.db'):
        self.data: DataManager = DataManager(db_path)
        self.short_est: ShortEstimation = ShortEstimation()
        self.long_est: LongEstimation = LongEstimation()
        self.user_manager: UserManager = UserManager()
        
        self.current_date: datetime = datetime.now()
        self.last_estimation: datetime = None
    
    def update_estimations(self, reset=False):
        """
        Update predictions for all tracked tickers.
        FIXED: Properly merges short-term and long-term predictions.
        """
        if reset:
            self.data.predictions = self.data.create_empty_predictions_df()
        
        self.data.update_data()
        
        if self.data.data is None or self.data.data.empty:
            warnings.warn("No data available to generate estimations")
            return self.data.predictions
        
        for ticker in self.data.tickers:
            try:
                ticker_data = self.data.get_ticker_data(ticker)
                
                if ticker_data.empty:
                    warnings.warn(f"No data available for {ticker}, skipping estimation")
                    continue
                
                # SHORT-TERM ESTIMATION
                pred_price, real_price = self.short_est.estimate(ticker_data)
                
                # Add short-term predictions first
                self.data.update_preds(ticker, pred_price)
                
                # Verify short-term data was added
                ticker_preds = self.data.predictions.xs(ticker, level='Ticker')
                short_count = ticker_preds['predicted_price'].notna().sum()
                
                if short_count == 0:
                    warnings.warn(f"No short-term predictions generated for {ticker}")
                
                # LONG-TERM ESTIMATION
                long_pred = self.long_est.estimate(ticker_data)
                
                # Add long-term predictions (will merge with existing)
                self.data.update_preds(ticker, long_pred)
                
                # Verify both are present
                ticker_preds = self.data.predictions.xs(ticker, level='Ticker')
                short_count = ticker_preds['predicted_price'].notna().sum()
                long_count = ticker_preds['yhat'].notna().sum()
                
                if short_count == 0:
                    warnings.warn(f"predicted_price was lost during merge for {ticker}")
                
                if long_count == 0:
                    warnings.warn(f"No long-term predictions generated for {ticker}")
                
                print(f"✓ Generated predictions for {ticker}")
                
            except Exception as e:
                warnings.warn(f"Failed to generate predictions for {ticker}: {e}")
                import traceback
                traceback.print_exc()
                continue
        
        self.last_estimation = datetime.now()
        
        if self.data.use_database:
            self.data.db.close()
        
        return self.data.predictions