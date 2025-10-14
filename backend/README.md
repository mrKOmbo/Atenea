# Backend Atenea

## Descripción general

Atenea es una aplicación enfocada en resolver uno de los principales problemas de la Ciudad de
México: el transporte.

Su objetivo es ofrecer rutas y alternativas inteligentes que permitan prevenir retrasos y mejorar la
experiencia del usuario al desplazarse, considerando factores sociales, ambientales y de tráfico en
tiempo real.

La aplicación utiliza inteligencia artificial para procesar grandes volúmenes de datos y realizar
pronósticos precisos sobre el comportamiento del transporte en todas sus categorías.

## Funcionalidades principales

El sistema se basa en el uso de ubicación en tiempo real, detectando la posición exacta de unidades
de transporte para visualizar su fluidez.

Además, analiza información proveniente de redes sociales y reportes ciudadanos, procesados
mediante modelos de IA para generar alertas y predicciones actualizadas.

### Características clave

- 📱 QR personalizado enfocado en pósters del Mundial.
• 🧭 Corrección de deficiencias de Google Maps, mejorando rutas urbanas locales.
• 🕶 Detección con realidad aumentada para indicar la dirección que se debe seguir.
• 🃏 Reconocimiento de cartas con álbum digital interactivo.
• ⚽ Reservación de partidos, incluyendo selección de asientos.
• 🇲🇽 Recomendación de actividades y lugares para conocer México

## Tecnologías utilizadas

- Python
- FastAPI
- OpenAI API
- PostgreSQL (PostGIS)
- Containerización


## Arquitectura del sistema

### 1. Análisis de fluidez y predicciones

La información de las rutas base parte de lo propocionado por la API de Google Maps, pero se
complementa con datos obtenidos en tiempo real de ubicación de los usuarios activos, además
de información de redes sociales y reportes ciudadanos.

#### Método de recolección de datos y procesamiento

- La aplicación recolecta la ubicación exacta del usuario cada minuto (lat, lon), se envía a un
endpoint seguro en el backend donde se almacena en una base de datos para análisis de 
patrón de movimiento y congestión.

```json
{
    "user_id": "randomized_user_id_12345",
    "latitude": 19.4326,
    "longitude": -99.1332
}
```

Ejemplo con httpie:

```bash
http POST :8000/api/user/location user_id=randomized_user_id_12345 latitude:=19.4326 longitude:=-99.1332
```

- Se generan rutas utilizando la información de Google Maps, pero se ajustan dinámicamente
según la fluidez detectada en tiempo real.

- Se revisan constantemente reportes en redes sociales (Twitter, Facebook, etc.) y se procesan con modelos
de IA para identificar incidentes que puedan afectar el transporte (accidentes, manifestaciones,
clima, etc.). Estos datos se integran en el análisis de rutas.

#### Respuesta deseada

Cuando un usuario solicita una ruta, el sistema debe:

- Analizar la ubicación actual y el destino.
- Consultar la base de datos para evaluar la fluidez en tiempo real.
- Ajustar la ruta propuesta según la información más reciente.
- Generar una predicción de tiempo estimado considerando factores actuales.

```json
{
    "start_location": {"lat": 19.4326, "lon": -99.1332},
    "end_location": {"lat": 19.4270, "lon": -99.1677},
    "estimated_time": 25,  // en minutos, contando con fluidez actual
    "route": [
        {"lat": 19.4326, "lon": -99.1332},
        {"lat": 19.4300, "lon": -99.1400},
        {"lat": 19.4280, "lon": -99.1500},
        {"lat": 19.4270, "lon": -99.1677}
    ],
    "alerts": [
        {"type": "accident", "location": {"lat": 19.4290, "lon": -99.1450}, "description": "Accidente reportado"},
        {"type": "construction", "location": {"lat": 19.4310, "lon": -99.1550}, "description": "Obras en curso"}
    ]
}
```

### 2. Detección de nuevas rutas

Existen ocasiones donde debido al evento se pueden generar nuevas rutas temporales (caminos
cerrados, desvíos, etc.). La aplicación debe ser capaz de detectar estas nuevas rutas
y adaptarse rápidamente.

#### Método de detección y adaptación

- La aplicación monitorea constantemente la ubicación de los usuarios y detecta patrones
de movimiento inusuales que puedan indicar nuevas rutas.
- Se utilizan modelos de IA para analizar estos patrones y validar si representan rutas
válidas.
- Una vez detectada una nueva ruta, se actualiza la base de datos y se presenta como una opción
disponible para los usuarios. Esto solo ocurrirá si la ruta es utilizada por un número
significativo de usuarios (por ejemplo, al menos 5 usuarios en los últimos 10 minutos).
- Estas rutas deben ser temporales y se eliminan si no son utilizadas en un periodo de tiempo
determinado (por ejemplo, 30 minutos).

### 3. Conociendo México

