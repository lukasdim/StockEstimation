from users.user import User
from users.owner import Owner

class Link:
    def __init__(self, manager_object):
        self.manager = manager_object

    #grab all estimations
    def get_estimation(self):
        return self.manager.data.predictions
    
    def promote_to_owner(self, name: str, password: str):
        if self.manager.user_manager.verify_private_key(name, password):
            user = self.manager.user_manager.get_user(name)
            
            if user is None:
                return False
            
            #create owner
            owner = Owner.__new__(Owner)
            owner.name = user.name
            owner.email = user.email if hasattr(user, 'email') else None
            owner.private_key = user.private_key 
            owner.balance = user.balance
            owner.positions = user.positions if hasattr(user, 'positions') else {}
            
            #directly replace in the dictionary
            self.manager.user_manager.users[name] = owner
            
            return True
        return False

    def get_all_users(self, name: str, password: str):
        """Get all users - only accessible by owners"""
        if self.manager.user_manager.verify_private_key(name, password):
            user = self.manager.user_manager.get_user(name)
            if type(user) is Owner:
                #return list of all users with their info
                all_users = []
                for username, user_obj in self.manager.user_manager.users.items():
                    all_users.append({
                        'name': username,
                        'email': user_obj.email if hasattr(user_obj, 'email') else None,
                        'balance': user_obj.balance,
                        'is_owner': type(user_obj) is Owner,
                        'positions': user_obj.positions
                    })
                return all_users
        
        return None  #not authorized or user doesn't exist

    def view_clients(self, name, password):
        if self.manager.user_manager.verify_private_key(name, password):
            owner = self.manager.user_manager.get_user(name)
            if type(owner) is Owner:
                self.manager.user.view_clients()

    #adds user (no authentication needed)
    def add_user(self, name: str, password: str, email: str = None):
        new_user = User(name, password, email)
        self.manager.user_manager.add_user(new_user)

    #updates basic information for specific user (only password now)
    def update_user(self, name: str, password: str, email: str = None, new_password: str = None):
        if not self.manager.user_manager.verify_private_key(name, password):
            raise ValueError("Invalid current password")

    #deletes specific user
    def delete_user(self, name, password):
        if not self.manager.user_manager.verify_private_key(name, password):
            raise ValueError("Invalid current password")

    def get_balance(self, name, password):
        if self.manager.user_manager.verify_private_key(name, password, True):
            user = self.manager.user_manager.get_user(name)
            return user.balance

        #no access or user doesn't exist
        return None

    def get_positions(self, name, password):
        if self.manager.user_manager.verify_private_key(name, password, True):
            user = self.manager.user_manager.get_user(name)
            return user.positions

        #no access or user doesn't exist
        return None
    
    

    #grabs new ticker data and updates estimations
    def update_estimations(self):
        self.manager.update_estimations()

    #adds ticker to watchlist for estimations
    def add_ticker(self, ticker: str):
        self.manager.data.fetch_new_ticker(ticker, auto_update=False)

    def buy_order(self, name, password, ticker, num_shares: float):
        if self.manager.user_manager.verify_private_key(name, password, True):
            price = self.manager.data.data.iloc[-1][("Close", ticker)]

            new_data = self.manager.user_manager.buy_order(name, ticker, num_shares, price)
            return new_data

        return None #user not verified or doesn't exist

    def sell_order(self, name, password, ticker, num_shares: float):
        if self.manager.user_manager.verify_private_key(name, password, True):
            price = self.manager.data.data.iloc[-1][("Close", ticker)]

            new_data = self.manager.user_manager.sell_order(name, ticker, num_shares, price)
            return new_data

        return None #user not verified or doesn't exist