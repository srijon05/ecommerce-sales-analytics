import numpy as np
import pandas as pd
from faker import Faker
from datetime import datetime, timedelta
import random

# CONFIG
SEED = 42
N_CUSTOMERS = 5000
N_PRODUCTS = 800
N_ORDERS = 25000
START_DATE = datetime(2023, 1, 1)
END_DATE = datetime(2026, 8, 31)

OUT_DIR = "data/raw"

random.seed(SEED)
np.random.seed(SEED)
fake = Faker("en_IN")
Faker.seed(SEED)

# CUSTOMERS
INDIAN_STATES_CITIES = {
    "Maharashtra": ["Mumbai", "Pune", "Nagpur"],
    "Karnataka": ["Bengaluru", "Mysuru", "Mangaluru"],
    "Delhi": ["New Delhi"],
    "Tamil Nadu": ["Chennai", "Coimbatore", "Madurai"],
    "West Bengal": ["Kolkata", "Durgapur", "Siliguri"],
    "Telangana": ["Hyderabad", "Warangal"],
    "Gujarat": ["Ahmedabad", "Surat", "Vadodara"],
    "Uttar Pradesh": ["Lucknow", "Kanpur", "Noida"],
    "Rajasthan": ["Jaipur", "Udaipur"],
    "Kerala": ["Kochi", "Thiruvananthapuram"],
}
states = list(INDIAN_STATES_CITIES.keys())

def random_signup_date():
    delta = END_DATE - START_DATE
    return (START_DATE + timedelta(days=random.randint(0, delta.days))).date()

customers = []
for cid in range(1, N_CUSTOMERS + 1):
    state = random.choice(states)
    city = random.choice(INDIAN_STATES_CITIES[state])
    gender = random.choice(["Male", "Female", "Other"])
    age = int(np.clip(np.random.normal(32, 9), 16, 75))
    customers.append({
        "customer_id": cid,
        "name": fake.name(),
        "gender": gender,
        "age": age,
        "city": city,
        "state": state,
        "signup_date": random_signup_date(),
    })

customers_df = pd.DataFrame(customers)

# Inject realistic messiness
messy_idx = customers_df.sample(frac=0.02, random_state=SEED).index
customers_df.loc[messy_idx[:len(messy_idx)//2], "gender"] = None
customers_df.loc[messy_idx[len(messy_idx)//2:], "age"] = -1  # invalid ages to catch in cleaning
dup_rows = customers_df.sample(n=15, random_state=SEED)
customers_df = pd.concat([customers_df, dup_rows], ignore_index=True)

# PRODUCTS
CATEGORIES = {
    "Electronics": ["Apple", "Samsung", "Sony", "OnePlus", "Dell"],
    "Fashion": ["Zara", "H&M", "Levis", "Allen Solly", "Puma"],
    "Home & Kitchen": ["Prestige", "Philips", "Milton", "IKEA"],
    "Beauty": ["Nivea", "Lakme", "Mamaearth", "LOreal"],
    "Sports": ["Nike", "Adidas", "Decathlon", "Yonex"],
    "Books": ["Penguin", "HarperCollins", "Scholastic"],
    "Groceries": ["Tata", "Amul", "Nestle", "ITC"],
}

products = []
pid = 1
for _ in range(N_PRODUCTS):
    category = random.choice(list(CATEGORIES.keys()))
    brand = random.choice(CATEGORIES[category])
    cost_price = round(np.random.uniform(50, 25000), 2)
    markup = np.random.uniform(1.15, 1.8)
    selling_price = round(cost_price * markup, 2)
    products.append({
        "product_id": pid,
        "product_name": f"{brand} {fake.word().capitalize()} {category[:3]}{pid}",
        "category": category,
        "brand": brand,
        "cost_price": cost_price,
        "selling_price": selling_price,
    })
    pid += 1

products_df = pd.DataFrame(products)
# a few invalid prices to clean later
bad_idx = products_df.sample(n=8, random_state=SEED).index
products_df.loc[bad_idx, "selling_price"] = -products_df.loc[bad_idx, "selling_price"]

# ORDERS + ORDER_ITEMS (generated together so line items match dates)
PAYMENT_METHODS = ["UPI", "Credit Card", "Debit Card", "Cash on Delivery", "Net Banking"]
STATUSES = ["Delivered", "Delivered", "Delivered", "Delivered", "Cancelled", "Returned", "Pending"]

# skew orders towards a subset of "loyal" customers for realistic RFM later
customer_ids = customers_df["customer_id"].unique()
loyalty_weights = np.random.pareto(a=2.0, size=len(customer_ids)) + 0.1
loyalty_weights = loyalty_weights / loyalty_weights.sum()

orders = []
order_items = []
oi_id = 1

for oid in range(1, N_ORDERS + 1):
    cust_id = int(np.random.choice(customer_ids, p=loyalty_weights))
    days_offset = random.randint(0, (END_DATE - START_DATE).days)
    order_date = (START_DATE + timedelta(days=days_offset)).date()
    payment = random.choice(PAYMENT_METHODS)
    discount = round(random.choice([0, 0, 0, 5, 10, 15, 20, 25]) / 100, 2)
    status = random.choice(STATUSES)

    orders.append({
        "order_id": oid,
        "customer_id": cust_id,
        "order_date": order_date,
        "payment_method": payment,
        "discount": discount,
        "status": status,
    })

    n_items = random.choice([1, 1, 2, 2, 3, 4])
    chosen_products = random.sample(range(1, N_PRODUCTS + 1), k=min(n_items, N_PRODUCTS))
    for prod_id in chosen_products:
        qty = random.choice([1, 1, 1, 2, 2, 3])
        unit_price = products_df.loc[products_df["product_id"] == prod_id, "selling_price"].values[0]
        order_items.append({
            "order_item_id": oi_id,
            "order_id": oid,
            "product_id": prod_id,
            "quantity": qty,
            "unit_price": abs(round(unit_price, 2)),
        })
        oi_id += 1

orders_df = pd.DataFrame(orders)
order_items_df = pd.DataFrame(order_items)

null_pm_idx = orders_df.sample(frac=0.015, random_state=SEED).index
orders_df.loc[null_pm_idx, "payment_method"] = None
bad_qty_idx = order_items_df.sample(n=10, random_state=SEED).index
order_items_df.loc[bad_qty_idx, "quantity"] = 0


# SAVE
customers_df.to_csv(f"{OUT_DIR}/customers.csv", index=False)
products_df.to_csv(f"{OUT_DIR}/products.csv", index=False)
orders_df.to_csv(f"{OUT_DIR}/orders.csv", index=False)
order_items_df.to_csv(f"{OUT_DIR}/order_items.csv", index=False)

print("Generated:")
print(f"  customers.csv    -> {len(customers_df):,} rows")
print(f"  products.csv     -> {len(products_df):,} rows")
print(f"  orders.csv       -> {len(orders_df):,} rows")
print(f"  order_items.csv  -> {len(order_items_df):,} rows")