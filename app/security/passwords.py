import hashlib


def hash_password_sha256(password: str) -> bytes:
    return hashlib.sha256(password.encode("utf-8")).digest()


def verify_password_sha256(password: str, password_hash: bytes) -> bool:
    return hash_password_sha256(password) == password_hash
