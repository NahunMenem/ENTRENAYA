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
        public = (await self.client.get("/api/v1/routines")).json()
        self.assertEqual(public[0]["exercises"][0]["name"], body["name"])
        body["published"] = False
        self.assertEqual((await self.client.put(f"/api/v1/admin/exercises/{exercise_id}", json=body, headers=self.headers)).status_code, 409)
        template["published"] = False
        self.assertEqual((await self.client.put(f"/api/v1/admin/routines/{routine_id}", json=template, headers=self.headers)).status_code, 200)
        self.assertEqual((await self.client.get("/api/v1/routines")).json(), [])
        self.assertEqual((await self.client.put(f"/api/v1/admin/exercises/{exercise_id}", json=body, headers=self.headers)).status_code, 200)
        self.assertEqual((await self.client.get("/api/v1/exercises")).json(), [])
        self.assertEqual(len((await self.client.get("/api/v1/admin/exercises", headers=self.headers)).json()), 1)

    async def test_validation(self):
        body = dict(name="Press", muscle_group="Pecho", video_url="http://example.com/video.mp4")
        self.assertEqual((await self.client.post("/api/v1/admin/exercises", json=body, headers=self.headers)).status_code, 422)
        template = dict(name="Test", category="Volumen", level="Principiante", days=[1, 1],
            exercises=[dict(id="unknown", sets=0, reps=12, rest_seconds=90)])
        self.assertEqual((await self.client.post("/api/v1/admin/routines", json=template, headers=self.headers)).status_code, 422)

    async def test_seed_is_idempotent(self):
        from unittest.mock import patch
        from app.services.catalog import seed_catalog
        with patch("app.services.catalog.SessionLocal", self.sessions):
            await seed_catalog()
            await seed_catalog()
        data = (await self.client.get("/api/v1/exercises")).json()
        self.assertEqual(len(data), 22)
