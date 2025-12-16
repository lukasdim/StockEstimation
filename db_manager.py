import sqlite3
import pandas as pd
from datetime import datetime, timedelta
import warnings

class DatabaseManager:
    """
    Manages SQLite database operations for stock data.
    Used as fallback when yfinance API is rate-limited.
    """
    
    def __init__(self, db_path='stocks1112.db'):
        self.db_path = db_path
        self.conn = None
    
    def connect(self):
        """Establish database connection."""
        try:
            self.conn = sqlite3.connect(self.db_path)
            return True
        except sqlite3.Error as e:
            warnings.warn(f"Database connection failed: {e}")
            return False
    
    def close(self):
        """Close database connection."""
        if self.conn:
            self.conn.close()
            self.conn = None
    
    def get_ticker_data(self, ticker: str, period='1y') -> pd.DataFrame:
        """
        Fetch historical price data for a ticker from database.
        
        Args:
            ticker: Stock symbol
            period: Time period (e.g., '1y', '6mo', '3mo')
        
        Returns:
            DataFrame with Date index and OHLCV columns
        """
        if not self.conn:
            if not self.connect():
                return pd.DataFrame()
        
        # Calculate date range based on period
        end_date = datetime.now()
        if period == '1y':
            start_date = end_date - timedelta(days=365)
        elif period == '6mo':
            start_date = end_date - timedelta(days=180)
        elif period == '3mo':
            start_date = end_date - timedelta(days=90)
        elif period == '1mo':
            start_date = end_date - timedelta(days=30)
        else:
            start_date = end_date - timedelta(days=365)
        
        # Query combining price and volume data
        query = """
        SELECT 
            p.date,
            p.open,
            p.high,
            p.low,
            p.close,
            p.adjusted_close,
            v.volume
        FROM daily_prices p
        LEFT JOIN volume_data v ON p.symbol = v.symbol AND p.date = v.date
        WHERE p.symbol = ?
        AND p.date >= ?
        AND p.date <= ?
        ORDER BY p.date ASC
        """
        
        try:
            df = pd.read_sql_query(
                query,
                self.conn,
                params=(ticker.upper(), start_date.strftime('%Y-%m-%d'), end_date.strftime('%Y-%m-%d'))
            )
            
            if df.empty:
                warnings.warn(f"No data found in database for ticker {ticker}")
                return df
            
            print(f"✓ Loaded {len(df)} rows from database for {ticker}")
            print(f"  Date range: {df['date'].min()} to {df['date'].max()}")
            
            # Convert date to datetime and set as index
            df['date'] = pd.to_datetime(df['date'])
            df = df.set_index('date')
            
            # Rename columns to match yfinance format (capitalized)
            df.columns = ['Open', 'High', 'Low', 'Close', 'Adj Close', 'Volume']
            
            # Ensure numeric types
            for col in df.columns:
                df[col] = pd.to_numeric(df[col], errors='coerce')
            
            return df
            
        except sqlite3.Error as e:
            warnings.warn(f"Database query failed for {ticker}: {e}")
            print(f"Error details: {e}")
            return pd.DataFrame()
    
    def get_volume_data(self, ticker: str, period='1y') -> pd.DataFrame:
        """Fetch volume data for a ticker."""
        if not self.conn:
            if not self.connect():
                return pd.DataFrame()
        
        end_date = datetime.now()
        if period == '1y':
            start_date = end_date - timedelta(days=365)
        else:
            start_date = end_date - timedelta(days=365)
        
        query = """
        SELECT date, volume
        FROM volume_data
        WHERE symbol = ?
        AND date >= ?
        AND date <= ?
        ORDER BY date ASC
        """
        
        try:
            df = pd.read_sql_query(
                query,
                self.conn,
                params=(ticker.upper(), start_date.strftime('%Y-%m-%d'), end_date.strftime('%Y-%m-%d'))
            )
            
            if not df.empty:
                df['date'] = pd.to_datetime(df['date'])
                df = df.set_index('date')
            
            return df
            
        except sqlite3.Error as e:
            warnings.warn(f"Volume query failed for {ticker}: {e}")
            return pd.DataFrame()
    
    def get_fundamentals(self, ticker: str) -> dict:
        """Fetch fundamental data for a ticker."""
        if not self.conn:
            if not self.connect():
                return {}
        
        query = """
        SELECT 
            earnings_per_share,
            pe_ratio,
            dividend_yield,
            book_value
        FROM fundamentals
        WHERE symbol = ?
        ORDER BY date DESC
        LIMIT 1
        """
        
        try:
            cursor = self.conn.cursor()
            cursor.execute(query, (ticker.upper(),))
            row = cursor.fetchone()
            
            if row:
                return {
                    'eps': row[0],
                    'pe_ratio': row[1],
                    'dividend_yield': row[2],
                    'book_value': row[3]
                }
            return {}
            
        except sqlite3.Error as e:
            warnings.warn(f"Fundamentals query failed for {ticker}: {e}")
            return {}
    
    def ticker_exists(self, ticker: str) -> bool:
        """Check if ticker exists in database."""
        if not self.conn:
            if not self.connect():
                return False
        
        query = "SELECT COUNT(*) FROM stocks WHERE symbol = ?"
        
        try:
            cursor = self.conn.cursor()
            cursor.execute(query, (ticker.upper(),))
            count = cursor.fetchone()[0]
            return count > 0
            
        except sqlite3.Error as e:
            warnings.warn(f"Ticker existence check failed: {e}")
            return False
    
    def get_all_tickers(self) -> list:
        """Get list of all available tickers in database."""
        if not self.conn:
            if not self.connect():
                return []
        
        query = "SELECT symbol FROM stocks ORDER BY symbol"
        
        try:
            cursor = self.conn.cursor()
            cursor.execute(query)
            return [row[0] for row in cursor.fetchall()]
            
        except sqlite3.Error as e:
            warnings.warn(f"Failed to fetch ticker list: {e}")
            return []