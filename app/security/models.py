from datetime import datetime

from sqlalchemy import (
    DateTime,
    ForeignKey,
    Integer,
    LargeBinary,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship


class Base(DeclarativeBase):
    pass


class UsuarioRol(Base):
    __tablename__ = "actuaciones"
    __table_args__ = (
        UniqueConstraint("rol_id", "usuario_id", name="uq_actuacion"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    rol_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("roles.id", ondelete="RESTRICT"),
        nullable=False,
    )
    usuario_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("usuarios.id", ondelete="CASCADE"),
        nullable=False,
    )

    usuario: Mapped["Usuario"] = relationship(back_populates="roles_asignados")
    rol: Mapped["Rol"] = relationship(back_populates="usuarios_asignados")


class Usuario(Base):
    __tablename__ = "usuarios"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    nombre: Mapped[str] = mapped_column(Text, nullable=False)
    clave: Mapped[bytes] = mapped_column(LargeBinary, nullable=False)
    fecha_clave: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        server_default=func.current_timestamp(),
    )
    login: Mapped[str | None] = mapped_column(String(50), unique=True)
    token: Mapped[str | None] = mapped_column(String(13))

    roles_asignados: Mapped[list[UsuarioRol]] = relationship(
        back_populates="usuario",
        cascade="all, delete-orphan",
    )
    roles: Mapped[list["Rol"]] = relationship(
        secondary="actuaciones",
        back_populates="usuarios",
        viewonly=True,
    )


class Rol(Base):
    __tablename__ = "roles"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    nombre: Mapped[str] = mapped_column(Text, nullable=False, unique=True)

    usuarios_asignados: Mapped[list[UsuarioRol]] = relationship(
        back_populates="rol",
        cascade="all, delete-orphan",
    )
    usuarios: Mapped[list[Usuario]] = relationship(
        secondary="actuaciones",
        back_populates="roles",
        viewonly=True,
    )
