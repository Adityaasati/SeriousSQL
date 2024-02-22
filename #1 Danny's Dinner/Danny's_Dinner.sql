-- Q1 What is the total amount each customer spent at the restaurant?


SELECT
  customer_id,
  SUM(price)
FROM
  dannys_diner.menu
  JOIN dannys_diner.sales USING (product_id)
GROUP BY
  customer_id
ORDER BY customer_id

-- **************************************************************
-- Q2 How many days has each customer visited the restaurant?


WITH cte AS (
  SELECT
    customer_id,
    COUNT(order_date) as visit_numbers
  FROM
    dannys_diner.sales
  GROUP BY
    customer_id,
    order_date
  ORDER BY
    customer_id
)
SELECT customer_id, COUNT(visit_numbers)
FROM cte
GROUP BY customer_id
-- **************************************************************
-- Q3 What was the first item from the menu purchased by each customer?


WITH sales_rank AS (
  SELECT
    customer_id,
    product_name,
    order_date,
    RANK() OVER(
      PARTITION BY customer_id
      ORDER BY
        order_date
    ) AS ranks
  FROM
    dannys_diner.menu
    JOIN dannys_diner.sales USING (product_id)
)
SELECT DISTINCT
  customer_id,
  product_name
FROM
  sales_rank
WHERE
  ranks = 1
-- **************************************************************
-- Q4 What is the most purchased item on the menu and how many times was it purchased by all customers?


SELECT
  product_name,
  COUNT(order_date) as counts
FROM
  dannys_diner.menu
  JOIN dannys_diner.sales USING (product_id)
GROUP BY
  product_name
ORDER BY
  counts DESC
LIMIT
  1
-- **************************************************************
-- Q5 Which item was the most popular for each customer?


WITH base_cte AS (
  SELECT
    customer_id,
    product_name,
    COUNT(*) as counts,
    RANK() OVER(
      PARTITION BY customer_id
      ORDER BY
        count(product_name) DESC
    ) AS ranks
  FROM
    dannys_diner.menu
    JOIN dannys_diner.sales USING (product_id)
  GROUP BY
    product_name,
    customer_id
  ORDER BY
    counts,
    customer_id
)
SELECT
  customer_id,
  product_name,
  counts
FROM
  base_cte
WHERE
  ranks = 1
ORDER BY
  customer_id
-- **************************************************************
-- Q6  Which item was purchased first by the customer after they became a member?


WITH ctes AS (
  SELECT
    customer_id,
    product_name,
    order_date,
    join_date,
    RANK() OVER(
      PARTITION BY customer_id
      ORDER BY
        order_date ASC
    ) AS ranks
  FROM
    dannys_diner.menu
    JOIN dannys_diner.sales USING (product_id)
    JOIN dannys_diner.members USING(customer_id)
  WHERE
    order_date >= join_date
  ORDER BY
    customer_id
)
SELECT
  DISTINCT customer_id,
  product_name,
  order_date
FROM
  ctes
WHERE
  ranks = 1
ORDER BY
  customer_id
-- **************************************************************
-- Q7 Which item was purchased just before the customer became a member?

WITH ctes AS (
  SELECT
    customer_id,
    product_name,
    order_date,
    join_date,
    RANK() OVER(
      PARTITION BY customer_id
      ORDER BY
        order_date DESC
    ) AS ranks
  FROM
    dannys_diner.menu
    JOIN dannys_diner.sales USING (product_id)
    JOIN dannys_diner.members USING(customer_id)
  WHERE
    order_date < join_date
  ORDER BY
    customer_id
)
SELECT
  DISTINCT customer_id,
  product_name,
  order_date
FROM
  ctes
WHERE
  ranks = 1
ORDER BY
  customer_id
-- **************************************************************
-- Q8 What is the total items and amount spent for each member before they became a member?

SELECT
  customer_id,
  COUNT(*) AS products,
  SUM (price) AS total_amount
