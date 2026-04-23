from collections.abc import Callable

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.db import get_db
from app.security.models import Usuario
from app.security.tokens import decode_jwt

bearer_scheme = HTTPBearer(auto_error=False)


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> Usuario:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token de autenticacion requerido",
        )

    try:
        payload = decode_jwt(credentials.credentials)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(exc),
        ) from exc

    user_id = payload.get("user_id")
    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="JWT sin user_id",
        )

    usuario = db.scalar(
        select(Usuario)
        .options(selectinload(Usuario.roles))
        .where(Usuario.id == user_id)
    )

    if usuario is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuario autenticado no encontrado",
        )

    return usuario


def require_roles(*allowed_roles: str) -> Callable:
    allowed_role_set = {role.upper() for role in allowed_roles}

    def role_dependency(current_user: Usuario = Depends(get_current_user)) -> Usuario:
        user_roles = {role.nombre.upper() for role in current_user.roles}

        if not user_roles.intersection(allowed_role_set):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Rol no autorizado",
            )

        return current_user

    return role_dependency
