from typing import Dict
from users.user import User
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
    def verify_private_key(self, name_destination: str, private_key: str):
        #Verify key with encrypted key

        if name_destination not in self.users:
            return False
        return bcrypt.checkpw(private_key.encode('utf-8'), self.users[name_destination].private_key.encode('utf-8'))

    def get_user(self, name: str):
        if name not in self.users:
            return None
        return self.users[name]