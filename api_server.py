from flask import Flask, request, jsonify
from flask_cors import CORS
from managers.managers import Manager
from managers.link import Link
import warnings
import pandas as pd

app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter web/mobile

# Initialize the manager and link with database path
manager = Manager(db_path='stocks1112.db')
link = Link(manager)

# Suppress warnings for cleaner output
warnings.filterwarnings('ignore')

@app.route('/estimations', methods=['GET'])
def get_estimations():
    """
    GET /estimations
    Returns all predictions for all tickers
    Format: {ticker: {date: {predicted_price: x, yhat: y, ...}}}
    """
    try:
        predictions = link.get_estimation()
        
        # Convert DataFrame to nested dict format expected by Flutter
        result = {}
        if predictions is not None and not predictions.empty:
            # Group by ticker
            for ticker in predictions.index.get_level_values('Ticker').unique():
                ticker_data = predictions.xs(ticker, level='Ticker')
                result[ticker] = {}
                
                # Convert each row to dict
                for date, row in ticker_data.iterrows():
                    date_str = date.strftime('%Y-%m-%d') if hasattr(date, 'strftime') else str(date)
                    
                    # Build prediction dict with only non-null values
                    pred_dict = {}
                    
                    # Handle both Series and DataFrame row
                    if isinstance(row, pd.Series):
                        # Row from DataFrame
                        if 'predicted_price' in row.index and not pd.isna(row['predicted_price']):
                            pred_dict['predicted_price'] = float(row['predicted_price'])
                        
                        if 'predicted_change' in row.index and not pd.isna(row.get('predicted_change')):
                            pred_dict['predicted_change'] = float(row['predicted_change'])
                        
                        if 'yhat' in row.index and not pd.isna(row.get('yhat')):
                            pred_dict['yhat'] = float(row['yhat'])
                            
                        if 'yhat_lower' in row.index and not pd.isna(row.get('yhat_lower')):
                            pred_dict['yhat_lower'] = float(row['yhat_lower'])
                            
                        if 'yhat_upper' in row.index and not pd.isna(row.get('yhat_upper')):
                            pred_dict['yhat_upper'] = float(row['yhat_upper'])
                    else:
                        # Single value (Series case)
                        if not pd.isna(row):
                            pred_dict['predicted_price'] = float(row)
                    
                    # Only add if we have at least some data
                    if pred_dict:
                        result[ticker][date_str] = pred_dict
        
        return jsonify(result), 200
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500


