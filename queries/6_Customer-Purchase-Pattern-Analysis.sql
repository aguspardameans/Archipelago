WITH completed_orders_2024 AS (
    -- Step 1: Filter only completed bookings in 2024
    SELECT
        o.id,
        o.customer_id,
        o.order_date,
        o.total_amount
    FROM orders o
    WHERE o.status = 'completed'
      AND o.order_date >= '2024-01-01'
      AND o.order_date < '2025-01-01'
),

customer_orders AS (
    -- Step 2: Add ordering sequence per customer
    SELECT
        c.id AS customer_id,
        c.name,
        c.email,
        o.id AS order_id,
        o.order_date,
        o.total_amount,
        ROW_NUMBER() OVER (
            PARTITION BY c.id
            ORDER BY o.order_date
        ) AS order_sequence,
        COUNT(*) OVER (
            PARTITION BY c.id
        ) AS total_orders
    FROM customers c
    JOIN completed_orders_2024 o
        ON c.id = o.customer_id
),

order_intervals AS (
    -- Step 3: Calculate days between orders using LAG
    SELECT
        *,
        EXTRACT(DAY FROM
            order_date - LAG(order_date) OVER (
                PARTITION BY customer_id
                ORDER BY order_date
            )
        ) AS days_between_orders
    FROM customer_orders
),

category_preference AS (
    -- Step 4: Determine most frequently purchased category per customer
    SELECT
        o.customer_id,
        p.category,
        COUNT(*) AS category_count,
        RANK() OVER (
            PARTITION BY o.customer_id
            ORDER BY COUNT(*) DESC
        ) AS category_rank
    FROM completed_orders_2024 o
    JOIN order_items oi ON o.id = oi.order_id
    JOIN products p ON oi.product_id = p.id
    GROUP BY o.customer_id, p.category
),

category_top AS (
    SELECT
        customer_id,
        category AS most_frequent_category
    FROM category_preference
    WHERE category_rank = 1
),

customer_summary AS (
    -- Step 5: Aggregate customer-level metrics
    SELECT
        customer_id,
        name,
        email,
        MAX(total_orders) AS total_orders,
        AVG(days_between_orders) AS avg_days_between_orders,
        STDDEV(days_between_orders) AS stddev_days_between_orders,
        AVG(total_amount) AS avg_order_value,
        MIN(order_date) AS first_order_date,
        MAX(order_date) AS last_order_date
    FROM order_intervals
    GROUP BY customer_id, name, email
    HAVING MAX(total_orders) >= 3
),

trend_calc AS (
    -- Step 6: Compare first 3 vs last 3 orders average value
    SELECT
        customer_id,
        AVG(CASE WHEN order_sequence <= 3 THEN total_amount END) AS first_3_avg,
        AVG(CASE WHEN order_sequence > total_orders - 3 THEN total_amount END) AS last_3_avg
    FROM customer_orders
    GROUP BY customer_id, total_orders
)

SELECT
    cs.name,
    cs.email,
    cs.total_orders,
    ROUND(cs.avg_days_between_orders, 2) AS avg_days_between_orders,
    ROUND(cs.stddev_days_between_orders, 2) AS stddev_days_between_orders,
    ct.most_frequent_category,
    ROUND(cs.avg_order_value, 2) AS avg_order_value,

    CASE
        WHEN tc.last_3_avg > tc.first_3_avg THEN 'Increasing'
        ELSE 'Decreasing'
    END AS trend_indicator,

    EXTRACT(DAY FROM (cs.last_order_date - cs.first_order_date)) 
        AS customer_lifetime_days

FROM customer_summary cs
JOIN trend_calc tc ON cs.customer_id = tc.customer_id
LEFT JOIN category_top ct ON cs.customer_id = ct.customer_id

ORDER BY cs.total_orders DESC;
