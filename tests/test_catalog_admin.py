import os
import unittest

os.environ.setdefault("DATABASE_URL", "postgresql+asyncpg://test:test@localhost/test")
os.environ.setdefault("JWT_SECRET_KEY", "catalog-tests-only-secret-000000000000000000")
os.environ["ADMIN_API_KEY"] = "catalog-tests-admin-key-0000000000000000000"

import httpx
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.main import app
from app.db.base import Base
from app.db.session import get_db


class CatalogTests(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        self.engine = create_async_engine("sqlite+aiosqlite:///:memory:")
        async with self.engine.begin() as connection:
            await connection.run_sync(Base.metadata.create_all)
        self.sessions = async_sessionmaker(self.engine, expire_on_commit=False)
        async def database():
            async with self.sessions() as db:
                yield db
        app.dependency_overrides[get_db] = database
        self.client = httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url="http://test")
        self.headers = {"X-Admin-Key": os.environ["ADMIN_API_KEY"]}

    async def asyncTearDown(self):
        app.dependency_overrides.clear()
        await self.client.aclose()
        await self.engine.dispose()

    async def test_publication_permissions_and_template_lifecycle(self):
        self.assertEqual((await self.client.get("/api/v1/admin/exercises")).status_code, 401)
        body = dict(name="Sentadilla de prueba", muscle_group="Piernas", instructions="Descenso controlado.", published=False)
        response = await self.client.post("/api/v1/admin/exercises", json=body, headers=self.headers)
        self.assertEqual(response.status_code, 201, response.text)
        exercise_id = response.json()["id"]
        self.assertEqual((await self.client.get("/api/v1/exercises")).json(), [])
        template = dict(name="Hipertrofia inicial", category="Hipertrofia", level="Principiante", days=[1, 4],
            exercises=[dict(id=exercise_id, sets=3, reps=12, rest_seconds=90)], published=True)
        self.assertEqual((await self.client.post("/api/v1/admin/routines", json=template, headers=self.headers)).status_code, 422)
        body["published"] = True
        body["video_url"] = "https://cdn.example.com/sentadilla.mp4"
        response = await self.client.put(f"/api/v1/admin/exercises/{exercise_id}", json=body, headers=self.headers)
        self.assertEqual(response.status_code, 200, response.text)
        public = (await self.client.get("/api/v1/exercises")).json()
        self.assertEqual(public[0]["muscle_group"], "Piernas")
        response = await self.client.post("/api/v1/admin/routines", json=template, headers=self.headers)
        self.assertEqual(response.status_code, 201, response.text)
        routine_id = response.json()["id"]
        shared = await self.client.get(f'/api/v1/routines/{routine_id}')
        self.assertEqual(shared.status_code, 200)
        self.assertEqual(shared.json()['name'], template['name'])
        public = (await self.client.get("/api/v1/routines")).json()
        self.assertEqual(public[0]["exercises"][0]["name"], body["name"])
        body["published"] = False
        self.assertEqual((await self.client.put(f"/api/v1/admin/exercises/{exercise_id}", json=body, headers=self.headers)).status_code, 409)
        template["published"] = False
        self.assertEqual((await self.client.put(f"/api/v1/admin/routines/{routine_id}", json=template, headers=self.headers)).status_code, 200)
        self.assertEqual((await self.client.get("/api/v1/routines")).json(), [])
        self.assertEqual((await self.client.get(f'/api/v1/routines/{routine_id}')).status_code, 404)
        self.assertEqual((await self.client.put(f"/api/v1/admin/exercises/{exercise_id}", json=body, headers=self.headers)).status_code, 200)
        self.assertEqual((await self.client.get("/api/v1/exercises")).json(), [])
        self.assertEqual(len((await self.client.get("/api/v1/admin/exercises", headers=self.headers)).json()), 1)

    async def test_validation(self):
        preflight = await self.client.options('/api/v1/routines', headers={
            'Origin': 'http://localhost:64011', 'Access-Control-Request-Method': 'GET',
        })
        self.assertEqual(preflight.status_code, 200)
        self.assertEqual(preflight.headers.get('access-control-allow-origin'), 'http://localhost:64011')
        body = dict(name="Press", muscle_group="Pecho", video_url="http://example.com/video.mp4")
        self.assertEqual((await self.client.post("/api/v1/admin/exercises", json=body, headers=self.headers)).status_code, 422)
        template = dict(name="Test", category="Volumen", level="Principiante", days=[1, 1],
            exercises=[dict(id="unknown", sets=0, reps=12, rest_seconds=90)])
        self.assertEqual((await self.client.post("/api/v1/admin/routines", json=template, headers=self.headers)).status_code, 422)

    async def test_exercise_cover_upload_replace_remove_and_permissions(self):
        import base64
        import hashlib
        import io
        from unittest.mock import patch
        from PIL import Image
        def image(color):
            output = io.BytesIO()
            Image.new("RGB", (32, 24), color).save(output, format="PNG")
            return "data:image/png;base64," + base64.b64encode(output.getvalue()).decode()
        uploaded = []
        def fake_upload(content, exercise_id):
            with Image.open(io.BytesIO(content)) as photo:
                self.assertEqual(photo.format, 'WEBP')
                self.assertEqual(photo.size, (32, 24))
            digest = hashlib.sha256(content).hexdigest()
            url = f'https://res.cloudinary.com/test/image/upload/{digest}.webp'
            uploaded.append(url)
            return url, f'entrenaya/exercises/{exercise_id}/{digest}'
        with patch('app.api.v1.catalog_admin.upload_cover', side_effect=fake_upload) as upload:
            body = dict(name="Ejercicio con portada", muscle_group="Pecho", published=True, cover_image=image("red"))
            response = await self.client.post('/api/v1/admin/exercises', json=body, headers=self.headers)
            self.assertEqual(response.status_code, 201, response.text)
            exercise_id = response.json()['id']
            first_url = response.json()['cover_url']
            self.assertEqual(first_url, uploaded[-1])
            route = f'/api/v1/exercises/{exercise_id}/cover'
            photo = await self.client.get(route)
            self.assertEqual(photo.status_code, 302)
            self.assertEqual(photo.headers['location'], first_url)
            self.assertEqual((await self.client.get(route, headers={'If-None-Match': photo.headers['etag']})).status_code, 304)
            body.pop('cover_image')
            preserved = await self.client.put(f'/api/v1/admin/exercises/{exercise_id}', json=body, headers=self.headers)
            self.assertEqual(preserved.json()['cover_url'], first_url)
            body['cover_image'] = image('blue')
            replaced = await self.client.put(f'/api/v1/admin/exercises/{exercise_id}', json=body, headers=self.headers)
            self.assertNotEqual(replaced.json()['cover_url'], first_url)
            current_url = replaced.json()['cover_url']
            from fastapi import HTTPException
            upload.side_effect = HTTPException(503, 'Cloudinary no permite subir imágenes.')
            failed_body = {**body, 'name': 'Cambio que no debe persistir'}
            failed = await self.client.put(f'/api/v1/admin/exercises/{exercise_id}', json=failed_body, headers=self.headers)
            self.assertEqual(failed.status_code, 503)
            listing = (await self.client.get('/api/v1/admin/exercises', headers=self.headers)).json()
            self.assertEqual(listing[0]['name'], body['name'])
            self.assertEqual(listing[0]['cover_url'], current_url)
            upload.side_effect = fake_upload
            body.pop('cover_image')
            body['published'] = False
            await self.client.put(f'/api/v1/admin/exercises/{exercise_id}', json=body, headers=self.headers)
            self.assertEqual((await self.client.get(route)).status_code, 404)
            private_photo = await self.client.get(route, headers=self.headers)
            self.assertEqual(private_photo.status_code, 302)
            self.assertIn('private', private_photo.headers['cache-control'])
            body['remove_cover'] = True
            removed = await self.client.put(f'/api/v1/admin/exercises/{exercise_id}', json=body, headers=self.headers)
            self.assertIsNone(removed.json()['cover_url'])
            self.assertEqual((await self.client.get(route, headers=self.headers)).status_code, 404)
            body['cover_image'] = 'data:image/png;base64,bm90LWFuLWltYWdl'
            self.assertEqual((await self.client.put(f'/api/v1/admin/exercises/{exercise_id}', json=body, headers=self.headers)).status_code, 422)

    async def test_seed_is_idempotent(self):
        from unittest.mock import patch
        from app.services.catalog import seed_catalog
        with patch("app.services.catalog.SessionLocal", self.sessions):
            await seed_catalog()
            await seed_catalog()
        data = (await self.client.get("/api/v1/exercises")).json()
        self.assertEqual(len(data), 22)
