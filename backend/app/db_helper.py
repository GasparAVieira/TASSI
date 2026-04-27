from sqlalchemy import inspect
from sqlalchemy import text
from app.database import engine

inspector = inspect(engine)

columns = inspector.get_columns("locations")

for col in columns:
    print(col["name"], col["type"])

with engine.connect() as conn:
    result = conn.execute(text("""
        SELECT column_name, data_type
        FROM information_schema.columns
        WHERE table_name = 'locations';
    """))

    for row in result:
        print(row)