from fastapi import APIRouter
from app.api.v1.endpoints import recommendations, plans, users

api_router = APIRouter()

# Endpoints principales del sistema
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(recommendations.router, prefix="/recommendations", tags=["recommendations"])
api_router.include_router(plans.router, prefix="/plans", tags=["plans"])
