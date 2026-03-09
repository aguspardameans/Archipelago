WITH date_series AS (
		-- Generate continuous 90-day date range
		SELECT generate_series(
			CURRENT_DATE - INTERVAL '89 days',
			CURRENT_DATE,
			INTERVAL '1 day'
		)::date AS report_date
	),

	daily_sales AS (
		-- Aggregate daily completed booking data
		SELECT
			order_date::date AS order_day,
			COUNT(*) AS total_orders,
			SUM(total_amount) AS total_revenue
		FROM orders
		WHERE status = 'completed'
		  AND order_date >= CURRENT_DATE - INTERVAL '90 days'
		GROUP BY order_day
	),

	merged AS (
		-- Left join to include days with zero orders
		SELECT
			ds.report_date,
			COALESCE(d.total_orders, 0) AS total_orders,
			COALESCE(d.total_revenue, 0) AS total_revenue
		FROM date_series ds
		LEFT JOIN daily_sales d
			ON ds.report_date = d.order_day
	),

	moving_avg_calc AS (
		-- Calculate 7-day moving averages
		SELECT
			report_date,
			total_orders,
			total_revenue,

			AVG(total_revenue) OVER (
				ORDER BY report_date
				ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
			) AS revenue_7d_avg,

			AVG(total_orders) OVER (
				ORDER BY report_date
				ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
			) AS orders_7d_avg

		FROM merged
	)

	SELECT
		report_date,
		total_orders,
		total_revenue,
		ROUND(revenue_7d_avg, 2) AS revenue_7d_avg,
		ROUND(orders_7d_avg, 2) AS orders_7d_avg,

		-- % difference from 7-day average
		ROUND(
			(total_revenue - revenue_7d_avg)
			/ NULLIF(revenue_7d_avg, 0) * 100,
			2
		) AS revenue_vs_avg_percentage,

		TO_CHAR(report_date, 'Day') AS day_of_week,

		-- Anomaly flag (>30% deviation)
		CASE
			WHEN revenue_7d_avg = 0 THEN 'No Baseline'
			WHEN total_revenue > revenue_7d_avg * 1.30 THEN 'High Spike'
			WHEN total_revenue < revenue_7d_avg * 0.70 THEN 'Low Drop'
			ELSE 'Normal'
		END AS anomaly_flag

	FROM moving_avg_calc
	ORDER BY report_date;