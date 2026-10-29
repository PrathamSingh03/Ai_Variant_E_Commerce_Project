# Excel module (Power Query + Data Model + PivotTables)

> **The workbook is not in this repository.** It is about 126 MB (over GitHub's 100 MB file limit) and
> contains the raw dataset. What is here instead: the Power Query cleaning code
> ([`power_query_cleaning.m`](power_query_cleaning.m)), the cleaning decisions, the data model and the KPI method notes below.
> [TODO: optionally attach a trimmed workbook (KPI sheets only, no raw data) as a GitHub Release.]

## What I did in this module

1. **Cleaned and loaded all 9 tables** with Power Query (data types, text fixes, missing values).
2. **Built the Excel Data Model (Power Pivot)**: 9 source tables plus 2 helper lookup tables, 9 relationships.
3. **Reviewed the Excel-stage KPI results** against independently pre-checked figures before they went into the final workbook.

## Cleaning decisions (one row per table)

| Table | What I did | Why |
| --- | --- | --- |
| customers | Types only | No nulls, no duplicates |
| geolocation | Imported as UTF-8; replaced the `sao paulo` text variants with `são paulo`; removed duplicates on `geolocation_city` (see note below) | Raw table has ~1M rows and many rows per zip prefix, so it cannot sit on the "one" side of a relationship. No KPI uses it |
| order_items | Types only | Several rows per order is normal (one row per item) |
| order_payments | Types only | More rows (103,886) than orders (99,440) because of installment splits, so orders must be counted with a distinct count |
| order_reviews | Types only; blank comment title / message left as they are | A blank comment means "no comment written", not missing data |
| orders | Removed fully blank rows only; **kept all 99,441 rows and all nulls** | Null delivery dates (2,965) mean "never delivered". Deleting them would remove orders that KPIs 1, 2 and 4 need; filling them would corrupt the delivery-time KPIs |
| products | 610 blank `product_category_name` set to `unknown`; blanks in size / weight / photo columns left blank | The category is used in a join. A weight of 0 g would be wrong; a blank honestly means "unknown" |
| sellers | Types only | Clean |
| product_category_name_translation | Promoted headers | 71 unique rows, clean |
| **Geo_Zip_Lookup** and **Geo_Zip_Lookup (2)** | New tables grouped by zip prefix with average latitude / longitude (6,011 rows each) | Gives a unique key for the customers and sellers relationships |

**Geolocation note.** My cleaning log counts 261,831 exact duplicate rows in the raw geolocation table. The query saved in the
final workbook removes duplicates on `geolocation_city`, which leaves 8,008 rows (raw: 1,000,163). This is lossy, but no KPI uses geolocation.
[TODO: confirm the intended rule; for the exact-duplicate version, remove duplicates across all five columns instead.]

## Data Model (Power Pivot)

| Many side | Column | One side | Column |
| --- | --- | --- | --- |
| order_items | order_id | orders | order_id |
| order_payments | order_id | orders | order_id |
| order_reviews | order_id | orders | order_id |
| orders | customer_id | customers | customer_id |
| order_items | product_id | products | product_id |
| order_items | seller_id | sellers | seller_id |
| products | product_category_name | product_category_name_translation | product_category_name |
| customers | customer_zip_code_prefix | Geo_Zip_Lookup | geolocation_zip_code_prefix |
| sellers | seller_zip_code_prefix | Geo_Zip_Lookup (2) | geolocation_zip_code_prefix |

The raw `olist_geolocation_dataset` is deliberately **not** connected. Excel allows only one filtering path between two tables,
so customers and sellers each use their own copy of the zip lookup. An earlier version had two extra links from the lookup tables back to the raw
geolocation table; they created a hidden second filtering path between customers and sellers and were removed.

## KPI method notes (as built in the workbook)

| KPI | Method | Result in Excel |
| --- | --- | --- |
| 1 Weekday vs weekend | `Day_Type` calculated column on orders; PivotTable from the Data Model with **distinct count of order_id** and average of payment_value; combo chart (bars = orders, line = average payment) | 76,593 weekday / 22,847 weekend orders; average payment 154.44 / 152.95 |
| 2 5-star + credit card | Merged sheet (order_id, review_score, payment_type) and `COUNTIFS` | 42,581 (**superseded**, see the main README, "Data quality lessons") |
| 3 pet_shop delivery days | Power Query merge orders -> items -> products, filter `delivered` and `pet_shop`, average of fractional days | 11.23 days |
| 4 Sao Paulo price / payment | PivotTable from the Data Model, filter `customer_city = sao paulo` | Average price 107.53, average payment 135.83, 15,540 orders |
| 5 Shipping days vs review score | Order-level sheet; orders with several reviews de-duplicated by latest review; undelivered orders and negative durations excluded; PivotTable + parallel `AVERAGEIF` check + `CORREL` | 21.32 days (score 1) to 10.68 days (score 5); correlation -0.334; 95,824 orders |
