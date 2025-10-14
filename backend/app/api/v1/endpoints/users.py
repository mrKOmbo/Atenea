from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.user import (
    UserRegister, 
    UserLogin, 
    UserProfile, 
    UserUpdate,
    VisitedPlace,
    LoginResponse
)
from app.services.user_service import UserService

router = APIRouter()


@router.post("/register", response_model=UserProfile, status_code=status.HTTP_201_CREATED)
async def register_user(
    user_data: UserRegister,
    db: Session = Depends(get_db)
):
    """
    Registrar nuevo usuario
    
    **Campos:**
    - name: Nombre completo
    - email: Email único
    - password: Contraseña (será hasheada)
    - age: Edad (opcional)
    - nationality: Nacionalidad (opcional, ej: "Mexico", "Japan", "USA")
    - preferences: Lista de preferencias (opcional)
    """
    service = UserService(db)
    
    try:
        user = service.register_user(user_data)
        return service.get_user_profile_dict(user)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error registrando usuario: {str(e)}"
        )


@router.post("/login", response_model=LoginResponse)
async def login_user(
    credentials: UserLogin,
    db: Session = Depends(get_db)
):
    """
    Iniciar sesión
    
    **Retorna:** Información del usuario si credenciales correctas
    """
    service = UserService(db)
    
    user = service.login_user(credentials.email, credentials.password)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email o contraseña incorrectos"
        )
    
    return {
        "user_id": user.user_id,
        "name": user.name,
        "email": user.email,
        "nationality": user.nationality,
        "message": f"Bienvenido de vuelta, {user.name}!"
    }


@router.get("/{user_id}", response_model=UserProfile)
async def get_user_profile(
    user_id: str,
    db: Session = Depends(get_db)
):
    """
    Obtener perfil de usuario
    """
    service = UserService(db)
    user = service.get_user_by_id(user_id)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuario no encontrado"
        )
    
    return service.get_user_profile_dict(user)


@router.put("/{user_id}", response_model=UserProfile)
async def update_user_profile(
    user_id: str,
    updates: UserUpdate,
    db: Session = Depends(get_db)
):
    """
    Actualizar perfil de usuario
    """
    service = UserService(db)
    user = service.update_user_profile(user_id, updates)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuario no encontrado"
        )
    
    return service.get_user_profile_dict(user)


@router.post("/{user_id}/visited", response_model=UserProfile)
async def add_visited_place(
    user_id: str,
    place: VisitedPlace,
    db: Session = Depends(get_db)
):
    """
    Registrar lugar visitado por el usuario
    
    Esto ayuda a personalizar futuras recomendaciones
    """
    service = UserService(db)
    user = service.add_visited_place(user_id, place)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuario no encontrado"
        )
    
    return service.get_user_profile_dict(user)
