from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()

# NOTA: No importar modelos aquí para evitar importación circular
# Los modelos se importan en alembic/env.py para las migraciones
