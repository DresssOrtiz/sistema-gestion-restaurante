from pydantic import BaseModel


class LoginRequest(BaseModel):
    login: str
    password: str


class LoginResponse(BaseModel):
    message: str
    user_id: int
    login: str
    nombre: str
    rol: str
    access_token: str
    token_type: str
    expires_at: str
