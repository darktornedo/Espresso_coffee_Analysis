-- create database
CREATE DATABASE coffee_db;

-- create table 'city'
CREATE TABLE city
(
	city_id	INT PRIMARY KEY,
	city_name VARCHAR(15),	
	population	BIGINT,
	estimated_rent	FLOAT,
	city_rank INT
);

-- create table 'customers'
CREATE TABLE customers
(
	customer_id INT PRIMARY KEY,	
	customer_name VARCHAR(25),	
	city_id INT,
	CONSTRAINT fk_city FOREIGN KEY (city_id) REFERENCES city(city_id)
);

-- create table 'products'
CREATE TABLE products
(
	product_id	INT PRIMARY KEY,
	product_name VARCHAR(35),	
	Price float
);

-- create table 'sales'
CREATE TABLE sales
(
	sale_id	INT PRIMARY KEY,
	sale_date	date,
	product_id	INT,
	customer_id	INT,
	total FLOAT,
	rating INT,
	CONSTRAINT fk_products FOREIGN KEY (product_id) REFERENCES products(product_id),
	CONSTRAINT fk_customers FOREIGN KEY (customer_id) REFERENCES customers(customer_id) 
);

-- Data Analysis and Findings 

-- Easy Level Questions 
/*Task 1: Coffee Consumers Count
Write a Query to find How many people in each city are estimated to consume coffee, given that 25% of the population does?*/

SELECT city_name , ROUND((population * 0.25) / 1000000,2) as coffee_consumers_in_millions,
city_rank
FROM city
ORDER BY coffee_consumers_in_millions DESC;

/* Task 2: Total Revenue from Coffee Sales
write a query to find the total revenue generated from coffee sales across all cities in the last quarter of 2023?*/

SELECT c.city_name, YEAR(s.sale_date) AS year, QUARTER(s.sale_date) as Quarter, SUM(s.total) AS total_revenue 
FROM city AS C 
JOIN customers AS cc ON c.city_id = cc.city_id
JOIN sales AS s ON cc.customer_id  = s.customer_id 
WHERE YEAR(s.sale_date) = 2023 AND QUARTER(s.sale_date) = 4
GROUP BY c.city_name, year, Quarter
ORDER BY total_revenue DESC;

/* Task 3: Sales Count for Each Product
write a query to find How many units of each coffee product have been sold?*/

SELECT p.product_name, COUNT(s.sale_id) as total_orders 
FROM products AS p 
JOIN sales AS s ON p.product_id = s.product_id
GROUP BY p.product_name
ORDER BY total_orders DESC;


/* Task 4: Average Sales Amount per City
write a query to find What is the average sales amount per customer in each city?*/

SELECT cc.customer_id, cc.customer_name, c.city_name, SUM(s.total) AS total_revenue, AVG (s.total) AS average_sales_amount
FROM city AS c 
JOIN customers AS cc ON c.city_id = cc.city_id 
JOIN sales AS s ON cc.customer_id = s.customer_id
GROUP BY c.city_name, cc.customer_id,cc.customer_name
ORDER BY  total_revenue DESC;

/* Task 5: City Population and Coffee Consumers (25%)
Provide a list of cities along with their populations and estimated coffee consumers.
return city_name, total current cx, estimated coffee consumers (25%) */

SELECT city_name, population, ROUND((population * 0.25) / 1000000,2) as coffee_consumers_in_millions,
COUNT(DISTINCT cc.customer_id) as unique_cx
FROM city AS c 
JOIN customers AS cc ON c.city_id = cc.city_id
GROUP BY city_name, population
ORDER BY city_name;
  
  
-- Medium Level Questions 
/* Task 6: Top Selling Products by City
write a query to find What are the top 3 selling products in each city based on sales volume? */

