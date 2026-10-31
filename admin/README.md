# EntrenaYa · Monitoreo

Panel Next.js de administración inspirado en la estructura del monitoreo DocYa. Incluye resumen con métricas reales, búsqueda y filtros de ejercicios, editor de técnica/equipamiento/video HTTPS y editor de rutinas por categoría, nivel, días, series, repeticiones y descanso. Los contenidos se guardan como borradores o publicados en FastAPI/PostgreSQL.

## Desarrollo

```powershell
cd C:\Users\turko\Downloads\entrenaYA\admin
npm ci
npm run dev
```

Copiá `.env.example` a `.env.local` y completá las variables. `ADMIN_API_KEY` debe coincidir con el valor del backend y tener al menos 32 caracteres. `ADMIN_PASSWORD` debe tener al menos 12 caracteres y `ADMIN_SESSION_SECRET` al menos 32. La configuración local generada para este proyecto está en `.env.local`, ignorada por Git. La contraseña de ingreso corresponde a `ADMIN_PASSWORD`.

## Railway

Servicio `ENTRENAYA-MONITOREO` en el mismo proyecto que FastAPI. Root directory `/admin`, Dockerfile `Dockerfile`, health check `/login`, puerto `3000`, variables de `.env.example`. El servidor Next agrega la clave administrativa al consultar FastAPI; la clave nunca se envía al navegador. La sesión usa una cookie HttpOnly firmada, de 8 horas. Las escrituras verifican el origen y el login limita intentos por IP en la instancia.

## Flujo de publicación

### Acceso temporal

`ADMIN_DEMO_MODE=true` habilita temporalmente el panel sin contraseña, incluido el acceso a sus acciones de gestión. `/login` redirige al inicio. La clave de conexión con FastAPI permanece en el servidor. Para volver a exigir la contraseña administrativa, cambiar `ADMIN_DEMO_MODE=false` en Railway y desplegar; no hace falta cambiar la contraseña existente.

1. Crear o editar un ejercicio y su grupo muscular, equipamiento, indicaciones y URL HTTPS opcional de video.
2. Activar Publicado para que figure en la biblioteca de la app.
3. Crear una rutina, elegir categoría y nivel y asignar ejercicios, días sugeridos, series, repeticiones y descanso.
4. Publicar la rutina. La app la muestra en Entrenar → Explorar rutinas de EntrenaYa.
5. El usuario puede usar una copia y adaptarla a su semana; las copias personales existentes no se modifican al editar el catálogo.

Para retirar un ejercicio usado en una rutina publicada, primero pasar la rutina a borrador. No se eliminan registros de entrenamiento de los usuarios. Los videos se vinculan por URL de reproducción directa; todavía no hay subida de archivos desde el panel.

Pruebas: `npm run build`, `npm run typecheck`, y desde la raíz `python -m unittest discover -s tests -v` después de instalar `requirements-dev.txt`.
