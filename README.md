# EntrenaYa API

Backend inicial de EntrenaYa con FastAPI, acceso mediante Google Identity Services y persistencia de usuarios en PostgreSQL.

## Requisitos

- Python 3.11 o superior
- PostgreSQL 14 o superior
- Un OAuth 2.0 Client ID tipo **Aplicación web** en Google Cloud Console

Agregá los orígenes locales del frontend en **Authorized JavaScript origins** de ese cliente OAuth (por ejemplo `http://localhost:5173`). El backend valida el ID token recibido y comprueba que su audiencia coincida con `GOOGLE_CLIENT_ID`.

## Preparación local

```powershell
py -3.11 -m venv .venv
.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
Copy-Item .env.example .env
```

Editá `.env`: configurá el Client ID real, la conexión local de PostgreSQL y reemplazá `JWT_SECRET_KEY` por un secreto aleatorio de al menos 32 caracteres. No compartas ni subas `.env` al repositorio.

Podés generar el secreto en PowerShell con:

```powershell
python -c "import secrets; print(secrets.token_urlsafe(48))"
```

## Iniciar

```powershell
uvicorn app.main:app --reload
```

- Health: `GET http://localhost:8000/health`
- Swagger: `http://localhost:8000/docs`
- Login Google: `POST http://localhost:8000/api/v1/auth/google`
- Perfil: `GET http://localhost:8000/api/v1/auth/me`

Al iniciar, la aplicación crea la tabla inicial `users` si todavía no existe.

### Login

El frontend obtiene un ID token de Google y lo envía al backend:

```json
{
  "id_token": "GOOGLE_ID_TOKEN"
}
```

La respuesta contiene un JWT de EntrenaYa y el perfil mínimo verificado. Para llamar a `/api/v1/auth/me`, enviá `Authorization: Bearer <access_token>`.

## Despliegue en Railway

1. Creá un servicio PostgreSQL en el proyecto de Railway.
2. Conectá el servicio de backend a la variable de PostgreSQL mediante una referencia, por ejemplo `${{Postgres.DATABASE_URL}}`.
3. Configurá en el servicio del backend `GOOGLE_CLIENT_ID`, `JWT_SECRET_KEY` y `CORS_ORIGINS`.
4. Conectá el repositorio GitHub de EntrenaYa y desplegá la rama principal. Railway detecta `Dockerfile` y `railway.json`.
5. Generá un dominio público para la API y agregalo a los orígenes autorizados del cliente OAuth de Google.

El healthcheck de Railway consulta `/health/ready`; esa ruta confirma que PostgreSQL acepta conexiones. La aplicación crea la tabla inicial `users` al arrancar.

## Alcance actual

El backend valida la identidad de Google, crea o actualiza el usuario en PostgreSQL y emite tokens firmados por EntrenaYa. Sin `GOOGLE_CLIENT_ID`, la API inicia normalmente, pero el endpoint de login devuelve `503` hasta configurar ese valor. Todavía no implementa refresh tokens, cierre de sesión ni el onboarding del prototipo.
