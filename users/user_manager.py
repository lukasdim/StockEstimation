from typing import Dict
from users.user import User


class UserManager:
    
    def __init__(self):
        self.users: Dict[str, User] = {}
    
    def add_user(self, user: User):
        if user.name in self.users:
            raise Exception(f"User with name '{user.name}' already exists")
        self.users[user.name] = user
    
    def delete_user(self, name: str):
        if name not in self.users:
            raise Exception(f"User with name '{name}' not found")
        del self.users[name]
    
    def update_user(self, name: str, **kwargs):
        if name not in self.users:
            raise Exception(f"User with name '{name}' not found")
        
        user = self.users[name]
        
        # Update allowed attributes
        if 'email' in kwargs:
            user.email = kwargs['email']
        if 'hashed_id' in kwargs:
            user.hashed_id = kwargs['hashed_id']
        if 'private_key' in kwargs:
            user.private_key = kwargs['private_key']
    
    def verify_user(self, name: str, hashed_id: str):
        if name not in self.users:
            return False
        return self.users[name].hashed_id == hashed_id
