WITH sales_90_days AS (
		-- Step 1: Calculate units sold in last 90 days (completed bookings only)
		SELECT
			oi.product_id,
			SUM(oi.quantity) AS units_sold_90d,
			MAX(o.order_date) AS last_order_date
		FROM order_items oi
		JOIN orders o ON oi.order_id = o.id
		WHERE o.status = 'completed'
		  AND o.order_date >= CURRENT_DATE - INTERVAL '90 days'
		GROUP BY oi.product_id
	),

	product_base AS (
		-- Step 2: Combine product info with sales data
		SELECT
			p.id,
			p.name,
			p.category,
			p.stock_quantity,
			COALESCE(s.units_sold_90d, 0) AS units_sold_90d,
			s.last_order_date
		FROM products p
		LEFT JOIN sales_90_days s
			ON p.id = s.product_id
	),

	calculated_metrics AS (
		-- Step 3: Calculate daily rate and estimated days until stockout
		SELECT
			*,
			(units_sold_90d / 90.0) AS avg_daily_sales_rate,

			CASE 
				WHEN units_sold_90d = 0 THEN NULL
				ELSE stock_quantity / NULLIF((units_sold_90d / 90.0), 0)
			END AS estimated_days_until_stockout
		FROM product_base
	),

	final_status AS (
		-- Step 4: Apply stock classification logic
		SELECT
			*,
			CASE
				WHEN units_sold_90d = 0 AND stock_quantity > 0 THEN 'Dead Stock'
				WHEN estimated_days_until_stockout IS NULL THEN 'Dead Stock'
				WHEN estimated_days_until_stockout < 7 THEN 'Critical'
				WHEN estimated_days_until_stockout < 30 THEN 'Low'
				WHEN estimated_days_until_stockout <= 90 THEN 'Adequate'
				ELSE 'Overstocked'
			END AS stock_status,

			CASE
				WHEN units_sold_90d = 0 THEN 0
				ELSE GREATEST(
					CEIL((avg_daily_sales_rate * 45) - stock_quantity),
					0
				)
			END AS reorder_recommendation
		FROM calculated_metrics
	)

	SELECT
		name AS product_name,
		category,
		stock_quantity AS current_stock,
		units_sold_90d,
		ROUND(avg_daily_sales_rate, 2) AS avg_daily_sales_rate,
		ROUND(estimated_days_until_stockout, 2) AS estimated_days_until_stockout,
		last_order_date,
		stock_status,
		reorder_recommendation

	FROM final_status

	-- Include products with stock > 0 OR sold in last 90 days
	WHERE stock_quantity > 0
	   OR units_sold_90d > 0

	-- Sort by priority, then urgency
	ORDER BY
		CASE stock_status
			WHEN 'Critical' THEN 1
			WHEN 'Low' THEN 2
			WHEN 'Adequate' THEN 3
			WHEN 'Overstocked' THEN 4
			WHEN 'Dead Stock' THEN 5
			ELSE 6
		END,
		estimated_days_until_stockout NULLS LAST;