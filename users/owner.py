from users.user import User


class Owner(User):
    #Class for owner/admin
    
    def __init__(self, name: str, password: str, email: str = None):
        #Init owner instance
        super().__init__(name, password, email)