Se ofrecen recomendaciones personalizadas de actividades y lugares para conocer México,
basadas en las preferencias del usuario y su ubicación actual.

#### Método de recomendación

- La aplicación recopila datos sobre las preferencias del usuario (intereses, historial de
visitas, etc.) y su ubicación actual.
- Utiliza modelos de IA para analizar estos datos y generar recomendaciones personalizadas,
partiendo de la base de datos de lugares y actividades disponibles.
- Las recomendaciones se actualizan dinámicamente según la ubicación del usuario y eventos
especiales que puedan estar ocurriendo en la ciudad.
- Los eventos especiales (festivales, conciertos, exposiciones) se obtienen de fuentes
externas y se integran en el sistema de recomendaciones.

#### Respuesta deseada

Cuando un usuario solicita recomendaciones, el sistema debe:

- Analizar las preferencias y ubicación actual del usuario.
- Consultar la base de datos de lugares y actividades.
- Generar una lista de recomendaciones personalizadas.

Se recibe:

```json
{
    "user_id": "randomized_user_id_12345",
    "location": {"lat": 19.4326, "lon": -99.1332},
    "preferences": ["museums", "parks", "events"]
}
```

Se regresa:

```json
{
    "recommendations": [
        {
            "name": "Museo Frida Kahlo",
            "type": "museum",
            "location": {"lat": 19.3550, "lon": -99.1620},
            "description": "Casa museo de la famosa pintora mexicana.",
            "rating": 4.8,
            "distance": 8.5,  // en km desde la ubicación actual
            "time_estimate": 20 // en minutos en transporte público
        },
        {
            "name": "Parque México",
            "type": "park",
            "location": {"lat": 19.4120, "lon": -99.1800},
            "description": "Un hermoso parque en la colonia Condesa.",
            "rating": 4.7,
            "distance": 3.2,
            "time_estimate": 10
        },
        {
            "name": "Concierto en el Zócalo",
            "type": "event",
            "location": {"lat": 19.4326, "lon": -99.1332},
            "description": "Concierto gratuito en el Zócalo este fin de semana.",
            "rating": null,
            "distance": 10.3,
            "time_estimate": 30
        }
    ]
}
```

### 5. Construcción de planes

Permite a los usuarios construir planes personalizados para sus actividades, integrando
transporte, eventos y lugares de interés.

#### Método de construcción de planes

- La aplicación permite a los usuarios seleccionar actividades, eventos y lugares de interés
que desean visitar.
- Utiliza modelos de IA para optimizar la secuencia de visitas y el transporte necesario,
considerando la fluidez en tiempo real y las recomendaciones personalizadas.

#### Respuesta deseada

Cuando un usuario construye un plan, el sistema debe:

- Analizar las selecciones del usuario.
- Optimizar la secuencia de visitas y el transporte necesario.
- Generar un plan detallado con horarios y rutas.

Se recibe:

```json
{
    "user_id": "randomized_user_id_12345",
    "activities": [
        {"type": "museum", "id": "museo_frida_kahlo"},
        {"type": "park", "id": "parque_mexico"},
        {"type": "event", "id": "concierto_zocalo"}
    ],
    "start_time": "2024-05-01T10:00:00Z"
}
```

Se regresa:

```json
{
    "plan": [
        {
            "activity": "Museo Frida Kahlo",
            "start_time": "2024-05-01T10:00:00Z",
            "end_time": "2024-05-01T12:00:00Z",
            "location": {"lat": 19.3550, "lon": -99.1620},
            "transport": {
                "mode": "bus",
                "route": [
                    {"lat": 19.4326, "lon": -99.1332},
                    {"lat": 19.4000, "lon": -99.1500},
                    {"lat": 19.3550, "lon": -99.1620}
                ],
                "estimated_time": 30
            }
        },
        {
            "activity": "Parque México",
            "start_time": "2024-05-01T12:30:00Z",
            "end_time": "2024-05-01T14:00:00Z",
            "location": {"lat": 19.4120, "lon": -99.1800},
            "transport": {
                "mode": "walking",
                "route": [
                    {"lat": 19.3550, "lon": -99.1620},
                    {"lat": 19.3800, "lon": -99.1700},
                    {"lat": 19.4120, "lon": -99.1800}
                ],
                "estimated_time": 20
            }
        },
        {
            "activity": "Concierto en el Zócalo",
            "start_time": "2024-05-01T15:00:00Z",
            "end_time": "2024-05-01T17:00:00Z",
            "location": {"lat": 19.4326, "lon": -99.1332},
            "transport": {
                "mode": "metro",
                "route": [
                    {"lat": 19.4120, "lon": -99.1800},
                    {"lat": 19.4300, "lon": -99.1400},
                    {"lat": 19.4326, "lon": -99.1332}
                ],
                "estimated_time": 25
            }
        }
    ],
    "total_estimated_time": 105 // en minutos, incluyendo transporte y actividades
}


