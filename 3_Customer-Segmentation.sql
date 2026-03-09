WITH customer_metrics AS (
		-- Step 1: Calculate base metrics from completed orders only
		SELECT
			c.id,
			c.name,
			c.email,
			MAX(o.order_date) AS last_order_date,
			COUNT(o.id) AS frequency,
			SUM(o.total_amount) AS monetary
		FROM customers c
		JOIN orders o 
			ON c.id = o.customer_id
		WHERE o.status = 'completed'
		GROUP BY c.id, c.name, c.email
	),

	recency_calc AS (
		-- Step 2: Calculate recency in days
		SELECT
			*,
			EXTRACT(DAY FROM CURRENT_DATE - last_order_date)::INT AS recency_days
		FROM customer_metrics
	),

	scored AS (
		-- Step 3: Apply scoring logic
		SELECT
			*,
			
			-- Recency Score (lower days = better)
			CASE
				WHEN recency_days <= 30 THEN 5
				WHEN recency_days <= 90 THEN 4
				WHEN recency_days <= 180 THEN 3
				WHEN recency_days <= 365 THEN 2
				ELSE 1
			END AS recency_score,

			-- Frequency Score
			CASE
				WHEN frequency >= 20 THEN 5
				WHEN frequency >= 10 THEN 4
				WHEN frequency >= 5 THEN 3
				WHEN frequency >= 3 THEN 2
				ELSE 1
			END AS frequency_score,

			-- Monetary Score using NTILE (top 20% = 5)
			NTILE(5) OVER (ORDER BY monetary DESC) AS monetary_score

		FROM recency_calc
	),

	final_segment AS (
		-- Step 4: Combine scores and assign segment
		SELECT
			name,
			email,
			recency_days,
			frequency,
			monetary,

			(recency_score + frequency_score + monetary_score) AS rfm_score,

			CASE
				WHEN (recency_score + frequency_score + monetary_score) >= 12 THEN 'Champions'
				WHEN (recency_score + frequency_score + monetary_score) BETWEEN 9 AND 11 THEN 'Loyal'
				WHEN (recency_score + frequency_score + monetary_score) BETWEEN 6 AND 8 THEN 'At Risk'
				ELSE 'Lost'
			END AS segment

		FROM scored
	)

	SELECT *
	FROM final_segment
	ORDER BY rfm_score DESC;

