WITH completed_orders_2024 AS (
		-- Filter only completed orders in 2024 to reduce dataset early (performance optimization)
		SELECT *
		FROM orders
		WHERE status = 'completed'
		  AND order_date >= '2024-01-01'
		  AND order_date < '2025-01-01'
	),

	first_order AS (
		-- Determine each customer's first completed order month in 2024
		SELECT
			customer_id,
			DATE_TRUNC('month', MIN(order_date)) AS cohort_month
		FROM completed_orders_2024
		GROUP BY customer_id
	),

	cohort_activity AS (
		-- Get monthly activity and revenue for each customer in their cohort
		SELECT
			f.cohort_month,
			o.customer_id,
			DATE_TRUNC('month', o.order_date) AS activity_month,
			SUM(o.total_amount) AS revenue
		FROM first_order f
		JOIN completed_orders_2024 o
			ON f.customer_id = o.customer_id
		GROUP BY f.cohort_month, o.customer_id, activity_month
	),

	cohort_summary AS (
		-- Aggregate cohort-level metrics
		SELECT
			cohort_month,
			COUNT(DISTINCT customer_id) AS new_customers,
			SUM(
				CASE 
					WHEN activity_month = cohort_month 
					THEN revenue 
					ELSE 0 
				END
			) AS first_month_revenue,
			COUNT(
				DISTINCT CASE 
					WHEN activity_month = cohort_month + INTERVAL '1 month'
					THEN customer_id
				END
			) AS retained_next_month
		FROM cohort_activity
		GROUP BY cohort_month
	)

	SELECT
		cohort_month,
		new_customers,
		first_month_revenue,

		-- Running total of customers acquired up to that month
		SUM(new_customers) OVER (ORDER BY cohort_month) 
			AS running_total_customers,

		-- Retention rate calculation
		ROUND(
			retained_next_month::NUMERIC 
			/ NULLIF(new_customers, 0) * 100,
			2
		) AS retention_rate_percentage

	FROM cohort_summary
	ORDER BY cohort_month;