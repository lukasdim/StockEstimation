from users.user import User

class Link:

    def __init__(self, manager_object):
        self.manager = manager_object

    def get_estimation(self):
        return self.manager.data.predictions

    def add_user(self, name: str, password: str, email: str = None):
        new_user = User(name, password, email)
        self.manager.user_manager.add_user(new_user)

    def update_user(self, name: str, email: str = None, password: str = None):
        user = self.manager.user_manager.get_user(name)
        if self.manager.user_manager.verify_private_key(user.private_key):
            self.manager.user_manager.update_user(name, email, password)

    def delete_user(self, name):
        user = self.manager.user_manager.get_user(name)
        if self.manager.user_manager.verify_private_key(user.private_key):
            self.manager.user_manager.delete_user()

    def check_balance(self, name):
        user = self.manager.user_manager.get_user(name)
        if self.manager.user_manager.verify_private_key(user.private_key):
            return user.balance

        # no access or user doesn't exist
        return None

    def reset_estimations(self):
        self.manager.data.predictions.reset_estimations()