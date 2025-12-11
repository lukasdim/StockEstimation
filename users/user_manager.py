from typing import Dict
from users.user import User


class UserManager:
    
    def __init__(self):
        self.users: Dict[str, User] = {}

    def add_user(self, user: User):
        if user.name in self.users:
            raise Exception("User with name " + user.name + " already exists")
        self.users[user.name] = user

    def delete_user(self, name: str):
        if name not in self.users:
            raise Exception("User with name " + name + "not found")
        del self.users[name]

    def update_user(self, name: str, email: str = None, hashed_id: str = None, private_key: str = None):
        if name not in self.users:
            raise Exception("User with name " + name + "not found")
        
        user = self.users[name]

        # Update allowed attributes
        if email is not None:
            user.email = email
        if hashed_id is not None:
            user.hashed_id = hashed_id
        if private_key is not None:
            user.private_key = user._hash_private_key(private_key)

    def verify_user(self, name: str, hashed_id: str):
        if name not in self.users:
            return False
        return self.users[name].hashed_id == hashed_id
    
    def verify_private_key(self, name: str, private_key: str):
        #Verify key with encrypted key
        if name not in self.users:
            return False
        return self.users[name].verify_private_key(private_key)
