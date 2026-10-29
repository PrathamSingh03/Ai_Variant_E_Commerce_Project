# Power BI: calculated columns and measures

Copied from the project `.pbix`. The KPI 2 measures are **mine**; the others were written by other course participants and are shown for completeness.

## Calculated columns

```dax
-- orders
DayType =
IF(WEEKDAY('olist_orders_dataset'[order_purchase_timestamp], 2) >= 6, "Weekend", "Weekday")

Delivery_Days =
IF(
    NOT(ISBLANK(olist_orders_dataset[order_delivered_customer_date])) &&
    olist_orders_dataset[order_status] = "delivered",
    DATEDIFF(olist_orders_dataset[order_purchase_timestamp],
             olist_orders_dataset[order_delivered_customer_date], DAY),
    BLANK()
)

[delivery days 1] = DATEDIFF(olist_orders_dataset[order_purchase_timestamp], olist_orders_dataset[order_delivered_customer_date], DAY)
[shipping Days]   = DATEDIFF(olist_orders_dataset[order_purchase_timestamp], olist_orders_dataset[order_delivered_customer_date], DAY)
[Avg Shipping Days] = AVERAGEX(FILTER(olist_orders_dataset, olist_orders_dataset[Shipping Days] >= 0), olist_orders_dataset[Shipping Days])

-- customers
City Group =
IF(LOWER(olist_customers_dataset[customer_city]) = "sao paulo", "São Paulo", "All Other Cities")

-- order_items
[Total Revenue] = SUM(olist_order_items_dataset[price]) + SUM(olist_order_items_dataset[freight_value])
```

## Measures

### KPI 1: weekday vs weekend

```dax
Weekday Orders =
CALCULATE(DISTINCTCOUNT('olist_order_payments_dataset'[order_id]), 'olist_orders_dataset'[DayType] = "Weekday")

Weekend Orders =
CALCULATE(DISTINCTCOUNT('olist_order_payments_dataset'[order_id]), 'olist_orders_dataset'[DayType] = "Weekend")

Weekday Avg Payment =
CALCULATE(AVERAGE('olist_order_payments_dataset'[payment_value]), 'olist_orders_dataset'[DayType] = "Weekday")

Weekend Avg Payment =
CALCULATE(AVERAGE('olist_order_payments_dataset'[payment_value]), 'olist_orders_dataset'[DayType] = "Weekend")

Total Orders = DISTINCTCOUNT('olist_order_payments_dataset'[order_id])
```

### KPI 2: 5-star orders paid by credit card (mine)

`CROSSFILTER(..., BOTH)` lets the reviews and payments tables filter each other through `orders`,
so each order is counted once with `DISTINCTCOUNT`.

```dax
KPI2_ReviewScore5_CreditCard =
CALCULATE(
    DISTINCTCOUNT(olist_orders_dataset[order_id]),
    CROSSFILTER(olist_order_reviews_dataset[order_id], olist_orders_dataset[order_id], BOTH),
    CROSSFILTER(olist_order_payments_dataset[order_id], olist_orders_dataset[order_id], BOTH),
    olist_order_reviews_dataset[review_score] = 5,
    olist_order_payments_dataset[payment_type] = "credit_card"
)

KPI2_AllPaymentTypes_5Star =
CALCULATE(
    DISTINCTCOUNT(olist_orders_dataset[order_id]),
    CROSSFILTER(olist_order_reviews_dataset[order_id], olist_orders_dataset[order_id], BOTH),
    CROSSFILTER(olist_order_payments_dataset[order_id], olist_orders_dataset[order_id], BOTH),
    olist_order_reviews_dataset[review_score] = 5
)

KPI2_ByScore_CreditCard =
CALCULATE(
    DISTINCTCOUNT(olist_orders_dataset[order_id]),
    CROSSFILTER(olist_order_reviews_dataset[order_id], olist_orders_dataset[order_id], BOTH),
    CROSSFILTER(olist_order_payments_dataset[order_id], olist_orders_dataset[order_id], BOTH),
    olist_order_payments_dataset[payment_type] = "credit_card"
)

KPI2_PercentOfTotal =
DIVIDE([KPI2_ReviewScore5_CreditCard], DISTINCTCOUNT(olist_orders_dataset[order_id]))
```

### KPI 3: pet_shop delivery days

```dax
Pet_Shop_Avg_Delivery_Days =
VAR PetShopOrderIDs =
    CALCULATETABLE(
        VALUES(olist_order_items_dataset[order_id]),
        olist_products_dataset[product_category_name] = "pet_shop"
    )
RETURN
    CALCULATE(
        AVERAGEX(
            olist_orders_dataset,
            DATEDIFF(olist_orders_dataset[order_purchase_timestamp],
                     olist_orders_dataset[order_delivered_customer_date], DAY)
        ),
        olist_orders_dataset[order_status] = "delivered",
        NOT(ISBLANK(olist_orders_dataset[order_delivered_customer_date])),
        olist_orders_dataset[order_id] IN PetShopOrderIDs
    )

Average delivery days = AVERAGE(olist_orders_dataset[delivery days 1])
```

### KPI 4: Sao Paulo price and payment (per-order averages)

```dax
Average Price =
AVERAGEX(
    FILTER(
        VALUES(olist_orders_dataset[order_id]),
        CALCULATE(COUNTROWS(olist_order_items_dataset)) > 0
            && CALCULATE(COUNTROWS(olist_order_payments_dataset)) > 0
    ),
    CALCULATE(AVERAGE(olist_order_items_dataset[price]))
)

Average Payment =
AVERAGEX(
    FILTER(
        VALUES(olist_orders_dataset[order_id]),
        CALCULATE(COUNTROWS(olist_order_items_dataset)) > 0
            && CALCULATE(COUNTROWS(olist_order_payments_dataset)) > 0
    ),
    CALCULATE(AVERAGE(olist_order_payments_dataset[payment_value]))
)

SP Order Count = DISTINCTCOUNT(olist_orders_dataset[order_id])
```

### KPI 5: shipping days

```dax
KPI5_AvgShippingDays =
CALCULATE(
    AVERAGE(olist_orders_dataset[Shipping Days]),
    CROSSFILTER(olist_order_reviews_dataset[order_id], olist_orders_dataset[order_id], BOTH)
)
```
