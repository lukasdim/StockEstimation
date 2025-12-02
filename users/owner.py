from users.user import User


class Owner(User):
    #Class for owner/admin
    
    def __init__(self, name: str, hashed_id: str, private_key: str):
        #Init owner instance
        super().__init__(name, hashed_id, private_key)