WITH best_selling_product AS (
SELECT c.city_name, p.product_name, SUM(s.total) as total_revenue,
DENSE_RANK() OVER(PARTITION BY c.city_name ORDER BY SUM(s.total) DESC) as rnk
FROM city AS c 
JOIN customers AS cc ON c.city_id = cc.city_id
JOIN sales AS s ON cc.customer_id = s.customer_id
JOIN products AS p ON s.product_id = p.product_id
GROUP BY c.city_name, p.product_name
)
SELECT city_name, product_name, total_revenue, rnk
FROM best_selling_product
WHERE rnk<=3;

/* Task 7: Customer Segmentation by City
write a query to find How many unique customers are there in each city who have purchased coffee products? */

SELECT c.city_name, COUNT(DISTINCT cc.customer_id) as unique_cus_count, COUNT(s.product_id) AS total_product_ordered
FROM city AS c 
JOIN customers AS cc ON c.city_id = cc.city_id
LEFT JOIN sales AS s ON cc.customer_id = s.customer_id
GROUP BY c.city_name
ORDER BY total_product_ordered DESC;

/* Task 8:  Average Sale vs Rent
write a query to Find each city and their average sale per customer and avg rent per customer */

WITH city_table AS(
SELECT c.city_name, SUM(s.total) as total_revenue, COUNT(DISTINCT cc.customer_id) as unique_cus_count, 
ROUND(AVG(s.total),2) as average_revenue_per_cus
FROM city AS C 
JOIN customers AS cc ON c.city_id = cc.city_id
JOIN sales AS s ON cc.customer_id = s.customer_id
GROUP BY c.city_name
),
city_rent AS (
SELECT city_name, estimated_rent
FROM city
)
SELECT ct.city_name, ct.total_revenue, cr.estimated_rent, ct.unique_cus_count, ct.average_revenue_per_cus,
ROUND(cr.estimated_rent / ct.unique_cus_count,2) as average_rent_per_cus
FROM city_table AS ct
JOIN city_rent AS cr ON ct.city_name = cr.city_name
ORDER BY total_revenue DESC;

-- Advanced Level Questions 
/* Task 9: Monthly Sales Growth
write a query to find Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
by each city */

WITH previous_month_sale AS (
SELECT c.city_name, DATE_FORMAT(s.sale_date, '%Y-%M') as sale_month, SUM(s.total) as total_revenue,
LAG(SUM(s.total)) OVER(PARTITION BY c.city_name ORDER BY DATE_FORMAT(s.sale_date, '%Y-%M')) as previous_month_sales
FROM city AS c 
JOIN customers AS cc ON c.city_id = cc.city_id 
JOIN sales AS s ON cc.customer_id  = s.customer_id
GROUP BY c.city_name, sale_month
)
SELECT city_name, sale_month,total_revenue, previous_month_sales,
CASE 
 WHEN previous_month_sales IS NULL THEN NULL 
 WHEN previous_month_sales = 0 THEN NULL
 ELSE ROUND(((total_revenue - previous_month_sales) / previous_month_sales) *100,2)
 END AS sale_growth_percentage
 FROM previous_month_sale
 GROUP BY city_name, sale_month;
 
 /* Task 10: Market Potential Analysis
write a query to find the Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer */

WITH city_table AS (
SELECT c.city_name, SUM(s.total) as total_revenue, COUNT( DISTINCT cc.customer_id) as unique_cus_count, 
ROUND(SUM(s.total) / COUNT(DISTINCT cc.customer_id) ,2) as average_sale_per_cus
FROM city AS C 
JOIN customers AS cc ON c.city_id = cc.city_id
JOIN sales AS s ON cc.customer_id = s.customer_id 
GROUP BY c.city_name
),
 city_rent AS (
 SELECT city_name, estimated_rent, ROUND((population * 0.25) / 1000000,2) as coffee_consumer_in_millions
 FROM city
 )
  SELECT ct.city_name, ct.total_revenue, cr.estimated_rent, ct.unique_cus_count, ct.average_sale_per_cus, 
  cr.coffee_consumer_in_millions, ROUND(cr.estimated_rent / ct.unique_cus_count) as average_rent_per_cus
  FROM city_table as ct
  JOIN city_rent as cr ON ct.city_name = cr.city_name
  ORDER BY ct.total_revenue DESC
  LIMIT 3;
