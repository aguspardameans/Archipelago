package queries

var CohortQuery = `
SELECT
DATE_TRUNC('month', MIN(order_date)) AS cohort_month,
COUNT(DISTINCT customer_id) AS new_customers
FROM orders
WHERE status='completed'
GROUP BY cohort_month
ORDER BY cohort_month;
`