@app.route('/user/add', methods=['POST'])
def add_user():
    """
    POST /user/add
    Body: {"name": str, "password": str, "email": str (optional)}
    """
    try:
        data = request.get_json()
        name = data.get('name')
        password = data.get('password')
        email = data.get('email')
        
        if not name or not password:
            return jsonify({'error': 'Name and password are required'}), 400
        
        link.add_user(name, password, email)
        return jsonify({'message': 'User added successfully', 'name': name}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/user/balance', methods=['GET'])
def get_balance():
    """
    GET /user/balance?name=username&password=password
    Note: In production, use proper authentication (JWT tokens, sessions, etc.)
    """
    try:
        name = request.args.get('name')
        password = request.args.get('password')
        
        if not name or not password:
            return jsonify({'error': 'Name and password are required'}), 400
        
        balance = link.get_balance(name, password)
        
        if balance is None:
            return jsonify({'error': 'User not found or invalid credentials'}), 404
        
        return jsonify({'balance': balance}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/user/positions', methods=['GET'])
def get_positions():
    """
    GET /user/positions?name=username&password=password
    """
    try:
        name = request.args.get('name')
        password = request.args.get('password')
        
        if not name or not password:
            return jsonify({'error': 'Name and password are required'}), 400
        
        positions = link.get_positions(name, password)
        
        if positions is None:
            return jsonify({'error': 'User not found or invalid credentials'}), 404
        
        return jsonify({'positions': positions}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/ticker/add', methods=['POST'])
def add_ticker():
    """
    POST /ticker/add
    Body: {"ticker": str}
    """
    try:
        data = request.get_json()
        ticker = data.get('ticker')
        
        if not ticker:
            return jsonify({'error': 'Ticker is required'}), 400
        
        result = link.add_ticker(ticker.upper())
        
        # Check if ticker was found
        if result is None and ticker.upper() not in manager.data.tickers:
            return jsonify({'error': f'Ticker {ticker} not found'}), 404
        
        return jsonify({
            'message': f'Ticker {ticker} added successfully',
            'using_database': manager.data.use_database
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/estimations/update', methods=['POST'])
def update_estimations():
    """
    POST /estimations/update
    Updates predictions for all tracked tickers
    Automatically uses database fallback if yfinance is rate limited
    """
    try:
        link.update_estimations()
        
        return jsonify({
            'message': 'Estimations updated successfully',
            'using_database': manager.data.use_database,
            'tickers_processed': len(manager.data.tickers)
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/order/buy', methods=['POST'])
def buy_order():
    """
    POST /order/buy
    Body: {"name": str, "password": str, "ticker": str, "num_shares": float}
    """
    try:
        data = request.get_json()
        name = data.get('name')
        password = data.get('password')
        ticker = data.get('ticker')
        num_shares = data.get('num_shares')
        
        if not all([name, password, ticker, num_shares]):
            return jsonify({'error': 'All fields are required'}), 400
        
        result = link.buy_order(name, password, ticker, float(num_shares))
        
        if result is None:
            return jsonify({'error': 'User not found or invalid credentials'}), 404
        elif isinstance(result, str):
            return jsonify({'error': result}), 400
        
        return jsonify({'message': 'Order executed', 'position': result}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/order/sell', methods=['POST'])
def sell_order():
    """
    POST /order/sell
    Body: {"name": str, "password": str, "ticker": str, "num_shares": float}
    """
    try:
        data = request.get_json()
        name = data.get('name')
        password = data.get('password')
        ticker = data.get('ticker')
        num_shares = data.get('num_shares')
        
        if not all([name, password, ticker, num_shares]):
            return jsonify({'error': 'All fields are required'}), 400
        
        result = link.sell_order(name, password, ticker, float(num_shares))
        
        if result is None:
            return jsonify({'error': 'User not found or invalid credentials'}), 404
        elif isinstance(result, str):
            return jsonify({'error': result}), 400
        
        return jsonify({'message': 'Order executed', 'result': result}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/user/update', methods=['PUT'])
def update_user():
    """
    PUT /user/update
    Body: {"name": str, "password": str, "email": str (optional), "new_password": str (optional), "new_username": str (optional)}
    """
    try:
        data = request.get_json()
        name = data.get('name')
        password = data.get('password')
        email = data.get('email')
        new_password = data.get('new_password')
        
        if not name or not password:
            return jsonify({'error': 'Name and current password are required'}), 400
        
        if not email and not new_password:
            return jsonify({'error': 'Must provide email, new_password, or new_username to update'}), 400
        
        link.update_user(name, password, email=email, new_password=new_password)
        return jsonify({'message': 'User updated successfully'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/user/delete', methods=['DELETE'])
def delete_user():
    """
    DELETE /user/delete
    Body: {"name": str, "password": str}
    """
    try:
        data = request.get_json()
        name = data.get('name')
        password = data.get('password')
        
        if not name or not password:
            return jsonify({'error': 'Name and password are required'}), 400
        
        link.delete_user(name, password)
        return jsonify({'message': 'User deleted successfully'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/status', methods=['GET'])
def get_status():
    """
    GET /status
    Returns API status and data source information
    """
    try:
        return jsonify({
            'status': 'online',
            'using_database': manager.data.use_database,
            'tracked_tickers': manager.data.tickers,
            'last_estimation': manager.last_estimation.isoformat() if manager.last_estimation else None,
            'database_path': 'stocks1112.db'
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    
@app.route('/user/promote', methods=['POST'])
def promote_to_owner():
    """
    POST /user/promote
    Body: {"name": str, "password": str}
    Promotes a user to owner status
    """
    try:
        data = request.get_json()
        name = data.get('name')
        password = data.get('password')
        
        if not name or not password:
            return jsonify({'error': 'Name and password are required'}), 400
        
        link.promote_to_owner(name, password)
        return jsonify({'message': 'User promoted to owner successfully'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/users/list', methods=['GET'])
def list_users():
    """
    GET /users/list?name=admin_name&password=admin_password
    Returns list of all users (only accessible by owners)
    """
    try:
        name = request.args.get('name')
        password = request.args.get('password')
        
        if not name or not password:
            return jsonify({'error': 'Name and password are required'}), 400
        
        # You'll need to add this method to link.py
        users = link.get_all_users(name, password)
        
        if users is None:
            return jsonify({'error': 'Unauthorized or invalid credentials'}), 403
        
        return jsonify({'users': users}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/debug/users', methods=['GET'])
def debug_users():
    """Debug endpoint to see all users"""
    try:
        users = {}
        for username, user_obj in manager.user_manager.users.items():
            users[username] = {
                'type': type(user_obj).__name__,
                'name': user_obj.name,
                'balance': user_obj.balance
            }
        return jsonify({'users': users}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    # Run on port 5001 to match your Flutter app
    print("=" * 50)
    print("Stock Prediction API Server")
    print("=" * 50)
    print(f"Database: stocks1112.db")
    print(f"Using automatic fallback: yfinance → database")
    print("=" * 50)
    app.run(host='0.0.0.0', port=5001, debug=True)