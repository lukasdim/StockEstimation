from typing import Dict
from users.user import User
from datetime import datetime
import bcrypt
import warnings

class UserManager:
    
    def __init__(self):
        self.users: Dict[str, User] = {}

    def add_user(self, user: User):
        if user.name in self.users:
            warnings.warn("User with name " + user.name + " already exists")
        self.users[user.name] = user

    def delete_user(self, name: str):
        if name not in self.users:
           warnings.warn("User with name " + name + "not found")
        del self.users[name]

    def update_user(self, name: str, email: str = None, password: str = None):
        if name not in self.users:
            warnings.warn("User with name " + name + "not found")
        
        user = self.users[name]

        # Update allowed attributes
        if email is not None:
            user.email = email
        if password is not None:
            user.private_key = user.hash_private_key(password)

    # first is name of destination user class. second is private key of requester
    def verify_private_key(self, name: str, password: str):
        #Verify key with encrypted key

        if name not in self.users:
            return False
        return bcrypt.checkpw(password.encode('utf-8'), self.users[name].private_key.encode('utf-8'))

    def get_user(self, name: str):
        if name not in self.users:
            warnings.warn("User with name " + name + "not found")
            return None
        return self.users[name]

    #
    def buy_order(self, name, ticker, num_shares: float, price: float):
        buy_date = datetime.now() # Reduces delay of computation time by being at top
        if name not in self.users:
            warnings.warn("User with name " + name + "not found")
            return None

        user_obj = self.users[name]
        total = num_shares * price

        if total <= user_obj.balance:
            # create temp vars in case user already has position (less code)
            new_shares = num_shares
            new_total = total
            new_price = price
            if ticker in user_obj.positions:
                new_shares = user_obj.positions[ticker]['buy_amount'] + num_shares
                new_total = total + user_obj.positions[ticker]['total_price']
                new_price = new_total / new_shares # Average by using total spent / total num_shares

            user_obj.positions[ticker] = {
                'buy_date': buy_date.isoformat(),
                'buy_amount': float(new_shares),
                'stock_price': float(new_price),
                'total_price': float(new_total),
            }

            user_obj.balance -= total

            return user_obj.positions[ticker]

        return "Total price is greater than your balance." # User doesn't have enough money.