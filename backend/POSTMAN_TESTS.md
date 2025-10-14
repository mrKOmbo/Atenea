# 🧪 Testing Completo con Postman
Autor: Gael Zamora + Claude AI
Fecha: 2025-10-14

Guía paso a paso para probar todo el sistema sin errores.

---

## ✅ Pre-requisitos

```bash
# 1. Iniciar servidor
cd backend
docker build .
docker-compose up --build --remove-orphans

# 2. Esperar estos logs:
# ✓ Gemini IA inicializado correctamente
# INFO: Uvicorn running on http://0.0.0.0:8000
```

---

## 📝 Tests en Orden

### Test 1: Health Check

```
GET http://localhost:8000/health
```

**Response esperado:**
```json
{"status": "healthy"}
```

---

### Test 2: Registro de Usuario

```
POST http://localhost:8000/api/v1/users/register
Content-Type: application/json

{
  "name": "Yuki Tanaka",
  "email": "yuki@test.com",
  "password": "test123",
  "age": 28,
  "nationality": "Japan",
  "preferences": ["museums", "restaurants"]
}
```

**✅ Verificar:**
- `user_id` presente (ej: "user_001")
- `visited_places: []` (vacío)
- `favorite_categories: []` (vacío)
- `personality_traits` todos en 0.5

📝 **Guardar `user_id` para próximos tests**

---

### Test 3: Login

```
POST http://localhost:8000/api/v1/users/login
Content-Type: application/json

{
  "email": "yuki@test.com",
  "password": "test123"
}
```

**✅ Verificar:** `user_id` coincide con registro

---

### Test 4: Ver Perfil
  
```
GET http://localhost:8000/api/v1/users/user_001
```

**✅ Verificar:** Sin lugares visitados aún

---

### Test 5: Primera Recomendación

```
POST http://localhost:8000/api/v1/recommendations/
Content-Type: application/json

{
  "user_id": "user_001",
  "location": {"lat": 19.4326, "lon": -99.1332},
  "preferences": ["restaurants"]
}
```

**✅ Verificar:**
- 10-15 recomendaciones retornadas
- **Nombres incluyen restaurantes JAPONESES** (Sushi, Ramen, Yakitori)
- `reason` incluye "🌍 +25% boost (match nacionalidad: japan)"

**Logs del servidor:**
```
🔍 Usando keyword: 'japanese restaurant sushi ramen yakitori'
✓ Encontrados X lugares tipo 'restaurant' (keyword: '...')
```

📝 **Guardar 3 `place_id` para crear plan**

---

### Test 6: Crear Plan

```
POST http://localhost:8000/api/v1/plans/
Content-Type: application/json

{
  "user_id": "user_001",
  "name": "Mi día en CDMX",
  "activities": [
    {"type": "restaurants", "id": "ChIJ...place_id_1"},
    {"type": "museums", "id": "ChIJ...place_id_2"},
    {"type": "cafes", "id": "ChIJ...place_id_3"}
  ],
  "start_time": "2024-11-02T09:00:00Z"
}
```

**✅ Verificar:**
- `plan_id` presente
- 3 actividades con horarios
- `transport_to_here` con 4 opciones (walking, transit, driving, bicycling)
- `status: "draft"`

📝 **Guardar `plan_id`**

---

### Test 7: Completar Plan (Sin Ratings)

```
POST http://localhost:8000/api/v1/plans/{plan_id}/complete
Content-Type: application/json

{}
```

**✅ Verificar:**
- `status: "completed"`

**Logs del servidor (IMPORTANTE):**
```
🎉 Plan completado: Mi día en CDMX
  ✅ Registrado: [Lugar 1] (restaurants)
  ✅ Registrado: [Lugar 2] (museums)
  ✅ Registrado: [Lugar 3] (cafes)
📍 3 lugar(es) registrados en el perfil de Yuki Tanaka
⭐ Categorías favoritas actualizadas: ['restaurants', 'museums', 'cafes']
```

---

### Test 8: Ver Perfil Actualizado (🧠 Aprendizaje)

