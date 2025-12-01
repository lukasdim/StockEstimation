from users.user import User


class Owner(User):
    """
    Owner class representing an owner/administrator user.
    
    Inherits all attributes and methods from User base class.
    """
    
    def __init__(self, name: str, hashed_id: str, private_key: str):
        """
        Initialize an Owner instance.
        
        Args:
            name: Owner's name
            hashed_id: Hashed identifier for the owner
            private_key: Private key for authentication
        """
        super().__init__(name, hashed_id, private_key)
