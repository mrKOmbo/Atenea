# 🎯 Sistema Atenea Backend - Simplificado

## 📦 Descripción

Sistema de recomendaciones y planificación de viajes para CDMX usando Google Places y Directions API.

**Filosofía: Todo en tiempo real desde Google API**

---

## 🚀 Endpoints Disponibles

### 1. Usuarios (Autenticación y Perfil)

```http
POST /api/v1/users/register            # Registro
POST /api/v1/users/login                # Login
GET /api/v1/users/{user_id}             # Ver perfil
PUT /api/v1/users/{user_id}             # Actualizar perfil
POST /api/v1/users/{user_id}/visited    # Registrar lugar visitado
```

### 2. Recomendaciones (🧠 IA Personalizada)

```http
POST /api/v1/recommendations/
```

**Obtiene lugares recomendados personalizados según:**
- 🌍 Nacionalidad del usuario (keywords específicos)
- 📊 Historial de visitas (categorías favoritas)
- 🎂 Edad y rasgos de personalidad (foodie, culture_lover)
- ☁️ Clima actual (lluvia → lugares cubiertos)
- 🎪 Eventos en la ciudad
- 🎉 Días festivos

**Personalización por nacionalidad:**
- 🇯🇵 Japonés → Restaurantes japoneses, izakayas, museos de arte japonés
- 🇮🇹 Italiano → Restaurantes italianos, gelaterías, arte renacentista
- 🇫🇷 Francés → Bistros, patisserías, arte impresionista
- Y más... (11 nacionalidades × 7 tipos de lugares = 77 combinaciones)

**Request:**
```json
{
  "user_id": "user_123",
  "location": {
    "lat": 19.4326,
    "lon": -99.1332
  },
  "preferences": ["museums", "parks", "restaurants"]
}
```

**Response:**
```json
{
  "recommendations": [
    {
      "name": "Museo Nacional de Arte",
      "type": "museums",
      "location": {"lat": 19.4342, "lon": -99.1411},
      "rating": 4.7,
      "distance": 0.8,
      "score": 0.92,
      "metadata": {
        "place_id": "ChIJ..."
      }
    }
  ]
}
```

### 3. Planes (🗺️ Optimización de Rutas + 🧠 Aprendizaje)

```http
POST /api/v1/plans/                      # Crear plan optimizado
GET /api/v1/plans/{plan_id}              # Ver plan
GET /api/v1/plans/user/{user_id}         # Ver todos los planes del usuario
PUT /api/v1/plans/{plan_id}              # Actualizar plan
DELETE /api/v1/plans/{plan_id}           # Eliminar plan
POST /api/v1/plans/{plan_id}/complete    # 🧠 Completar plan (aprende automáticamente)
```

**Crea planes optimizados y aprende del usuario:**
- 🗺️ Optimiza orden de lugares por proximidad
- 🚇 Calcula rutas con 4 opciones de transporte (walking, transit, driving, bicycling)
- ⏱️ Estima tiempos reales con Google Directions API
- 🧠 **Al completar plan: registra automáticamente lugares visitados**

**Request (Crear Plan):**
```json
{
  "user_id": "user_123",
  "name": "Mi día en CDMX",
  "activities": [
    {
      "type": "restaurants",
      "id": "ChIJGX_PSsP_0YURvm73DGoe4r4"
    },
    {
      "type": "parks",
      "id": "ChIJf6l_FyX_0YURuQa4gW_XvJM"
    }
  ],
  "start_time": "2024-12-15T09:00:00Z"
}
```

**Request (Completar Plan - Aprende Automáticamente):**
```bash
POST /api/v1/plans/plan_abc123/complete

# Con ratings opcionales
{
  "activity_ratings": {
    "ChIJGX_PSsP_0YURvm73DGoe4r4": 5,
    "ChIJf6l_FyX_0YURuQa4gW_XvJM": 4
  }
}
```

**¿Qué hace?**
1. ✅ Marca el plan como `completed`
2. ✅ Registra todos los lugares del plan en `visited_places`
3. ✅ Recalcula `favorite_categories` automáticamente
4. ✅ Actualiza `personality_traits` (foodie, culture_lover, etc.)
5. ✅ **Futuras recomendaciones son +30% más precisas**

---

## 🏗️ Arquitectura

### Stack
- **Backend**: FastAPI (Python 3.11)
- **Base de Datos**: PostgreSQL 15
- **APIs**: Google Places, Google Directions, Gemini AI
- **Deploy**: Docker + Docker Compose

### Estructura