```
GET http://localhost:8000/api/v1/users/user_001
```

**✅ Verificar CAMBIOS:**
- ✅ `visited_places`: 3 lugares (antes: 0)
- ✅ `favorite_categories`: ["restaurants", "museums", "cafes"] (antes: [])
- ✅ `personality_traits`:
  - `foodie`: 0.7 (antes: 0.5) ⬆️
  - `culture_lover`: 0.65 (antes: 0.5) ⬆️
  - `explorer`: 0.6 (antes: 0.5) ⬆️

🎉 **¡El sistema aprendió del usuario!**

---

### Test 9: Segunda Recomendación (Mejorada)

```
POST http://localhost:8000/api/v1/recommendations/
Content-Type: application/json

{
  "user_id": "user_001",
  "location": {"lat": 19.4326, "lon": -99.1332},
  "preferences": ["restaurants"]
}
```

**✅ Verificar MEJORAS:**
- `reason` ahora incluye **MÚLTIPLES boosts**:
  - 🌍 +25% (nacionalidad)
  - ⭐ +15% (categoría favorita) ← **NUEVO**
  - 🍽️ +12% (foodie) ← **NUEVO**
- `score` más alto (0.95-0.98 vs 0.85-0.93 antes)

**Logs:**
```
👤 Usuario: Yuki Tanaka | Nacionalidad: Japan | Visitas: 3
⭐ Agregando 'restaurants' (categoría favorita del usuario)
  Yakitori Kaji: 🌍 +25% + ⭐ +15% + 🍽️ +12% = 0.97
```

🎉 **¡Las recomendaciones mejoraron automáticamente!**

---

### Test 10: Completar Plan con Ratings

**Crear otro plan y completarlo con ratings:**

```
POST http://localhost:8000/api/v1/plans/
...
```

Luego completar con ratings:

```
POST http://localhost:8000/api/v1/plans/{plan_id_2}/complete
Content-Type: application/json

{
  "activity_ratings": {
    "ChIJ...place_1": 5,
    "ChIJ...place_2": 4
  }
}
```

**✅ Verificar:** Ratings guardados en `visited_places`

---

## 📊 Checklist Final

Después de todos los tests:

### Autenticación ✅
- [x] Registro funciona
- [x] Login funciona
- [x] Ver perfil funciona

### Recomendaciones ✅
- [x] Primera búsqueda retorna lugares
- [x] Keywords por nacionalidad funcionan
- [x] Boost +25% por nacionalidad aplicado
- [x] Boost +15% por categoría favorita (después de plan)
- [x] Boost +12% por personalidad (foodie)

### Planes ✅
- [x] Crear plan funciona
- [x] Optimiza orden de lugares
- [x] Calcula 4 opciones de transporte
- [x] Ver plan funciona

### Aprendizaje Automático ✅
- [x] Completar plan actualiza `visited_places`
- [x] Actualiza `favorite_categories` automáticamente
- [x] Actualiza `personality_traits` automáticamente
- [x] Recomendaciones mejoran después de planes

---

## 🔥 Test Extra: Usuario Italiano

**Registrar usuario italiano:**
```json
{
  "name": "Marco Rossi",
  "email": "marco@test.com",
  "nationality": "Italy"
}
```

**Pedir recomendaciones:**
```json
{
  "user_id": "user_002",
  "preferences": ["restaurants", "cafes"]
}
```

**✅ Verificar:**
- Logs muestran: `🔍 Usando keyword: 'italian restaurant pizza pasta'`
- Resultados incluyen restaurantes italianos
- `reason` incluye "🌍 +25% boost (match nacionalidad: italy)"

---

## 🎉 Resultado

**Si TODOS los tests pasan:**
- ✅ Autenticación funciona
- ✅ Recomendaciones personalizadas funcionan
- ✅ Planes optimizados funcionan
- ✅ Sistema de aprendizaje funciona
- ✅ **Aplicación 100% operativa**

---

**¡Listo para probar en Postman!** 🚀
