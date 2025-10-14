from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.db.session import get_db
from app.schemas.plan import (
    PlanCreateRequest, 
    PlanResponse, 
    PlanUpdateRequest,
    PlanCompleteRequest
)
from app.services.plan_service import PlanService

router = APIRouter()


@router.post("/", response_model=PlanResponse, status_code=status.HTTP_201_CREATED)
async def create_plan(
    plan_request: PlanCreateRequest,
    db: Session = Depends(get_db)
):
    """
    Crear un plan personalizado optimizando rutas y tiempos
    """
    service = PlanService(db)
    try:
        plan = service.create_optimized_plan(plan_request)
        return plan
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        import traceback
        print(f"❌ Error creando plan: {str(e)}")
        print(traceback.format_exc())
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error creando plan: {str(e)}"
        )


@router.get("/{plan_id}", response_model=PlanResponse)
async def get_plan(
    plan_id: str,
    db: Session = Depends(get_db)
):
    """
    Obtener detalles de un plan específico
    """
    service = PlanService(db)
    plan = service.get_plan_by_id(plan_id)
    if not plan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Plan no encontrado"
        )
    return plan


@router.get("/user/{user_id}", response_model=List[PlanResponse])
async def get_user_plans(
    user_id: str,
    status_filter: str = None,
    db: Session = Depends(get_db)
):
    """
    Obtener todos los planes de un usuario
    """
    service = PlanService(db)
    return service.get_user_plans(user_id, status_filter)


@router.put("/{plan_id}", response_model=PlanResponse)
async def update_plan(
    plan_id: str,
    plan_update: PlanUpdateRequest,
    db: Session = Depends(get_db)
):
    """
    Actualizar información de un plan
    """
    service = PlanService(db)
    updated_plan = service.update_plan(plan_id, plan_update)
    if not updated_plan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Plan no encontrado"
        )
    return updated_plan


@router.delete("/{plan_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_plan(
    plan_id: str,
    db: Session = Depends(get_db)
):
    """
    Eliminar un plan
    """
    service = PlanService(db)
    success = service.delete_plan(plan_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Plan no encontrado"
        )
    return None


@router.post("/{plan_id}/complete", response_model=PlanResponse)
async def complete_plan(
    plan_id: str,
    complete_request: PlanCompleteRequest = None,
    db: Session = Depends(get_db)
):
    """
    Completar un plan y registrar automáticamente todos los lugares visitados
    
    **Esto aprende del usuario:**
    - Registra todos los lugares del plan como visitados
    - Actualiza categorías favoritas automáticamente
    - Recalcula rasgos de personalidad
    - Futuras recomendaciones serán más precisas
    
    **Ratings opcionales:**
    Puedes proporcionar ratings (1-5) para cada lugar:
    ```json
    {
      "activity_ratings": {
        "ChIJ...place_id_1": 5,
        "ChIJ...place_id_2": 4,
        "ChIJ...place_id_3": 3
      }
    }
    ```
    """
    service = PlanService(db)
    
    # Extraer ratings si se proporcionaron
    activity_ratings = None
    if complete_request:
        activity_ratings = complete_request.activity_ratings
    
    completed_plan = service.complete_plan(plan_id, activity_ratings)
    
    if not completed_plan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Plan no encontrado"
        )
    
    return completed_plan