FROM
  dannys_diner.menu
  JOIN dannys_diner.sales USING (product_id)
  JOIN dannys_diner.members USING(customer_id)
WHERE
  order_date < join_date
GROUP BY
  customer_id
ORDER BY
  customer_id
-- **************************************************************
-- Q9 If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT
  customer_id,
  SUM(
    CASE
      WHEN product_name = 'sushi' THEN price * 20
      ELSE price * 10
    END
  )
FROM
  dannys_diner.menu
  JOIN dannys_diner.sales USING (product_id)
  GROUP BY customer_id
  ORDER BY customer_id
-- **************************************************************
-- -- Q10 In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT
    customer_id,
    SUM (
      CASE
        WHEN (order_date >= join_date  AND order_date < join_date + 6) OR product_name = 'sushi' THEN price * 20
        ELSE price * 10
        END
      )
      FROM
        dannys_diner.menu
        JOIN dannys_diner.sales USING (product_id)
        JOIN dannys_diner.members USING(customer_id)
      WHERE
        order_date < '2021-02-01'
        GROUP BY customer_id


-- **************************************************************
-- Q11  Recreate the following table output using the available data:
-- customer_id	order_date	product_name	price	member
-- A	2021-01-01	curry	15	N
-- A	2021-01-01	sushi	10	N
-- A	2021-01-07	curry	15	Y
-- A	2021-01-10	ramen	12	Y
-- A	2021-01-11	ramen	12	Y
-- A	2021-01-11	ramen	12	Y
-- B	2021-01-01	curry	15	N
-- B	2021-01-02	curry	15	N
-- B	2021-01-04	sushi	10	N
-- B	2021-01-11	sushi	10	Y
-- B	2021-01-16	ramen	12	Y
-- B	2021-02-01	ramen	12	Y
-- C	2021-01-01	ramen	12	N
-- C	2021-01-01	ramen	12	N
-- C	2021-01-07	ramen	12	N


SELECT
  customer_id,
  order_date,
  product_name,
  price,
  CASE
    WHEN order_date >= join_date THEN 'Y'
    ELSE 'N'
  END AS member
FROM
  dannys_diner.sales
  LEFT JOIN dannys_diner.menu USING (product_id)
  LEFT JOIN dannys_diner.members USING(customer_id)
ORDER BY
  customer_id, order_date, product_name









-- **************************************************************
-- Q12   Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.
-- customer_id	order_date	product_name	price	member	ranking
-- A	2021-01-01	curry	15	N	null
-- A	2021-01-01	sushi	10	N	null
-- A	2021-01-07	curry	15	Y	1
-- A	2021-01-10	ramen	12	Y	2
-- A	2021-01-11	ramen	12	Y	3
-- A	2021-01-11	ramen	12	Y	3
-- B	2021-01-01	curry	15	N	null
-- B	2021-01-02	curry	15	N	null
-- B	2021-01-04	sushi	10	N	null
-- B	2021-01-11	sushi	10	Y	1
-- B	2021-01-16	ramen	12	Y	2
-- B	2021-02-01	ramen	12	Y	3
-- C	2021-01-01	ramen	12	N	null
-- C	2021-01-01	ramen	12	N	null
-- C	2021-01-07	ramen	12	N	null


WITH base_cte AS (
  SELECT
    customer_id,
    order_date,
    product_name,
    price,CASE
      WHEN order_date >= join_date THEN 'Y'
      ELSE 'N'
    END AS member
  FROM
    dannys_diner.sales
    LEFT JOIN dannys_diner.menu USING (product_id)
    LEFT JOIN dannys_diner.members USING(customer_id)
)
SELECT
  customer_id,
  order_date,
  product_name,
  price,
  member,
  CASE
    WHEN member = 'Y' THEN RANK() OVER (
      PARTITION BY customer_id,
      member
      ORDER BY
        order_date
    )
    ELSE NULL
  END AS ranks
FROM
  base_cte
 