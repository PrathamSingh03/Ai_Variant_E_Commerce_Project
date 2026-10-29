# Project notes (cleaned working log)

Team-based course project (Data Analyst bootcamp). Same five KPIs answered in four tools (Excel, Power BI, SQL, Tableau) and cross-checked.
Dataset: Olist Brazilian e-commerce, 9 CSV files (about 45 MB zipped).

## Common join columns

| Column | Connects |
| --- | --- |
| order_id | orders, order_items, order_payments, order_reviews |
| product_id | order_items, products |
| seller_id | order_items, sellers |
| customer_id | orders, customers |
| zip_code_prefix | customers / sellers to geolocation |
| product_category_name | products, product_category_name_translation |

## Known data issues (confirmed from the files)

- `olist_geolocation_dataset`: 261,831 exact duplicate rows in my cleaning log (261,836 counted in the SQL copy). See the Excel README for the rule actually saved in the workbook.
- `olist_products_dataset`: 610 rows with no `product_category_name`; set to `unknown`, not deleted.
- `olist_orders_dataset`: 2,965 orders have no delivery date (never delivered). Excluded only from delivery-time KPIs (3 and 5).
- `olist_order_payments_dataset`: 103,886 rows for 99,440 distinct orders (installments). Count orders with a distinct count.
- `olist_order_reviews_dataset`: some orders have more than one review (547 in the SQL copy).

## Data model

Excel Data Model: 9 relationships. Power BI: 9 relationships. Tableau: 8 relationships (Relationships feature, not joins).
The raw geolocation table is intentionally not connected in Excel and Power BI; customers and sellers each use their own zip lookup table.
Details: [`excel/README.md`](../excel/README.md), [`powerbi/README.md`](../powerbi/README.md), [`tableau/README.md`](../tableau/README.md).

## KPI results by tool

| KPI | Excel | Power BI | SQL | Tableau |
| --- | --- | --- | --- | --- |
| 1 Weekday / weekend orders | 76,593 / 22,847 | 76,593 / 22,847 | 76,593 / 22,847 | 76,594 / 22,847 |
| 1 Avg payment weekday / weekend | 154.44 / 152.95 | 154.44 / 152.95 (the chart label for weekend reads 156.54; see open items) | 154.44 / 152.95 | n/a on the dashboard |
| 2 5-star credit card orders | 42,581 (superseded) | 43,981 | 43,981 | 43,981 |
| 3 pet_shop avg delivery days | 11.23 | 11.31 | 11.31 | 11.31 |
| 4 Sao Paulo avg price / payment | 107.53 / 135.83 | 112.58 / 138.74 | 112.58 / 138.74 | 107.5 / 135.8 |
| 5 Avg shipping days, score 1 to 5 | 21.32 / 16.63 / 14.26 / 12.31 / 10.68 | 21.25 / 16.61 / 14.20 / 12.25 / 10.63 | 21.25 / 16.61 / 14.20 / 12.25 / 10.63 | 21.25 / 16.60 / 14.21 / 12.25 / 10.62 |

Why the tools differ is explained in the main README (results section).

## Quality log

- All five KPI results were compared across tools before sign-off.
- KPI 2 was the one real discrepancy: Excel's `COUNTIFS` on a merged sheet gave 42,581; the SQL `COUNT(DISTINCT)`, DAX `DISTINCTCOUNT` and Tableau count agreed on 43,981. Excel was superseded.

## Open items

- Power BI dashboard: On-Time Rate card shows a delivered-rows count (12K) instead of a rate; the payment-type donut needs review.
- Excel dashboard: the "count of orders by payment method" chart needs fixing.
- Power BI KPI 1 weekend average label reads 156.54 where the other tools give 152.95.
- Excel KPI 3 (11.23) could not be reproduced independently; the other three tools give 11.31.
- Currency: the data is in R$; some project files show the rupee symbol.
