## Week 2 - Pizza Runner
<p align="center">
  <a href= 'https://8weeksqlchallenge.com/case-study-2/' target="_blank" rel="noopener noreferrer">
  <img src="https://8weeksqlchallenge.com/images/case-study-designs/2.png" width="500">
  </a>
 </p>
 
 This case study is Week 2 of [Danny Ma's 8 Week SQL Challenge](https://8weeksqlchallenge.com/case-study-2/). 
 
 ## Table of Contents
  
- [:pizza: Context](#ramen-context)  
- [:heavy_exclamation_mark: Problem Statement](#heavy_exclamation_markproblem-statement) 
- [:books: Dataset](#booksdataset) 
- [:link: Entity-Relationship Diagram](#link-entity-relationship-diagram)
- [:hammer: Data Prep](#link-entity-relationship-diagram)
- [:bar_chart: Case Study Questions](#bar_chart-case-study-questions)
  - [:pizza: Pizza Metrics](#pizza-pizza-metrics)
  - [:bicyclist: Runner and Customer Experience](#bicyclist-runner-and-customer-experience)
  - [:cheese: Ingredient Optimisation](#cheese-ingredient-optimisation)
  - [:moneybag: Pricing and Ratings](#moneybag-pricing-and-ratings)


## :pizza: Context

Did you know that over 115 million kilograms of pizza is consumed daily worldwide??? (Well according to Wikipedia anyway…)

Danny was scrolling through his Instagram feed when something really caught his eye - “80s Retro Styling and Pizza Is The Future!”

Danny was sold on the idea, but he knew that pizza alone was not going to help him get seed funding to expand his new Pizza Empire - so he had one more genius idea to combine with it - he was going to Uberize it - and so Pizza Runner was launched!

Danny started by recruiting “runners” to deliver fresh pizza from Pizza Runner Headquarters (otherwise known as Danny’s house) and also maxed out his credit card to pay freelance developers to build a mobile app to accept orders from customers.

## :heavy_exclamation_mark:Problem Statement

We'd like to help Danny have more visibility on his empire's data so he can optimise delivery, keep track of inventory and ensure his customers are happy!

## :books:Dataset

We were given 6 key datasets for this case study:

- runners
- runner_orders
- customer_orders
- pizza_names
- pizza_recipes
- pizza_toppings

#### Table 1: runners

Shows the registradion date for each runner

- runner_id: id of runner
- registration_date: date of registration with platform

<p align="center">
<img width="271" alt="image" src="https://user-images.githubusercontent.com/84375882/169072693-43aa4b0c-5dc1-4695-8f2e-ad8d210ff59c.png">
</p>

#### Table 2: runner_orders

Orders are assigned to runners after being received. However - they may be cancelled either by the restaurant or by the customer.

- order_id: id of order
- runner_id: id of assigned runner
- pickup-time: time where order was picked up from restaurant - null if cancelled
- distance: distance travelled to customer's location - null if cancelled
- duration: time taken to deliver pizza (after pickup) - null if cancelled
- cancellation: flags order cancellation - null if order not cancelled

#### Table 3: customer_orders

Each row is an instance of a pizza in an order - an order may have multiple pizzas!

- order_id: id of order
- customer_id: id of customer who placed order
- pizza_id: id of pizza ordered
- exclusions: toppings to exclude from pizza
- extras: toppings to be added to pizza
- order_time: time order was placed

#### Table 4: pizza_names

- pizza_id
- pizza_name: name of corresponding pizza

<p align="center">
<img width="220" alt="image" src="https://user-images.githubusercontent.com/84375882/169079589-da8fa224-f993-4c23-b250-e346a1fadcab.png">
</p>

#### Table 5: pizza_recipes

- pizza_id
- toppings: array of toppings included in the pizza

<p align="center">
<img width="220" alt="image" src="https://user-images.githubusercontent.com/84375882/169080002-8f3d1146-32a2-47fc-906b-a962a955b55a.png">
</p>


#### Table 6: pizza_toppings

- topping_id
- topping_name: name of topping


<p align="center">
<img width="215" alt="image" src="https://user-images.githubusercontent.com/84375882/169080513-ddb1e535-84d8-4008-a5f4-2fcd72f28ac7.png">
 </p>


## :link: Entity-Relationship Diagram

<p align="center">
<img width="528" alt="image" src="https://user-images.githubusercontent.com/84375882/169071257-52e1148e-4b7e-4b1f-9cfd-5366cb89cbac.png">
</p>

## :hammer: Data Preparation

A lot of data cleaning was necessary for this week! The tables included null, non-unform values and arrays within columns. 

Following are the steps I took to prep the data:

#### runner_orders

- pickup time: clean null
- distance: trim km, clean null
- duration: remove non int characters, clean null
- cancellation: null if not 'Restaurant Cancellation','Customer Cancellation'

```
DROP TABLE IF EXISTS temp_runner_orders;
CREATE TEMPORARY TABLE IF NOT EXISTS temp_runner_orders AS(  
SELECT 
    order_id
   	, runner_id
   	, CASE 
     	WHEN pickup_time LIKE '%null%' THEN null 
         ELSE pickup_time:: TIMESTAMP
    END AS pickup_time
    , UNNEST(REGEXP_MATCH(distance, '([0-9,.]+)'))::NUMERIC AS distance 
    , UNNEST(REGEXP_MATCH(duration, '([0-9]+)'))::NUMERIC AS duration
    , CASE
      WHEN cancellation not in ('Restaurant Cancellation','Customer Cancellation') THEN null
         ELSE cancellation
    END AS cancellation
    FROM pizza_runner.runner_orders);
    
```

#### pizza_recipes

- Transpose toppings column array to rows

```
DROP TABLE IF EXISTS temp_split_standard_toppings;
CREATE TEMPORARY TABLE IF NOT EXISTS temp_split_standard_toppings AS( 
SELECT
  pizza_id
, REGEXP_SPLIT_TO_TABLE(toppings, ',')::INTEGER AS toppings
FROM pizza_runner.pizza_recipes
);
```

#### customer_orders

- Exclusions: clean null or empty
- Extras: clean null or empty
- Add row order column - useful for Ingredient Optimisation section

```
DROP TABLE IF EXISTS temp_cust_orders;
CREATE TEMPORARY TABLE IF NOT EXISTS temp_cust_orders AS(  
  SELECT 
  order_id
  , customer_id
  , pizza_id
  , CASE 
  WHEN exclusions LIKE '' OR exclusions LIKE 'null' THEN null
  ELSE exclusions
  END AS exclusions
  , CASE 
      WHEN extras LIKE ''  OR extras LIKE 'null' THEN null
      ELSE extras
    END AS extras
  , order_time
  , ROW_NUMBER() OVER () AS original_row_number
FROM   pizza_runner.customer_orders);

-- Table with only extras

DROP TABLE IF EXISTS temp_split_extras;
CREATE TEMPORARY TABLE IF NOT EXISTS temp_split_extras AS( 
SELECT
  order_id
  , customer_id
  , pizza_id
  , REGEXP_SPLIT_TO_TABLE(extras, ',')::INTEGER AS extras
FROM temp_cust_orders
);

-- Table with only exclusions

DROP TABLE IF EXISTS temp_split_exclusions;
CREATE TEMPORARY TABLE IF NOT EXISTS temp_split_exclusions AS( 
SELECT
  order_id
  , customer_id
  , pizza_id
  , REGEXP_SPLIT_TO_TABLE(exclusions, ',')::INTEGER AS exclusions
FROM temp_cust_orders
);

-- Table with pizza details including split extras and exclusions

DROP TABLE IF EXISTS temp_exclusions_extras;
CREATE TEMPORARY TABLE IF NOT EXISTS temp_exclusions_extras AS( 
  SELECT
    order_id
    , customer_id
    , pizza_id
    , REGEXP_SPLIT_TO_TABLE(exclusions, ',')::INTEGER AS exclusions
    , REGEXP_SPLIT_TO_TABLE(extras, ',')::INTEGER AS extras
    , order_time
    , original_row_number
  FROM temp_cust_orders
UNION
    SELECT
      order_id
      , customer_id
      , pizza_id
      , NULL AS exclusions
      , NULL AS extras
      , order_time
      , original_row_number
    FROM temp_cust_orders
    WHERE exclusions IS NULL AND extras IS NULL
);

-- Table with all customer order details (extras and exclusions split) 

DROP TABLE IF EXISTS temp_complete_dataset;
CREATE TEMPORARY TABLE IF NOT EXISTS temp_complete_dataset AS( 
  SELECT 
    t.order_id
    , t.customer_id
    , t.pizza_id
    , names.pizza_name
    , t.order_time
    , t.original_row_number
    , STRING_AGG(exclusions.topping_name, ', ') AS exclusions
    , STRING_AGG(extras.topping_name, ', ') AS extras
  FROM temp_exclusions_extras AS t
  INNER JOIN pizza_runner.pizza_names AS names
    ON t.pizza_id = names.pizza_id
  LEFT JOIN pizza_runner.pizza_toppings AS exclusions
    ON t.exclusions = exclusions.topping_id
  LEFT JOIN pizza_runner.pizza_toppings AS extras
    ON t.extras = extras.topping_id
  GROUP BY 
  t.order_id
  , t.customer_id
  , t.pizza_id
  , names.pizza_name
  , t.order_time
  , t.original_row_number
);

```

## :bar_chart: Case Study Questions

This weeks case study was divided in 4 sections which will be expanded on below!

### :pizza: Pizza Metrics

1. How many pizzas were ordered?

```
select count(order_id) as pizzas_ordered
from pizza_runner.customer_orders;
```

<details>
  <summary>Output</summary>
  <img width="241" alt="image" src="https://user-images.githubusercontent.com/84375882/169086812-1390b726-30fd-475e-b106-ca881ba78728.png">

</details>

2. How many unique customer orders were made?

```
select count(distinct order_id) as order_count
from pizza_runner.customer_orders;
```
<details>
  <summary>Output</summary>
  <img width="203" alt="image" src="https://user-images.githubusercontent.com/84375882/169091831-124d5b86-9230-4101-a2f8-778c7fa7a979.png">
</details>

3. How many successful orders were delivered by each runner?

From this question onwards we will mostly be using temp_cust_orders and temp_runner_orders instead of customer_orders and runner_orders as they've been duly prepped.

```
select 
  runner_id
  , count(distinct order_id) as successful_orders
from temp_runner_orders
where cancellation is null
group by runner_id
order by runner_id;
```
<details>
  <summary>Output</summary>
  <img width="339" alt="image" src="https://user-images.githubusercontent.com/84375882/169087682-36c36040-937c-4c3b-a626-bb580e774086.png">

</details>

4. How many of each type of pizza was delivered?

```
SELECT 
  pizza_name
  , count(c.pizza_id) as pizzas_delivered
FROM temp_cust_orders c 
  INNER JOIN temp_runner_orders r 
    ON c.order_id = r.order_id 
  INNER JOIN pizza_runner.pizza_names n
    ON n.pizza_id = c.pizza_id 
WHERE pickup_time IS NOT NULL
GROUP BY pizza_name;
```
<details>
  <summary>Output</summary>
  <img width="348" alt="image" src="https://user-images.githubusercontent.com/84375882/169090432-6a8b6456-70a6-4e42-b073-dfb2c8d39e63.png">

</details>

5. How many Vegetarian and Meatlovers were ordered by each customer?

```
SELECT 
  customer_id
  , sum(case when c.pizza_id = 1 then 1 else 0 end) as "Meatlovers"
  , sum(case when c.pizza_id = 2 then 1 else 0 end) as "Vegetarian"
FROM pizza_runner.customer_orders c INNER JOIN pizza_runner.pizza_names pn ON c.pizza_id = pn.pizza_id
GROUP BY customer_id
ORDER BY customer_id;
```
<details>
  <summary>Output</summary>
  <img width="537" alt="image" src="https://user-images.githubusercontent.com/84375882/169090652-0040a6cc-eb34-4cc4-bfb4-89c037f1eb8b.png">
</details>

6. What was the maximum number of pizzas delivered in a single order?

```
SELECT 
COUNT(pizza_id) AS max_pizza_per_order
FROM pizza_runner.customer_orders
GROUP BY order_id
ORDER BY max_pizza_per_order desc
LIMIT 1;
```
<details>
  <summary>Output</summary>
  <img width="243" alt="image" src="https://user-images.githubusercontent.com/84375882/169090740-c6f5e75e-df03-4467-b1b3-6493525e44c6.png">

</details>

7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

```
SELECT 
  customer_id
  , SUM(
      CASE WHEN exclusions IS NULL AND extras IS NULL THEN 1 ELSE 0 END) 
    AS "no_changes"
  , SUM(
      CASE WHEN exclusions IS NOT NULL OR extras IS NOT NULL THEN 1 ELSE 0 END) 
    AS "had_changes"
FROM temp_cust_orders
GROUP BY customer_id
ORDER BY customer_id;
```
<details>
  <summary>Output</summary>
  <img width="549" alt="image" src="https://user-images.githubusercontent.com/84375882/169090930-ed894cdb-83c0-4b29-b20a-f4ddb891a87e.png">
</details>

8. How many pizzas were delivered that had both exclusions and extras?

```
SELECT 
  customer_id
  , SUM(
      CASE WHEN exclusions IS NOT NULL AND extras IS NOT NULL THEN 1 ELSE 0 END) 
    AS "had_exclusion_&_extras"
FROM temp_cust_orders
GROUP BY customer_id
ORDER BY customer_id;
```
<details>
  <summary>Output</summary>
  <img width="425" alt="image" src="https://user-images.githubusercontent.com/84375882/169091072-78585c7c-f79c-490f-8c35-490c87bce3e4.png">
</details>

9. What was the total volume of pizzas ordered for each hour of the day?

```
SELECT 
  DATE_PART('hour', order_time) as order_hour
  , COUNT(pizza_id) as pizza_count
FROM pizza_runner.customer_orders
GROUP BY 1
ORDER BY 1;
```
<details>
  <summary>Output</summary>
  <img width="320" alt="image" src="https://user-images.githubusercontent.com/84375882/169091145-f0405023-fc21-4dbe-9544-5006dc1f8119.png">
</details>

10. What was the volume of orders for each day of the week?

The to_char function extracts a date part and transforms it into a string 
```
SELECT 
  TO_CHAR(order_time,'Day') as day_ordered
  , COUNT(pizza_id) as pizzas_ordered
FROM pizza_runner.customer_orders
GROUP BY day_ordered, DATE_PART('dow', order_time)
ORDER BY DATE_PART('dow', order_time);
```
<details>
  <summary>Output</summary>
<img width="386" alt="image" src="https://user-images.githubusercontent.com/84375882/169091652-eeb4ff39-7784-4745-be62-e64734791d96.png">

</details>


### :bicyclist: Runner and Customer Experience

1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

Here we have to add +4 to the date in order to accomodate the restriction 
that the week starts on the 01/01/21 rather than on the Monday which would've been 28/12/2020 

```
SELECT
  DATE_TRUNC('week', registration_date)::DATE + 4 AS registration_week
  , COUNT(runner_id) AS runners
FROM pizza_runner.runners
GROUP BY registration_week
ORDER BY registration_week;
```
<details>
  <summary>Output</summary>
<img width="473" alt="image" src="https://user-images.githubusercontent.com/84375882/169092370-0189eff1-3228-415f-91d0-4bb20f18f846.png">
</details>

2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

```
WITH cte_pickup_mins AS (
  SELECT 
  DISTINCT c.order_id
  , DATE_PART('minute', AGE(pickup_time, order_time))::INTEGER AS pickup_mins
  FROM temp_runner_orders AS r
  INNER JOIN temp_cust_orders AS c ON r.order_id = c.order_id
)

SELECT round(AVG(pickup_mins),1) AS avg_pickup_time_mins
FROM cte_pickup_mins;
```
<details>
  <summary>Output</summary>
<img width="251" alt="image" src="https://user-images.githubusercontent.com/84375882/169092578-c6973afa-4291-4b9c-b2a9-f36840a6e1b6.png">
</details>

3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

```
SELECT 
  DISTINCT c.order_id
  , DATE_PART('minute', AGE(pickup_time, order_time))::INTEGER AS pickup_mins
  , COUNT(c.order_id) AS pizzas_ordered
  FROM temp_runner_orders AS r
  INNER JOIN temp_cust_orders AS c ON r.order_id = c.order_id
  WHERE pickup_time is not null
  GROUP BY c.order_id, pickup_mins
  ORDER BY pizzas_ordered ;
```

<details>
  <summary>Output</summary>
<img width="528" alt="image" src="https://user-images.githubusercontent.com/84375882/169092654-b2c80391-0d46-4dee-9636-496c5e96845d.png">
</details>

4. What was the average distance travelled for each customer?

```
SELECT 
  customer_id
  , ROUND(AVG(distance),2) as avg_distance_km
FROM temp_runner_orders r INNER JOIN temp_cust_orders c ON r.order_id = c.order_id
GROUP BY customer_id;
```
<details>
  <summary>Output</summary>
<img width="364" alt="image" src="https://user-images.githubusercontent.com/84375882/169092698-905acc56-f635-49f2-bacd-22eff1276f73.png">
</details>

5. What was the difference between the longest and shortest delivery times for all orders?

```
SELECT MAX(duration) - MIN(duration) as max_difference_in_delivery_time
FROM temp_runner_orders;
```
<details>
  <summary>Output</summary>
<img width="299" alt="image" src="https://user-images.githubusercontent.com/84375882/169092763-867b60ee-9921-4adc-a47d-778574920584.png">
</details>

6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

```
SELECT 
  runner_id
  , c.order_id
  , customer_id
  , DATE_PART('hour', pickup_time::TIMESTAMP) AS hour_of_day
  , ROUND(AVG(duration)) as duration_min
  , ROUND(AVG(distance)) as distance_km
  , ROUND(AVG(60*distance/duration)) as km_per_h
FROM temp_runner_orders r INNER JOIN temp_cust_orders c on r.order_id = c.order_id
GROUP BY runner_id,c.order_id,hour_of_day,customer_id
ORDER BY hour_of_day;
```
<details>
  <summary>Output</summary>
<img width="867" alt="image" src="https://user-images.githubusercontent.com/84375882/169092896-87bc6bf0-1cfe-4f46-ad8e-18aea0e50097.png">
</details>

7. What is the successful delivery percentage for each runner?

Here it is simpler to use the initial runner_orders table as the CTE created does not show the rows where pickup_time is null due to the regex matches. 

An improvement to the original CTE would be to fix this issue.

```
SELECT
  runner_id
  , ROUND( 100 * SUM( CASE WHEN pickup_time <> 'null' THEN 1 ELSE 0 END) / COUNT(*) ) AS successful_delivery_rate
FROM pizza_runner.runner_orders
GROUP BY runner_id
ORDER BY runner_id;
```
<details>
  <summary>Output</summary>
<img width="382" alt="image" src="https://user-images.githubusercontent.com/84375882/169092981-b8247c12-d520-4d41-9fb4-e206f2082eeb.png">
</details>

### :cheese: Ingredient Optimisation

1. What are the standard ingredients for each pizza?

Here I've created a CTE to split the topping_id's from comma separated strings into rows using REGEXP_SPLIT_TO_TABLE.
This enables to then match them to the ingredient names via the pizzza_toppings table in the main query.
Once they've been matched they're aggregated into a comma separated string again.

```
DROP TABLE IF EXISTS split_standard_toppings_ids;
WITH split_standard_toppings_ids AS (
SELECT
  pizza_id,
  REGEXP_SPLIT_TO_TABLE(toppings, ',')::INTEGER AS topping_id
FROM pizza_runner.pizza_recipes
)

SELECT
  pizza_id,
  STRING_AGG(topping_name::TEXT,',') AS standard_ingredients
FROM split_standard_toppings_ids AS s
INNER JOIN pizza_runner.pizza_toppings AS t
  ON s.topping_id = t.topping_id
GROUP BY pizza_id
ORDER BY pizza_id;
```
<details>
  <summary>Output</summary>
<img width="657" alt="image" src="https://user-images.githubusercontent.com/84375882/169093310-08ef26c7-4caa-41ae-ba77-003305a7a888.png">
</details>

2. What was the most commonly added extra?

```
SELECT 
  topping_name as most_common_extra
FROM temp_split_extras e
INNER JOIN pizza_runner.pizza_toppings t 
  ON e.extras = t.topping_id 
GROUP BY topping_name
ORDER BY COUNT(*) DESC
LIMIT 1;
```
<details>
  <summary>Output</summary>
<img width="229" alt="image" src="https://user-images.githubusercontent.com/84375882/169093477-db8cb381-d523-4421-a9b9-ef1a0ef4035a.png">
</details>

3. What was the most common exclusion?

```
SELECT 
  topping_name as most_common_exclusion
FROM temp_split_exclusions e
INNER JOIN pizza_runner.pizza_toppings t 
  ON e.exclusions = t.topping_id 
GROUP BY topping_name
ORDER BY COUNT(*) DESC
LIMIT 1;
```

<details>
  <summary>Output</summary>
<img width="265" alt="image" src="https://user-images.githubusercontent.com/84375882/169093561-6636dd4a-a6d4-4f2f-b73c-877cdf57dc3e.png">
</details>

4. Generate an order item for each record in the customers_orders table in the format of one of the following:
--    Meat Lovers
--    Meat Lovers - Exclude Beef
--    Meat Lovers - Extra Bacon
--    Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

-- Here I've used the previously created temp_complete_dataset table where the extras and exclusions columns have already been split

```
WITH cte_parsed_string_outputs AS (
SELECT
  order_id
  , customer_id
  , pizza_id
  , order_time
  , original_row_number
  , pizza_name
  , CASE WHEN exclusions IS NULL THEN '' ELSE ' - Exclude ' || exclusions END AS exclusions
  , CASE WHEN extras IS NULL THEN '' ELSE ' - Extra ' || exclusions END AS extras
FROM temp_complete_dataset
)
, final_output AS (
  SELECT
    order_id
    , customer_id
    , pizza_id
    , order_time
    , original_row_number
    , pizza_name || exclusions || extras AS order_item
  FROM cte_parsed_string_outputs
)
SELECT
  order_id
  , customer_id
  , pizza_id
  , order_time
  , order_item
FROM final_output
WHERE order_item IS NOT NULL
ORDER BY original_row_number;
```
<details>
  <summary>Output</summary>
<img width="1278" alt="image" src="https://user-images.githubusercontent.com/84375882/169093662-08449a5b-d1d8-4160-93f5-78d815e3306f.png">
</details>

### :moneybag: Pricing and Ratings

1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and 
-- there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?

```
SELECT
  SUM(
    CASE 
      WHEN pizza_id = 1 THEN 12 -- meatlovers
      WHEN pizza_id = 2 THEN 10 -- vegetarian
    END
  ) AS total_revenue
FROM temp_cust_orders c 
  INNER JOIN temp_runner_orders r ON c.order_id = r.order_id
WHERE pickup_time IS NOT NULL;
```
<details>
  <summary>Output</summary>
<img width="212" alt="image" src="https://user-images.githubusercontent.com/84375882/169093826-b762e117-ef5d-4c1d-99c2-24b8b71ff51c.png">
</details>

2. What if there was an additional $1 charge for any pizza extras? + Add cheese is $1 extra

Here I've reused the previous query as a cte and created an additional cte for the total revenue from the extras.
The temp queries can be found in data prep section.
The sum of these CTEs then gave the final amount given the additional charges

```
WITH cte_pizza_rev AS 
(
  SELECT
    SUM
    (
      CASE 
        WHEN pizza_id = 1 THEN 12 -- meatlovers
        WHEN pizza_id = 2 THEN 10 -- vegetarian
      END
    ) AS pizza_revenue
  FROM temp_cust_orders c INNER JOIN temp_runner_orders r ON c.order_id = r.order_id
  WHERE pickup_time IS NOT NULL
)

, cte_extras_rev AS 
(
  SELECT
    SUM
    (
      CASE 
        WHEN extras = 4 THEN 2 -- extra is cheese
        ELSE 1
      END
    ) AS extras_revenue
  FROM temp_split_extras e INNER JOIN temp_runner_orders r ON e.order_id = r.order_id
  WHERE pickup_time IS NOT NULL
)

SELECT SUM(pizza_revenue) as total_revenue
FROM 
(
  SELECT * FROM cte_pizza_rev
  UNION
  SELECT * FROM cte_extras_rev
) AS total_revenue
;
```
<details>
  <summary>Output</summary>
<img width="188" alt="image" src="https://user-images.githubusercontent.com/84375882/169093913-cf2fc782-1693-4323-98be-90e681ea977a.png">
</details>

3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, 
-- how would you design an additional table for this new dataset generate a schema for this new table and 
-- insert your own data for ratings for each successful customer order between 1 to 5.

```
SELECT SETSEED(0.42);

DROP TABLE IF EXISTS pizza_runner.ratings;
CREATE TABLE pizza_runner.ratings (
  "order_id" INTEGER,
  "rating" INTEGER
);

INSERT INTO pizza_runner.ratings
SELECT
  order_id
  , FLOOR(RANDOM()*5+1) AS rating
FROM pizza_runner.runner_orders
WHERE pickup_time IS NOT NULL;

select *
from pizza_runner.ratings;
```
<details>
  <summary>Output</summary>
<img width="230" alt="image" src="https://user-images.githubusercontent.com/84375882/169094001-c36dfa7f-6243-4b8a-9f6f-9b9e0a7d4af3.png">
</details>

4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries? + customer_id + order_id + runner_id + rating + order_time + pickup_time + Time between order and pickup + Delivery duration + Average speed + Total number of pizzas

Here we'll use the cte_pickup_mins created for the Runner and Customer Experience section for mins_to_pickup.
```
SELECT 
  customer_id
  , r.order_id
  , runner_id
  , rating
  , order_time
  , pickup_time
  , ROUND(pickup_mins) AS mins_to_pickup
  , ROUND(60*distance/duration) as avg_speed
FROM ((temp_runner_orders r LEFT JOIN cte_pickup_mins p ON  r.order_id = p.order_id) 
  INNER JOIN temp_cust_orders c on r.order_id = c.order_id)
  INNER JOIN pizza_runner.ratings rt on rt.order_id = r.order_id
WHERE pickup_time IS NOT NULL;
```
<details>
  <summary>Output</summary>
<img width="1108" alt="image" src="https://user-images.githubusercontent.com/84375882/169094228-3cb3f17a-a7f5-4290-86e0-6d3d32e36d03.png">
</details>

5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

```
DROP TABLE IF EXISTS temp_pizzas_distance;
CREATE TEMPORARY TABLE IF NOT EXISTS temp_pizzas_distance AS
(  
SELECT 
  c.order_id
  , SUM(CASE WHEN pizza_id = 1 THEN 1 ELSE 0 END) AS meatlovers_count
  , SUM(CASE WHEN pizza_id = 2 THEN 1 ELSE 0 END) AS vegetarian_count
  , SUM(distance) AS total_distance
FROM temp_cust_orders c INNER JOIN temp_runner_orders r on c.order_id = r.order_id
WHERE pickup_time IS NOT NULL
GROUP BY c.order_id
);

SELECT SUM ( meatlovers_count*12 + vegetarian_count*10 - total_distance*0.3) AS profit
FROM temp_pizzas_distance
;
```

<details>
  <summary>Output</summary>
<img width="137" alt="image" src="https://user-images.githubusercontent.com/84375882/169094474-476d1ee0-b9bc-4701-ae57-fdd3b2678df2.png">
</details>


