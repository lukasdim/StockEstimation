from typing import Any
import bcrypt


class User():
    #class for user on platform
    
    def __init__(self, name: str, password: str, email: str = None):
        #Init user instance
        self.name = name
        self.private_key = self._hash_private_key(password)
        self.email = email
    
    def _hash_private_key(self, private_key: str):
        if isinstance(private_key, str) and private_key.startswith('$2b$'):
            return private_key
            
        # Hash the private key
        salt = bcrypt.gensalt()
        hashed = bcrypt.hashpw(private_key.encode('utf-8'), salt)
        return hashed.decode('utf-8')
    
    def verify_private_key(self, private_key: str):
        try:
            return bcrypt.checkpw(private_key.encode('utf-8'), self.private_key.encode('utf-8'))
        except Exception:
            return False
    
    def __eq__(self, other: Any):
        #hashed_id verification
        if not isinstance(other, User):
            return False
        return self.hashed_id == other.hashed_id
    
    def __hash__(self):
        #Generate hash based on id
        return hash(self.hashed_id)
