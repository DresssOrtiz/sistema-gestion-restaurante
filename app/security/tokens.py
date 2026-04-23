import base64
import hashlib
import hmac
import json
import os
from datetime import UTC, datetime, timedelta


JWT_SECRET = os.getenv("JWT_SECRET", "dev-secret-key")
JWT_ALGORITHM = "HS256"
JWT_EXPIRE_MINUTES = int(os.getenv("JWT_EXPIRE_MINUTES", "60"))


def _b64url_encode(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def _b64url_decode(data: str) -> bytes:
    padding = "=" * (-len(data) % 4)
    return base64.urlsafe_b64decode(data + padding)


def generate_jwt(user_id: int, rol: str, expires_delta: timedelta | None = None) -> tuple[str, datetime]:
    now = datetime.now(UTC)
    expire_at = now + (expires_delta or timedelta(minutes=JWT_EXPIRE_MINUTES))

    header = {
        "alg": JWT_ALGORITHM,
        "typ": "JWT",
    }
    payload = {
        "user_id": user_id,
        "rol": rol,
        "exp": int(expire_at.timestamp()),
    }

    header_segment = _b64url_encode(
        json.dumps(header, separators=(",", ":"), sort_keys=True).encode("utf-8")
    )
    payload_segment = _b64url_encode(
        json.dumps(payload, separators=(",", ":"), sort_keys=True).encode("utf-8")
    )
    signing_input = f"{header_segment}.{payload_segment}".encode("ascii")
    signature = hmac.new(
        JWT_SECRET.encode("utf-8"),
        signing_input,
        hashlib.sha256,
    ).digest()
    signature_segment = _b64url_encode(signature)

    return f"{header_segment}.{payload_segment}.{signature_segment}", expire_at


def decode_jwt(token: str) -> dict:
    try:
        header_segment, payload_segment, signature_segment = token.split(".")
    except ValueError as exc:
        raise ValueError("Token invalido") from exc

    signing_input = f"{header_segment}.{payload_segment}".encode("ascii")
    expected_signature = hmac.new(
        JWT_SECRET.encode("utf-8"),
        signing_input,
        hashlib.sha256,
    ).digest()
    provided_signature = _b64url_decode(signature_segment)

    if not hmac.compare_digest(expected_signature, provided_signature):
        raise ValueError("Firma JWT invalida")

    header = json.loads(_b64url_decode(header_segment))
    if header.get("alg") != JWT_ALGORITHM:
        raise ValueError("Algoritmo JWT invalido")

    payload = json.loads(_b64url_decode(payload_segment))
    exp = payload.get("exp")

    if exp is None:
        raise ValueError("JWT sin expiracion")

    if datetime.now(UTC).timestamp() >= exp:
        raise ValueError("JWT expirado")

    return payload
