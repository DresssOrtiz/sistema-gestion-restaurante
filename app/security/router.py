from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.db import get_db
from app.security.dependencies import get_current_user, require_roles
from app.security.models import Usuario
from app.security.passwords import verify_password_sha256
from app.security.schemas import LoginRequest, LoginResponse
from app.security.tokens import generate_jwt

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/login", response_model=LoginResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)) -> LoginResponse:
    usuario = db.scalar(
        select(Usuario)
        .options(selectinload(Usuario.roles))
        .where(Usuario.login == payload.login)
    )

    if usuario is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Credenciales invalidas",
        )

    if not verify_password_sha256(payload.password, usuario.clave):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Credenciales invalidas",
        )

    rol = usuario.roles[0].nombre if usuario.roles else "SIN_ROL"
    access_token, expires_at = generate_jwt(usuario.id, rol)

    return LoginResponse(
        message="Login correcto",
        user_id=usuario.id,
        login=usuario.login or "",
        nombre=usuario.nombre,
        rol=rol,
        access_token=access_token,
        token_type="bearer",
        expires_at=expires_at.isoformat(),
    )


@router.get("/me")
def auth_me(current_user: Usuario = Depends(get_current_user)) -> dict:
    return {
        "message": "Usuario autenticado",
        "user_id": current_user.id,
        "login": current_user.login,
        "nombre": current_user.nombre,
        "roles": [role.nombre for role in current_user.roles],
    }


@router.get("/demo/admin")
def auth_demo_admin(
    current_user: Usuario = Depends(require_roles("ADMINISTRADOR")),
) -> dict:
    return {
        "message": "Acceso autorizado para ADMINISTRADOR",
        "user_id": current_user.id,
        "login": current_user.login,
        "roles": [role.nombre for role in current_user.roles],
    }


@router.get("/demo/mesero")
def auth_demo_mesero(
    current_user: Usuario = Depends(require_roles("MESERO")),
) -> dict:
    return {
        "message": "Acceso autorizado para MESERO",
        "user_id": current_user.id,
        "login": current_user.login,
        "roles": [role.nombre for role in current_user.roles],
    }
