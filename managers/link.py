from users.user import User

class Link:

    def __init__(self, manager_object):
        self.manager = manager_object

    # grab all estimations (for all tickers)
    def get_estimation(self):
        return self.manager.data.predictions

    # adds user (no authentication needed)
    def add_user(self, name: str, password: str, email: str = None):
        new_user = User(name, password, email)
        self.manager.user_manager.add_user(new_user)

    # updates basic information for specific user
    def update_user(self, name: str, password: str, email: str = None, new_password: str = None):
        if self.manager.user_manager.verify_private_key(name, password):
            self.manager.user_manager.update_user(name, email, new_password)

    # deletes specific user
    def delete_user(self, name, password):
        if self.manager.user_manager.verify_private_key(name, password):
            self.manager.user_manager.delete_user(name)

    def get_balance(self, name, password):
        if self.manager.user_manager.verify_private_key(name, password):
            user = self.manager.user_manager.get_user(name)
            return user.balance

        # no access or user doesn't exist
        return None

    # grabs new ticker data and updates estimations
    def update_estimations(self):
        self.manager.update_estimations()

    # adds ticker to watchlist for estimations
    def add_ticker(self, ticker: str):
        self.manager.data.fetch_new_ticker(ticker, auto_update=False)

    def buy_order(self, name, password, ticker, num_shares: float):
        if self.manager.user_manager.verify_private_key(name, password):
            price = self.manager.data.data.iloc[-1][("Close", ticker)]

            new_data = self.manager.user_manager.buy_order(name, ticker, num_shares, price)
            return new_data

        return None # User not verified or doesn't exist