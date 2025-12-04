from typing import Dict
from users.user import User


class UserManager:
    """UserManager class for managing user operations"""
    
    def __init__(self):
        """Initialize UserManager with an empty users dictionary"""
        self.users: Dict[str, User] = {}
    
    def add_user(self, user: User) -> None:
        """
        Add a user to the manager
        
        Args:
            user: User instance to add
        
        Raises:
            Exception: If user with the same name already exists
        """
        if user.name in self.users:
            raise Exception(f"User with name '{user.name}' already exists")
        self.users[user.name] = user
    
    def delete_user(self, name: str) -> None:
        """
        Delete a user from the manager
        
        Args:
            name: Name of the user to delete
        
        Raises:
            Exception: If user not found
        """
        if name not in self.users:
            raise Exception(f"User with name '{name}' not found")
        del self.users[name]
    
    def update_user(self, name: str, **kwargs) -> None:
        """
        Update user attributes
        
        Args:
            name: Name of the user to update
            **kwargs: Attributes to update (email, hashed_id, private_key)
        
        Raises:
            Exception: If user not found
        """
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
    
    def verify_user(self, name: str, hashed_id: str) -> bool:
        """
        Verify a user by name and hashed_id
        
        Args:
            name: Name of the user
            hashed_id: Hashed ID to verify
        
        Returns:
            True if user exists and hashed_id matches, False otherwise
        """
        if name not in self.users:
            return False
        return self.users[name].hashed_id == hashed_id
