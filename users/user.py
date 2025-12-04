from typing import Any


class User():
    #class for user on platform
    
    def __init__(self, name: str, hashed_id: str, private_key: str):
        #Init user instance
        self.name = name
        self.hashed_id = hashed_id
        self.private_key = private_key
    
    def __eq__(self, other: Any):
        #hashed_id verification
        if not isinstance(other, User):
            return False
        return self.hashed_id == other.hashed_id
    
    def __hash__(self):
        #Generate hash based on id
        return hash(self.hashed_id)
