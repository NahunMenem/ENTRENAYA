import base64
import hashlib
import io
import warnings
import time
import re
from uuid import uuid4
from urllib.parse import urlparse
import requests

from fastapi import HTTPException
from PIL import Image, ImageOps, UnidentifiedImageError
from app.core.config import get_settings


def process_cover(data_url: str) -> tuple[bytes, str]:
    try:
        prefix, payload = data_url.split(",", 1)
        if prefix not in ("data:image/jpeg;base64", "data:image/png;base64", "data:image/webp;base64"):
            raise ValueError("Formato no admitido")
        raw = base64.b64decode(payload, validate=True)
        if len(raw) > 4 * 1024 * 1024:
            raise ValueError("La imagen supera 4 MB")
        with warnings.catch_warnings():
            warnings.simplefilter("error", Image.DecompressionBombWarning)
            with Image.open(io.BytesIO(raw)) as image:
                if image.format not in ("JPEG", "PNG", "WEBP") or image.width * image.height > 20_000_000:
                    raise ValueError("Imagen demasiado grande o formato no admitido")
                image = ImageOps.exif_transpose(image).convert("RGB")
                image.thumbnail((1600, 1600))
                output = io.BytesIO()
                image.save(output, format="WEBP", quality=85)
        content = output.getvalue()
        return content, hashlib.sha256(content).hexdigest()
    except (ValueError, OSError, UnidentifiedImageError, Image.DecompressionBombError, Image.DecompressionBombWarning) as error:
        raise HTTPException(422, "Usá una foto JPG, PNG o WebP de hasta 4 MB y 20 megapíxeles.") from error


def upload_cover(content: bytes, exercise_id: str) -> tuple[str, str]:
    settings = get_settings()
    cloud = settings.cloudinary_cloud_name
    if not re.fullmatch(r"[a-z0-9-]+", cloud) or not settings.cloudinary_api_key or not settings.cloudinary_api_secret:
        raise HTTPException(503, "Falta configurar Cloudinary en el servidor para subir fotos.")
    parameters = {"public_id": f"entrenaya/exercises/{exercise_id}/{uuid4().hex}", "timestamp": str(int(time.time()))}
    signature_text = "&".join(f"{key}={value}" for key, value in sorted(parameters.items()))
    signature = hashlib.sha256((signature_text + settings.cloudinary_api_secret.get_secret_value()).encode()).hexdigest()
    try:
        response = requests.post(f"https://api.cloudinary.com/v1_1/{cloud}/image/upload",
            data={**parameters, "api_key": settings.cloudinary_api_key, "signature": signature},
            files={"file": ("cover.webp", content, "image/webp")}, timeout=(10, 30))
        if response.status_code == 403:
            raise HTTPException(503, "La clave de Cloudinary no tiene permiso para subir fotos. Habilitá el permiso de creación/subida para esa clave.")
        response.raise_for_status()
        result = response.json()
        url, public_id = result["secure_url"], result["public_id"]
        parsed = urlparse(url)
        if parsed.scheme != "https" or parsed.hostname != "res.cloudinary.com" or not parsed.path.startswith(f"/{cloud}/"):
            raise ValueError("Unexpected delivery URL")
        return url, public_id
    except (requests.RequestException, ValueError, KeyError) as error:
        raise HTTPException(502, "No pudimos subir la foto a Cloudinary. Revisá la configuración y reintentá.") from error
