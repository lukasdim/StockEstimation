from typing import Dict
from users.user import User


class Client(User):
    #CLient class for user with trading ability
    
    def __init__(self, name: str, hashed_id: str, private_key: str, 
                 balance: float = 0.0, positions_dict: Dict[str, float] = None):
       #Init Client instance
    
        super().__init__(name, hashed_id, private_key)
        self.balance = balance
        self.positions_dict = positions_dict if positions_dict is not None else {}
