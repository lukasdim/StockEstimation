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
        user = self.manager.user_manager.get_user(name)  # needed for hash_private_key method
        if self.manager.user_manager.verify_private_key(name, user.hash_private_key(password)):
            self.manager.user_manager.update_user(name, email, new_password)

    # deletes specific user
    def delete_user(self, name, password):
        user = self.manager.user_manager.get_user(name) #needed for hash_private_key method
        if self.manager.user_manager.verify_private_key(name, user.hash_private_key(password)):
            self.manager.user_manager.delete_user()

    def get_balance(self, name):
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