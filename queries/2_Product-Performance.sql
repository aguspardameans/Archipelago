WITH product_sales AS (
		-- Aggregate total revenue and units sold per product (all time, completed orders only)
		SELECT
			p.id,
			p.name,
			p.category,
			SUM(oi.quantity) AS total_units_sold,
			SUM(oi.quantity * oi.unit_price) AS total_revenue
		FROM products p
		JOIN order_items oi ON p.id = oi.product_id
		JOIN orders o ON oi.order_id = o.id
		WHERE o.status = 'completed'
		GROUP BY p.id, p.name, p.category
	),

	category_ranked AS (
		-- Add ranking and revenue share within category
		SELECT
			*,
			RANK() OVER (
				PARTITION BY category
				ORDER BY total_revenue DESC
			) AS revenue_rank_in_category,

			PERCENT_RANK() OVER (
				PARTITION BY category
				ORDER BY total_revenue DESC
			) AS revenue_percent_rank,

			SUM(total_revenue) OVER (
				PARTITION BY category
			) AS category_total_revenue
		FROM product_sales
	),

	monthly_revenue AS (
		-- Revenue per product per month (completed orders only)
		SELECT
			p.id,
			DATE_TRUNC('month', o.order_date) AS revenue_month,
			SUM(oi.quantity * oi.unit_price) AS monthly_revenue
		FROM products p
		JOIN order_items oi ON p.id = oi.product_id
		JOIN orders o ON oi.order_id = o.id
		WHERE o.status = 'completed'
		GROUP BY p.id, revenue_month
	),

	last_two_months AS (
		-- Identify last completed month and previous month dynamically
		SELECT
			MAX(revenue_month) AS last_month,
			MAX(revenue_month) - INTERVAL '1 month' AS previous_month
		FROM monthly_revenue
	),

	mom_comparison AS (
		-- Compare last month vs previous month revenue per product
		SELECT
			m.id,
			SUM(
				CASE WHEN m.revenue_month = l.last_month 
					 THEN m.monthly_revenue ELSE 0 END
			) AS last_month_revenue,

			SUM(
				CASE WHEN m.revenue_month = l.previous_month 
					 THEN m.monthly_revenue ELSE 0 END
			) AS previous_month_revenue
		FROM monthly_revenue m
		CROSS JOIN last_two_months l
		GROUP BY m.id
	)

	SELECT
		cr.name AS product_name,
		cr.category,
		cr.total_units_sold,
		cr.total_revenue,

		cr.revenue_rank_in_category,

		ROUND(
			cr.total_revenue 
			/ NULLIF(cr.category_total_revenue, 0) * 100,
			2
		) AS percentage_of_category_revenue,

		ROUND(
			(mc.last_month_revenue - mc.previous_month_revenue)
			/ NULLIF(mc.previous_month_revenue, 0) * 100,
			2
		) AS month_over_month_percentage_change,

		CASE 
			WHEN cr.revenue_percent_rank <= 0.20 
			THEN 'Top 20%'
			ELSE 'Normal'
		END AS top_20_percent_flag

	FROM category_ranked cr
	LEFT JOIN mom_comparison mc ON cr.id = mc.id

	-- Only include products with at least one sale
	WHERE cr.total_units_sold > 0

	ORDER BY cr.category, cr.revenue_rank_in_category;
	ORDER BY cr.category, cr.revenue_rank_in_category;