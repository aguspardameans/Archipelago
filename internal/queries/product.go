package queries

var ProductPerformanceQuery = `
SELECT
p.name,
p.category,
SUM(oi.quantity) AS units_sold,
SUM(oi.quantity*oi.unit_price) AS revenue
FROM products p
JOIN order_items oi ON p.id=oi.product_id
JOIN orders o ON o.id=oi.order_id
WHERE o.status='completed'
GROUP BY p.name,p.category
ORDER BY revenue DESC;
`
