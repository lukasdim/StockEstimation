from typing import Dict
from users.user import User


class Client(User):
    """
    Client class representing a client user with trading capabilities.
    
    Attributes:
        balance: Client's account balance
        positions_dict: Dictionary of client's stock positions
    """
    
    def __init__(self, name: str, hashed_id: str, private_key: str, 
                 balance: float = 0.0, positions_dict: Dict[str, float] = None):
        """
        Initialize a Client instance.
        
        Args:
            name: Client's name
            hashed_id: Hashed identifier for the client
            private_key: Private key for authentication
            balance: Initial account balance (default: 0.0)
            positions_dict: Dictionary of stock positions (default: empty dict)
        """
        super().__init__(name, hashed_id, private_key)
        self.balance = balance
        self.positions_dict = positions_dict if positions_dict is not None else {}
