-------------------------------------------------
-- Data with Danny - 8 Week Challenge (Week 1) --
-- https://8weeksqlchallenge.com/case-study-1/ --
----------- SQL code by: Anna Abreu -------------
-------------------------------------------------

-- 1. What is the total amount each customer spent at the restaurant?

SELECT customer_id, SUM(price) as total_sales
FROM menu_sales
GROUP BY customer_id
ORDER BY customer_id;

-- 2. How many days has each customer visited the restaurant?

SELECT customer_id, COUNT(DISTINCT order_date)
FROM dannys_diner.sales
GROUP BY customer_id
ORDER BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?

WITH ordered_sales AS (SELECT customer_id, product_name, RANK() OVER (
  PARTITION BY customer_id ORDER BY order_date) AS order_date_rank
FROM menu_sales

SELECT DISTINCT customer_id, product_name
FROM dannys_diner.ordered_sales
WHERE order_date_rank = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

WITH top_sale AS (
SELECT product_id, COUNT(product_id) as total_purchases
FROM dannys_diner.sales
GROUP BY product_id
ORDER BY purchases_COUNT desc
LIMIT 1 )

SELECT customer_id, product_name, COUNT(s.product_id) AS times_ordered
FROM members_menu_sales
GROUP BY customer_id, product_name;

-- 5. Which item was the most popular for each customer?

DROP TABLE IF EXISTS customer_cte;

WITH customer_cte AS(
  SELECT
    customer_id,
    product_name,
    COUNT(s.product_id) AS item_quantity,
    RANK() OVER (
      PARTITION BY s.customer_id
      ORDER BY COUNT(s.product_id)
    ) AS item_rank
  FROM menu_sales
  GROUP BY
    customer_id,product_name
    )
SELECT customer_id, product_name
FROM customer_cte
WHERE item_rank=1;

-- 6. Which item was purchased first by the customer after they became a member?

DROP TABLE IF EXISTS customer_order_cte;

WITH customer_order_cte as(
  SELECT
    s.customer_id,
    product_name,
    order_date,
    RANK() OVER (
      PARTITION BY s.customer_id
      ORDER BY order_date
    ) AS item_rank
  FROM members_menu_sales
  WHERE join_date < order_date
  GROUP BY
    s.customer_id,order_date, product_name
    )
    
SELECT customer_id,product_name as first_item_ordered_since_membership
FROM customer_order_cte
WHERE item_rank = 1;

-- 7. Which item was purchased just before the customer became a member?

DROP TABLE IF EXISTS customer_order_cte;

WITH customer_order_cte as(
  SELECT
    s.customer_id,
    product_name,
    order_date,
    RANK() OVER (
      PARTITION BY s.customer_id
      ORDER BY order_date desc
    ) AS item_rank
  FROM members_menu_sales
  WHERE join_date > order_date
  GROUP BY
    s.customer_id,order_date, product_name
    )
    
SELECT customer_id,product_name as first_item_ordered_since_membership
FROM customer_order_cte
WHERE item_rank = 1;

-- 8. What is the total items and amount spent for each member before they became a member?

SELECT customer_id, COUNT(s.product_id) as items_ordered, SUM(price) as total_spent
FROM menu_sales
GROUP BY customer_id;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT customer_id, 
SUM (CASE WHEN product_name = 'sushi' THEN 20*price
ELSE 10*price
END) points
FROM members_menu_sales
WHERE order_date >= join_date
GROUP BY customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi 
-- how many points do customer A and B have at the end of January?

SELECT m.customer_id, 
SUM (CASE 
WHEN (order_date >= join_date AND order_date < join_date+6) OR product_name = 'sushi' THEN 20*price
ELSE  10*price
END) points
FROM members_menu_sales
WHERE order_date >= join_date
GROUP BY m.customer_id;

-- Bonus: Recreate an output table

SELECT m.customer_id, order_date,product_name, price,
CASE 
WHEN order_date >= join_date THEN 'Y'
ELSE  'N'
END member
FROM members_menu_sales
ORDER BY customer_id,order_date