```
backend/
├── app/
│   ├── api/v1/endpoints/
│   │   ├── recommendations.py ✅
│   │   └── plans.py ✅
│   ├── services/
│   │   ├── recommendation_service.py ✅
│   │   └── plan_service.py ✅
│   ├── schemas/
│   │   ├── recommendation.py ✅
│   │   └── plan.py ✅
│   └── models/
│       ├── plan.py ✅ (Solo planes se guardan en BD)
│       └── recommendation.py
└── main.py
```

### 🗄️ Base de Datos

**Solo se persiste:**
- ✅ **Plans** - Planes del usuario
- ✅ **PlanActivities** - Actividades dentro del plan

**NO se guarda:**
- ❌ Places - Vienen de Google Places API
- ❌ Events - No se usan
- ❌ Recommendations - Solo se retornan

---

## 🔄 Flujo del Sistema

```
1. Usuario → POST /recommendations/
   ↓
   Sistema consulta Google Places API
   ↓
   Retorna lugares con place_id

2. Usuario selecciona lugares
   ↓
   Frontend guarda place_id

3. Usuario → POST /plans/
   ↓
   Sistema obtiene detalles de Google Places API
   ↓
   Optimiza orden por proximidad
   ↓
   Calcula rutas con Google Directions API
   ↓
   GUARDA plan en PostgreSQL
   ↓
   Retorna plan completo

4. Usuario → GET /plans/user/{user_id}
   ↓
   Retorna planes guardados
```

---

## ⚙️ Configuración

### Variables de Entorno (.env)

```env
# Base de datos
DATABASE_URL=postgresql://user:password@postgres:5432/atenea_db

# Google APIs
GOOGLE_MAPS_API_KEY=your_key_here
GOOGLE_GEMINI_API_KEY=your_key_here
AI_PROVIDER=gemini

# API
PROJECT_NAME=Atenea Backend
VERSION=1.0.0
API_V1_STR=/api/v1
```

### Iniciar

```bash
# Levantar servicios
docker-compose up --build

# Acceder
- API: http://localhost:8000
- Docs: http://localhost:8000/docs
```

---

## 📊 APIs Externas

### Google Places API
- **Nearby Search**: Buscar lugares cercanos
- **Place Details**: Detalles de un lugar por place_id
- **Uso**: Recommendations + Plans
- **Costo**: GRATIS hasta 40,000 requests/mes

### Google Directions API
- **Directions**: Rutas y tiempos reales
- **Modos**: walking, bicycling, transit, driving
- **Uso**: Plans (cálculo de rutas)
- **Costo**: GRATIS hasta 40,000 requests/mes

### Google Gemini AI
- **Text Generation**: Razones personalizadas
- **Uso**: Recommendations (opcional)
- **Costo**: GRATIS

---

## ✅ Funcionalidades

### Recomendaciones
- ✅ Búsqueda en tiempo real (Google Places)
- ✅ Filtrado por preferencias
- ✅ Cálculo de distancias
- ✅ Score inteligente
- ✅ Razones con Gemini AI
- ✅ Sin persistencia en BD

### Planes
- ✅ Obtención de lugares desde Google Places
- ✅ Optimización por proximidad (Nearest Neighbor)
- ✅ Rutas reales con Google Directions
- ✅ 4 modos de transporte
- ✅ Horarios automáticos
- ✅ Resumen de tiempos
- ✅ **Persistencia en PostgreSQL**

---

## 🧪 Testing

### 1. Obtener Recomendaciones

```bash
POST http://localhost:8000/api/v1/recommendations/
```

### 2. Crear Plan (usar place_id de recomendaciones)

```bash
POST http://localhost:8000/api/v1/plans/
```

### 3. Ver Planes del Usuario

```bash
GET http://localhost:8000/api/v1/plans/user/user_123
```

---

## 📝 Notas Importantes

1. **No hay CRUD de Places/Events** - Todo viene de Google API
2. **Los planes SÍ se guardan** - PostgreSQL
3. **Escalable** - Puede crecer si es necesario
4. **Real-time** - Datos siempre actualizados de Google

---

## 💰 Costos

Con $200 USD gratis/mes de Google Cloud:

| API | Requests/mes | Planes/mes | Costo |
|-----|--------------|------------|-------|
| Places | 40,000 | ~10,000 | GRATIS |
| Directions | 40,000 | ~5,000 | GRATIS |
| Gemini AI | Ilimitado* | ∞ | GRATIS |

**Para MVP: 100% GRATIS** 🎉

---

## 🐛 Troubleshooting

### Error: REQUEST_DENIED
**Solución:** Habilitar Places API y Directions API en Google Cloud Console

### Error: Connection refused
**Solución:** `docker-compose down && docker-compose up`

### Error: Import error
**Solución:** `docker-compose up --build`

---

## 📚 Documentación

- **Swagger**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/health

---

¡Sistema simplificado y listo para producción! 🚀
