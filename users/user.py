from typing import Any
import bcrypt


class User():
    #class for user on platform
    
    def __init__(self, name: str, password: str, email: str = None):
        #Init user instance
        self.name = name
        self.private_key = self.hash_private_key(password)
        self.email = email

        self.balance = float(10000) # fake starting balance of 10k
        self.positions = {}
    
    def hash_private_key(self, password: str):
        if isinstance(password, str) and password.startswith('$2b$'):
            return password
            
        # Hash the private key
        salt = bcrypt.gensalt()
        hashed = bcrypt.hashpw(password.encode('utf-8'), salt)
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
        return (self.email+self.name) == (other.email + other.name)
    
    def __hash__(self):
        #Generate hash based on id
        return hash((self.email, self.name))
