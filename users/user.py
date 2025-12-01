from abc import ABC
from typing import Any


class User(ABC):
    """
    Abstract base class representing a user in the Stock Analysis Platform.
    
    Attributes:
        name: User's name
        hashed_id: Hashed identifier for the user
        private_key: Private key for authentication
    """
    
    def __init__(self, name: str, hashed_id: str, private_key: str):
        """
        Initialize a User instance.
        
        Args:
            name: User's name
            hashed_id: Hashed identifier for the user
            private_key: Private key for authentication
        """
        self.name = name
        self.hashed_id = hashed_id
        self.private_key = private_key
    
    def __eq__(self, other: Any) -> bool:
        """
        Check equality based on hashed_id.
        
        Args:
            other: Another object to compare with
            
        Returns:
            True if both users have the same hashed_id, False otherwise
        """
        if not isinstance(other, User):
            return False
        return self.hashed_id == other.hashed_id
    
    def __hash__(self) -> int:
        """
        Generate hash based on hashed_id.
        
        Returns:
            Hash value of the hashed_id
        """
        return hash(self.hashed_id)
