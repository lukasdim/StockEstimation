from users.user import User

class Link:

    def __init__(self, manager_object):
        self.manager = manager_object

    def get_estimation(self):
        return self.manager.data.predictions

    def add_user(self):
        new_user = User()
        self.manager.user_manager.add_user(self)

    def update_user(self):
        pass

    def delete_user(self):
        pass

    def check_balance(self):
        pass

    def reset_estimations(self):
        pass