# Data

The raw data is **not** stored in this repository.

## Source

**Brazilian E-Commerce Public Dataset by Olist** (Kaggle)
<https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce>

Download the dataset, unzip it, and keep the 9 CSV files in a local folder such as `data/raw/`
(this folder is ignored by `.gitignore`, so the files are never committed).

The dataset covers orders placed on the Olist marketplace between 2016-09-04 and 2018-10-17.
Monetary values are in Brazilian reais (R$).

## The 9 files

| File | Rows | What it contains |
| --- | ---: | --- |
| `olist_orders_dataset.csv` | 99,441 | One row per order: status and purchase / approval / delivery timestamps |
| `olist_customers_dataset.csv` | 99,441 | One row per order-level `customer_id`, city, state, zip prefix |
| `olist_order_items_dataset.csv` | 112,650 | One row per item in an order: product, seller, price, freight |
| `olist_order_payments_dataset.csv` | 103,886 | One row per payment record: type, installments, value (99,440 distinct orders) |
| `olist_order_reviews_dataset.csv` | 99,224 | Review score (1-5) and optional comment per review |
| `olist_products_dataset.csv` | 32,951 | Product category and size / weight attributes |
| `olist_sellers_dataset.csv` | 3,095 | Seller city, state, zip prefix |
| `olist_geolocation_dataset.csv` | 1,000,163 | Latitude / longitude per zip prefix (many rows per zip prefix) |
| `product_category_name_translation.csv` | 71 | Product category name, Portuguese to English |

Row counts were checked on my copy of the data.

## Licence

Check the licence shown on the Kaggle dataset page before reusing the data.
[TODO: confirm the licence text on the Kaggle page and copy it here. I believe it is CC BY-NC-SA 4.0, but I have not verified it.]
