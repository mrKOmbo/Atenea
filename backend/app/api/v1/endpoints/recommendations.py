from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.recommendation import RecommendationRequest, RecommendationResponse
from app.services.recommendation_service import RecommendationService
from app.services.context.context_aware_service import ContextAwareService
from app.services.user_service import UserService

router = APIRouter()


@router.post("/", response_model=RecommendationResponse)
async def get_recommendations(
    request: RecommendationRequest,
    db: Session = Depends(get_db)
):
    """
    Obtener recomendaciones personalizadas de lugares y eventos
    basadas en la ubicación y preferencias del usuario.
    
    🧠 CONTEXTO INTELIGENTE:
    - Considera clima actual (lluvia, temperatura)
    - Detecta días festivos y eventos especiales
    - Incluye eventos en la ciudad
    - Ajusta recomendaciones según contexto
    
    👤 PERSONALIZACIÓN:
    - Usa nacionalidad del usuario (ej: japonés → restaurantes japoneses)
    - Analiza historial de visitas
    - Considera edad y rasgos de personalidad
    - Prioriza categorías favoritas
    """
    service = RecommendationService(db)
    context_service = ContextAwareService()
    user_service = UserService(db)
    
    try:
        # 1. Obtener contexto ambiental (clima, eventos, festivos)
        context = context_service.get_full_context(
            lat=request.location["lat"],
            lon=request.location["lon"]
        )
        
        # 2. Obtener contexto del usuario (perfil, historial)
        user_context = None
        user = user_service.get_user_by_id(request.user_id)
        if user:
            user_context = user_service.get_user_personalization_context(user)
            print(f"👤 Usuario: {user.name} | Nacionalidad: {user.nationality} | Visitas: {len(user.visited_places or [])}")
        
        # 3. Generar recomendaciones personalizadas
        recommendations = service.generate_recommendations(
            user_id=request.user_id,
            latitude=request.location["lat"],
            longitude=request.location["lon"],
            preferences=request.preferences,
            user_context=user_context  # 👈 Nuevo parámetro
        )
        
        # 4. Aplicar contexto ambiental
        recommendations = context_service.apply_context_to_recommendations(
            recommendations, 
            context
        )
        
        # 5. Generar narrativa
        narrative = context_service.get_context_narrative(context)
        
        return {
            "recommendations": recommendations,
            "context": context,
            "context_narrative": narrative
        }
        
    except Exception as e:
        import traceback
        print(f"❌ Error: {str(e)}")
        print(traceback.format_exc())
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error generando recomendaciones: {str(e)}"
        )
