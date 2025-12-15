from users.user import User


class Owner(User):
    #Class for owner/admin
    
    def __init__(self, name: str, password: str, email: str = None):
        #Init owner instance
        super().__init__(name, password, email)

    @classmethod
    def from_user(cls, user: User):
        owner = cls(user.name, user.private_key, user.email)  # private_key is already hashed
        owner.balance = user.balance
        owner.positions = user.positions
        return owner