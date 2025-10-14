"""
Servicio de Usuarios
Maneja autenticación y perfil de usuario
"""
from sqlalchemy.orm import Session
from sqlalchemy.orm.attributes import flag_modified
from typing import List, Optional, Dict
from datetime import datetime
import hashlib

from app.models.user import User
from app.schemas.user import UserUpdate, VisitedPlace, UserRegister


class UserService:
    def __init__(self, db: Session):
        self.db = db
    
    def _hash_password(self, password: str) -> str:
        """Hash simple de contraseña con SHA256"""
        return hashlib.sha256(password.encode()).hexdigest()
    
    def _generate_user_id(self) -> str:
        """Generar user_id secuencial simple"""
        # Obtener el último usuario
        last_user = self.db.query(User).order_by(User.id.desc()).first()
        
        if last_user and last_user.user_id.startswith("user_"):
            try:
                last_num = int(last_user.user_id.split("_")[1])
                new_num = last_num + 1
            except:
                new_num = 1
        else:
            new_num = 1
        
        return f"user_{new_num:03d}"  # user_001, user_002, etc.
    
    def register_user(self, user_data: UserRegister) -> User:
        """
        Registrar nuevo usuario
        
        Args:
            user_data: Datos de registro
            
        Returns:
            Usuario creado
            
        Raises:
            ValueError: Si el email ya existe
        """
        # Verificar si email ya existe
        existing_user = self.db.query(User).filter(
            User.email == user_data.email
        ).first()
        
        if existing_user:
            raise ValueError("El email ya está registrado")
        
        # Generar user_id
        user_id = self._generate_user_id()
        
        # Hash de contraseña
        hashed_password = self._hash_password(user_data.password)
        
        # Crear usuario
        new_user = User(
            user_id=user_id,
            name=user_data.name,
            email=user_data.email,
            password=hashed_password,
            age=user_data.age,
            nationality=user_data.nationality,
            preferences=user_data.preferences or [],
            visited_places=[],
            favorite_categories=[]
        )
        
        self.db.add(new_user)
        self.db.commit()
        self.db.refresh(new_user)
        
        print(f"✅ Usuario registrado: {user_id} - {user_data.name}")
        
        return new_user
    
    def login_user(self, email: str, password: str) -> Optional[User]:
        """
        Autenticar usuario
        
        Args:
            email: Email del usuario
            password: Contraseña
            
        Returns:
            Usuario si credenciales correctas, None si incorrectas
        """
        # Hash de contraseña proporcionada
        hashed_password = self._hash_password(password)
        
        # Buscar usuario
        user = self.db.query(User).filter(
            User.email == email,
            User.password == hashed_password
        ).first()
        
        if user:
            # Actualizar last_login
            user.last_login = datetime.utcnow()
            self.db.commit()
            print(f"✅ Login exitoso: {user.user_id} - {user.name}")
        else:
            print(f"❌ Login fallido para: {email}")
        
        return user
    
    def get_user_by_id(self, user_id: str) -> Optional[User]:
        """Obtener usuario por user_id"""
        return self.db.query(User).filter(User.user_id == user_id).first()
    
    def get_user_by_email(self, email: str) -> Optional[User]:
        """Obtener usuario por email"""
        return self.db.query(User).filter(User.email == email).first()
    
    def update_user_profile(
        self, 
        user_id: str, 
        updates: UserUpdate
    ) -> Optional[User]:
        """
        Actualizar perfil de usuario
        
        Args:
            user_id: ID del usuario
            updates: Datos a actualizar
            
        Returns:
            Usuario actualizado
        """
        user = self.get_user_by_id(user_id)
        
        if not user:
            return None
        
        # Actualizar campos
        if updates.name is not None:
            user.name = updates.name
        if updates.age is not None:
            user.age = updates.age
        if updates.nationality is not None:
            user.nationality = updates.nationality
        if updates.preferences is not None:
            user.preferences = updates.preferences
        
        user.updated_at = datetime.utcnow()
        
        self.db.commit()
        self.db.refresh(user)
        
        return user
    
    def add_visited_place(
        self, 
        user_id: str, 
        place: VisitedPlace
    ) -> Optional[User]:
        """
        Registrar lugar visitado
        
        Args:
            user_id: ID del usuario
            place: Datos del lugar visitado
            
        Returns:
            Usuario actualizado
        """
        user = self.get_user_by_id(user_id)
        
        if not user:
            return None
        
        # Crear registro de visita
        visit_record = {
            "place_id": place.place_id,
            "place_name": place.place_name,
            "rating": place.rating,
            "category": place.category,
            "visited_at": datetime.utcnow().isoformat()
        }
        
        # Agregar a visited_places
        visited_places = user.visited_places or []
        visited_places.append(visit_record)
        user.visited_places = visited_places
        
        # CRÍTICO: Notificar a SQLAlchemy que el campo JSON cambió
        flag_modified(user, "visited_places")
        
        # Actualizar categorías favoritas
        self._update_favorite_categories(user)
        
        user.updated_at = datetime.utcnow()
        
        self.db.commit()
        self.db.refresh(user)
        
        print(f"📍 {user.name} visitó: {place.place_name}")
        
        return user
    
    def _update_favorite_categories(self, user: User):
        """
        Calcular categorías favoritas basadas en historial
        """
        if not user.visited_places:
            return
        
        # Contar categorías
        category_counts = {}
        for visit in user.visited_places:
            category = visit.get("category")
            rating = visit.get("rating", 0)
            
            if category:
                if category not in category_counts:
                    category_counts[category] = {"count": 0, "total_rating": 0}
                
                category_counts[category]["count"] += 1
                category_counts[category]["total_rating"] += rating or 0
        
        # Ordenar por frecuencia y rating
        sorted_categories = sorted(
            category_counts.items(),
            key=lambda x: (x[1]["count"], x[1]["total_rating"]),
            reverse=True
        )
        
        # Top 5 categorías
        user.favorite_categories = [cat[0] for cat in sorted_categories[:5]]
        
        # CRÍTICO: Notificar a SQLAlchemy que el campo JSON cambió
        flag_modified(user, "favorite_categories")
    
    def get_user_profile_dict(self, user: User) -> Dict:
        """
        Convertir usuario a dict para response
        """
        return {
            "user_id": user.user_id,
            "name": user.name,
            "email": user.email,
            "age": user.age,
            "nationality": user.nationality,
            "preferences": user.preferences or [],
            "visited_places": user.visited_places or [],
            "favorite_categories": user.favorite_categories or [],
            "created_at": user.created_at.isoformat(),
            "last_login": user.last_login.isoformat() if user.last_login else None
        }
    
    def get_user_personalization_context(self, user: User) -> Dict:
        """
        Obtener contexto de personalización para recomendaciones
        
        Returns:
            {
                "nationality": "Japan",
                "age": 25,
                "preferences": ["museums", "restaurants"],
                "favorite_categories": ["museums", "japanese_restaurant"],
                "visited_count": 15,
                "avg_rating": 4.3,
                "personality_traits": {
                    "explorer": 0.8,
                    "culture_lover": 0.9,
                    "foodie": 0.7
                }
            }
        """
        visited_places = user.visited_places or []
        
        # Calcular promedio de rating
        ratings = [v.get("rating", 0) for v in visited_places if v.get("rating")]
        avg_rating = sum(ratings) / len(ratings) if ratings else 0
        
        # Analizar personalidad basada en comportamiento
        personality_traits = self._analyze_personality(user)
        
        return {
            "nationality": user.nationality,
            "age": user.age,
            "preferences": user.preferences or [],
            "favorite_categories": user.favorite_categories or [],
            "visited_count": len(visited_places),
            "avg_rating": round(avg_rating, 1),
            "personality_traits": personality_traits
        }
    
    def _analyze_personality(self, user: User) -> Dict[str, float]:
        """
        Analizar rasgos de personalidad basados en comportamiento
        
        Returns:
            Scores de 0-1 para diferentes rasgos
        """
        visited_places = user.visited_places or []
        preferences = user.preferences or []
        
        traits = {
            "explorer": 0.5,      # Diversidad de lugares
            "culture_lover": 0.5, # Interés en cultura
            "foodie": 0.5,        # Interés en comida
            "social": 0.5,        # Lugares sociales
            "nature_lover": 0.5   # Parques, naturaleza
        }
        
        if not visited_places:
            return traits
        
        # Contar categorías únicas
        unique_categories = set(v.get("category") for v in visited_places if v.get("category"))
        traits["explorer"] = min(len(unique_categories) / 10, 1.0)
        
        # Analizar categorías
        cultural_categories = ["museum", "art_gallery", "cultural", "landmark"]
        food_categories = ["restaurant", "cafe", "bar", "food"]
        social_categories = ["bar", "nightlife", "entertainment"]
        nature_categories = ["park", "nature", "zoo", "aquarium"]
        
        total_visits = len(visited_places)
        
        cultural_count = sum(1 for v in visited_places if v.get("category") in cultural_categories)
        food_count = sum(1 for v in visited_places if v.get("category") in food_categories)
        social_count = sum(1 for v in visited_places if v.get("category") in social_categories)
        nature_count = sum(1 for v in visited_places if v.get("category") in nature_categories)
        
        traits["culture_lover"] = min(cultural_count / max(total_visits * 0.3, 1), 1.0)
        traits["foodie"] = min(food_count / max(total_visits * 0.3, 1), 1.0)
        traits["social"] = min(social_count / max(total_visits * 0.3, 1), 1.0)
        traits["nature_lover"] = min(nature_count / max(total_visits * 0.3, 1), 1.0)
        
        return {k: round(v, 2) for k, v in traits.items()}
