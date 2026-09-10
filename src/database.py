import pandas as pd
from sqlalchemy import create_engine

DB_CONFIG = {
    "user": "root",
    "password": "12082005",
    "host": "localhost",
    "port": 3306,
    "database": "ecommerce_analytics",
}
CLEAN_DIR = "data/cleaned"

TABLES = {
    "customers": f"{CLEAN_DIR}/customers_clean.csv",
    "products": f"{CLEAN_DIR}/products_clean.csv",
    "orders": f"{CLEAN_DIR}/orders_clean.csv",
    "order_items": f"{CLEAN_DIR}/order_items_clean.csv",
}

DROP_COLUMNS = {
    "products": ["price_flag_below_cost"],
}

def get_engine():
    url = (
        f"mysql+pymysql://{DB_CONFIG['user']}:{DB_CONFIG['password']}"
        f"@{DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['database']}"
    )
    return create_engine(url)
def load_all():
    engine = get_engine()
    for table, path in TABLES.items():
        df = pd.read_csv(path)
        for col in DROP_COLUMNS.get(table, []):
            if col in df.columns:
                df = df.drop(columns=col)
        df.to_sql(table, engine, if_exists="append", index=False, method="multi", chunksize=2000)
        print(f"Loaded {len(df):,} rows into `{table}`")

    print("\nAll tables loaded. Run sql/02_data_quality.sql to verify.")

if __name__ == "__main__":
    load_all()