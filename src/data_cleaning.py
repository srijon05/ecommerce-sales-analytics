import pandas as pd
import numpy as np

RAW = "data/raw"
CLEAN = "data/cleaned"

def clean_customers():
    df = pd.read_csv(f"{RAW}/customers.csv")

    # 1. Duplicates: entered twice, Keep the first occurrence.
    before = len(df)
    df = df.drop_duplicates(subset="customer_id", keep="first")
    print(f"[customers] removed {before - len(df)} duplicate rows")

    # 2. Missing gender: Unknown' rather than dropping the customer 
    df["gender"] = df["gender"].fillna("Unknown")

    # 3. Invalid age (negative): isn't critical to most downstream analysis, so we set it to NaN
    df.loc[(df["age"] < 10) | (df["age"] > 100), "age"] = np.nan

    # 4. Data types
    df["signup_date"] = pd.to_datetime(df["signup_date"])

    df.to_csv(f"{CLEAN}/customers_clean.csv", index=False)
    print(f"[customers] final row count: {len(df):,}")
    return df

def clean_products():
    df = pd.read_csv(f"{RAW}/products.csv")

    before = len(df)
    df = df.drop_duplicates(subset="product_id", keep="first")
    print(f"[products] removed {before - len(df)} duplicate rows")

    neg_mask = df["selling_price"] < 0
    print(f"[products] fixed {neg_mask.sum()} negative selling_price values")
    df.loc[neg_mask, "selling_price"] = df.loc[neg_mask, "selling_price"].abs()

    df["price_flag_below_cost"] = df["selling_price"] < df["cost_price"]

    df.to_csv(f"{CLEAN}/products_clean.csv", index=False)
    print(f"[products] final row count: {len(df):,}")
    return df


def clean_orders():
    df = pd.read_csv(f"{RAW}/orders.csv")

    before = len(df)
    df = df.drop_duplicates(subset="order_id", keep="first")
    print(f"[orders] removed {before - len(df)} duplicate rows")

    df["payment_method"] = df["payment_method"].fillna("Unknown")

    df["order_date"] = pd.to_datetime(df["order_date"])
    df["discount"] = df["discount"].clip(lower=0, upper=1)  # discount is a 0-1 fraction

    df.to_csv(f"{CLEAN}/orders_clean.csv", index=False)
    print(f"[orders] final row count: {len(df):,}")
    return df


def clean_order_items(valid_order_ids, valid_product_ids):
    df = pd.read_csv(f"{RAW}/order_items.csv")

    before = len(df)
    df = df.drop_duplicates(subset="order_item_id", keep="first")

    zero_qty = (df["quantity"] <= 0).sum()
    df = df[df["quantity"] > 0]

    orphans = ~df["order_id"].isin(valid_order_ids) | ~df["product_id"].isin(valid_product_ids)
    df = df[~orphans]

    print(f"[order_items] removed {before - len(df)} rows "
          f"({zero_qty} zero-quantity, {orphans.sum()} orphaned)")

    df["unit_price"] = df["unit_price"].abs()

    df.to_csv(f"{CLEAN}/order_items_clean.csv", index=False)
    print(f"[order_items] final row count: {len(df):,}")
    return df


if __name__ == "__main__":
    customers = clean_customers()
    products = clean_products()
    orders = clean_orders()
    clean_order_items(
        valid_order_ids=set(orders["order_id"]),
        valid_product_ids=set(products["product_id"]),
    )
    print("\nCleaning complete. Cleaned files are in data/cleaned/")