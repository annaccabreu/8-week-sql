## Week 1 - Danny's Diner
<p align="center">
  <a href= 'https://8weeksqlchallenge.com/case-study-1/' target="_blank" rel="noopener noreferrer">
  <img src="https://8weeksqlchallenge.com/images/case-study-designs/1.png" width="500">
  </a>
 </p>
 
 This case study is Week 1 of [Danny Ma's 8 Week SQL Challenge](https://8weeksqlchallenge.com/case-study-1/). 
 
 ## Table of Contents
  
- [:ramen: Context](#ramen-context)  
- [:heavy_exclamation_mark: Problem Statement](#heavy_exclamation_markproblem-statement) 
- [:books: Dataset](#booksdataset) 
- [:link: Entity-Relationship Diagram](#link-entity-relationship-diagram)
- [:bar_chart: Case Study Questions](#bar_chart-case-study-questions)
- [:sparkles: Bonus Questions](#sparkles-bonus-questions)
- [:bulb: Recommendations](#bulb-recommendations)


## :ramen: Context

Danny seriously loves Japanese food so in the beginning of 2021, he decides to embark upon a risky venture and opens up a cute little restaurant that sells his 3 favourite foods: sushi, curry and ramen.

Danny’s Diner is in need of your assistance to help the restaurant stay afloat - the restaurant has captured some very basic data from their few months of operation but have no idea how to use their data to help them run the business.

## :heavy_exclamation_mark:Problem Statement

Danny wants to use the data to answer a few simple questions about his customers, especially about their visiting patterns, how much money they’ve spent and also which menu items are their favourite. Having this deeper connection with his customers will help him deliver a better and more personalised experience for his loyal customers.

He plans on using these insights to help him decide whether he should expand the existing customer loyalty program - additionally he needs help to generate some basic datasets so his team can easily inspect the data without needing to use SQL.

## :books:Dataset

We were given 3 key datasets for this case study:

- sales
- menu
- members

#### Sales

Maps orders made by customers to the products they ordered and the date the order took place
<p align="center">
<img width="271" alt="image" src="https://user-images.githubusercontent.com/84375882/165111938-97e798d6-1c00-47b7-bed9-f1f768cfdc43.png">
</p>

#### Menu

Contains the product id, its corresponding name and price
<p align="center">
<img width="371" alt="image" src="https://user-images.githubusercontent.com/84375882/165107188-57b7a6db-419b-4a5b-b2be-452898bba19b.png">
</p>

#### Members

Member's id along with date they joined Danny's Diner's loyaly program
<p align="center">
<img width="271" alt="image" src="https://user-images.githubusercontent.com/84375882/165107992-ce3673e6-33b6-4e31-b15c-cacf63c8fc74.png">
</p>

## :link: Entity-Relationship Diagram

<p align="center">
<img width="528" alt="image" src="https://user-images.githubusercontent.com/84375882/165112251-d4b1e536-6436-4346-aa19-3f5f9277b00e.png">
</p>

## :bar_chart: Case Study Questions

To simplify the data exploration I created a few CTEs with common joins
```
WITH members_menu_sales AS (
SELECT *
FROM (dannys_diner.sales s INNER JOIN dannys_diner.members mb ON s.customer_id = mb.customer_id) 
INNER JOIN dannys_diner.menu mu ON mu.product_id = s.product_id 
)
, 
menu_sales AS (
SELECT *
FROM dannys_diner.sales s INNER JOIN dannys_diner.menu mu ON mu.product_id = s.product_id 
)
,
member_sales AS (
SELECT *
FROM dannys_diner.sales s INNER JOIN dannys_diner.member mb ON mb.customer_id = s.customer_id 
)
```

1. What is the total amount each customer spent at the restaurant?
```
SELECT customer_id, SUM(price) as total_sales
FROM menu_sales
GROUP BY customer_id
ORDER BY customer_id;
```
<details>
  <summary>Output</summary>
  <img width="174" alt="image" src="https://user-images.githubusercontent.com/84375882/165115056-ee118cf3-735d-41cd-b1e6-f97061c6c815.png">
</details>

2. How many days has each customer visited the restaurant?
```
SELECT customer_id, COUNT(DISTINCT order_date)
FROM dannys_diner.sales
GROUP BY customer_id
ORDER BY customer_id;
```
<details>
  <summary>Output</summary>
  <img width="144" alt="image" src="https://user-images.githubusercontent.com/84375882/165115123-d1815d26-07e7-48ad-a527-829a683764ed.png">
</details>

3. What was the first item from the menu purchased by each customer?
```
WITH ordered_sales AS (SELECT customer_id, product_name, RANK() OVER (
  PARTITION BY customer_id ORDER BY order_date) AS order_date_rank
FROM menu_sales

SELECT DISTINCT customer_id, product_name
FROM dannys_diner.ordered_sales
WHERE order_date_rank = 1;
```

<details>
  <summary>Output</summary>
  <img width="200" alt="image" src="https://user-images.githubusercontent.com/84375882/165115179-8510c9cc-9e51-4895-8221-cc43da229a12.png">
</details>

4. What is the most purchased item on the menu and how many times was it purchased by all customers?
```
DROP TABLE IF EXISTS top_sale;

WITH top_sale AS (
SELECT product_id, COUNT(product_id) as total_purchases
FROM dannys_diner.sales
GROUP BY product_id
ORDER BY purchases_COUNT desc
LIMIT 1 )

SELECT customer_id, product_name, COUNT(s.product_id) AS times_ordered
FROM members_menu_sales
GROUP BY customer_id, product_name;
```
<details>
  <summary>Output</summary>
  <img width="227" alt="image" src="https://user-images.githubusercontent.com/84375882/165115226-fc8e90b5-9f4c-404c-90cd-6bffcdf4a25b.png">
</details>

5. Which item was the most popular for each customer?
```
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
```

<details>
  <summary>Output</summary>
  <img width="303" alt="image" src="https://user-images.githubusercontent.com/84375882/165115407-ffe7b94c-31c6-4c74-ac25-3ba4487c691d.png">
</details>

6. Which item was purchased first by the customer after they became a member?
```
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
```

<details>
  <summary>Output</summary>
  <img width="295" alt="image" src="https://user-images.githubusercontent.com/84375882/165115488-1ff74020-0d0a-4c64-a858-a8ea28426b98.png">
</details>

7. Which item was purchased just before the customer became a member?
```
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
```

<details>
  <summary>Output</summary>
  <img width="293" alt="image" src="https://user-images.githubusercontent.com/84375882/165115573-c805e1bd-89e5-4fc2-9da2-da141d65db00.png">
</details>


8. What is the total items and amount spent for each member before they became a member?
```
SELECT customer_id, COUNT(s.product_id) as items_ordered, SUM(price) as total_spent
FROM menu_sales
GROUP BY customer_id;
```
<details>
  <summary>Output</summary>
  <img width="328" alt="image" src="https://user-images.githubusercontent.com/84375882/165115641-e412fd16-8732-4d2a-8e15-1fdcc8b151df.png">
</details>

9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
```
SELECT customer_id, 
SUM (CASE WHEN product_name = 'sushi' THEN 20*price
ELSE 10*price
END) points
FROM members_menu_sales
WHERE order_date >= join_date
GROUP BY customer_id;
```
<details>
  <summary>Output</summary>
  <img width="146" alt="image" src="https://user-images.githubusercontent.com/84375882/165115718-80b85f23-8e78-4038-89cb-e2420ce8ec37.png">
</details>

10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
```
SELECT m.customer_id, 
SUM (CASE 
WHEN (order_date >= join_date AND order_date < join_date+6) OR product_name = 'sushi' THEN 20*price
ELSE  10*price
END) points
FROM members_menu_sales
WHERE order_date >= join_date
GROUP BY m.customer_id;
```

<details>
  <summary>Output</summary>
  <img width="147" alt="image" src="https://user-images.githubusercontent.com/84375882/165119868-7a6ceded-8fb6-4a66-8c3d-b303f6f86e6a.png">
</details>

## :sparkles: Bonus Questions

Recreate the following table output using the available data:

<img width="400" alt="image" src="https://user-images.githubusercontent.com/84375882/165108506-dcf29532-ec9a-4ef9-8b2a-2b8202c2982c.png">

```
SELECT m.customer_id, order_date,product_name, price,
CASE 
WHEN order_date >= join_date THEN 'Y'
ELSE  'N'
END member
FROM members_menu_sales
ORDER BY customer_id,order_date
```

## :bulb: Recommendations


