CREATE TABLE mobile_sales (
    transaction_id   INTEGER       PRIMARY KEY,
    sale_day         SMALLINT      NOT NULL CHECK (sale_day BETWEEN 1 AND 31),
    sale_month       SMALLINT      NOT NULL CHECK (sale_month BETWEEN 1 AND 12),
    sale_year        SMALLINT      NOT NULL CHECK (sale_year BETWEEN 2021 AND 2024),
    day_name         VARCHAR(15)   NOT NULL,
    brand            VARCHAR(30)   NOT NULL,
    units_sold       INTEGER       NOT NULL CHECK (units_sold > 0),
    price_per_unit   NUMERIC(10,2) NOT NULL CHECK (price_per_unit >= 0),
    customer_name    VARCHAR(100)  NOT NULL,
    customer_age     SMALLINT      NOT NULL CHECK (customer_age BETWEEN 18 AND 100),
    city             VARCHAR(50)   NOT NULL,
    payment_method   VARCHAR(30)   NOT NULL,
    customer_ratings SMALLINT      NOT NULL CHECK (customer_ratings BETWEEN 1 AND 5),
    mobile_model     VARCHAR(50)   NOT NULL
);
select * from mobile_sales;

---1.Retrieve the top 10 highest-priced single unit transactions:-----
SELECT transaction_id, brand, mobile_model,price_per_unit
FROM mobile_sales
ORDER BY "price_per_unit" DESC
LIMIT 10;
----List all unique cities where sales occurred, sorted alphabetically:-----
SELECT DISTINCT city
FROM mobile_sales
ORDER BY city ASC;

---Filter high-volume UPI transactions in Mumbai:----
SELECT transaction_id, customer_name,brand, units_sold  , price_per_unit
FROM mobile_sales
WHERE city = 'Mumbai'
  AND payment_method  = 'UPI'
  AND units_sold  >= 5;

----Find all transactions for Apple or Samsung models priced above ₹50,000:----
select transaction_id,brand,price_per_unit
from mobile_sales
where brand IN ('Samsung','Apple')
	and price_per_unit >=50000;

----Calculate overall total units sold and average customer rating:----
SELECT 
    SUM(units_sold) AS total_units_sold,
    ROUND(AVG(customer_ratings), 2) AS avg_rating
FROM mobile_sales;

-----Search for all Redmi models using pattern matching:-------
SELECT transaction_id, mobile_model,  units_sold ,  city  
FROM mobile_sales
WHERE mobile_model LIKE 'Redmi%';

----Count total transactions for customers aged between 25 and 35:----
SELECT COUNT(*) AS young_adult_transactions
FROM mobile_sales
WHERE customer_name BETWEEN 25 AND 35;

----Calculate total revenue and units sold per Brand:----
SELECT 
     brand ,
    SUM(units_sold ) AS total_units,
    ROUND(SUM(units_sold  * price_per_unit)::numeric, 2) AS total_revenue
FROM mobile_sales
GROUP BY  brand
ORDER BY total_revenue DESC;

----Find cities generating more than ₹5 Crore (50,000,000) in total revenue:----
SELECT 
   city,
    COUNT(*) AS total_orders,
    ROUND(SUM(units_sold * price_per_unit)::numeric, 2) AS city_revenue
FROM mobile_sales
GROUP BY city 
HAVING SUM(units_sold * price_per_unit) > 50000000
ORDER BY city_revenue DESC;

----Clean the inconsistent Day Name column and count orders by standardized weekday:---
SELECT 
    CASE 
        WHEN  day_name  IN ('Mon', 'Monday') THEN 'Monday'
        WHEN  day_name  IN ('Tue', 'Tuesday') THEN 'Tuesday'
        WHEN  day_name  IN ('Wed', 'Wednesday') THEN 'Wednesday'
        WHEN  day_name  IN ('Thu', 'Thursday') THEN 'Thursday'
        WHEN  day_name  IN ('Fri', 'Friday') THEN 'Friday'
        WHEN  day_name  IN ('Sat', 'Saturday') THEN 'Saturday'
        WHEN  day_name  IN ('Sun', 'Sunday') THEN 'Sunday'
    END AS clean_day_name,
    COUNT(*) AS order_count
FROM mobile_sales
GROUP BY clean_day_name
ORDER BY order_count DESC;

-----Segment customers into age brackets and analyze average spend per transaction:----
SELECT 
    CASE 
        WHEN  customer_age < 25 THEN '18-24 (Gen Z)'
        WHEN  customer_age BETWEEN 25 AND 40 THEN '25-40 (Millennials)'
        ELSE '41+ (Gen X & Boomers)'
    END AS age_group,
    COUNT(*) AS transactions,
    ROUND(AVG( units_sold    * price_per_unit)::numeric, 2) AS avg_order_value
FROM mobile_sales
GROUP BY age_group
ORDER BY avg_order_value DESC;

-----Analyze payment method share (%) across all transactions:------
SELECT 
    payment_method,
    COUNT(*) AS txn_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM mobile_sales), 2) AS pct_share
FROM mobile_sales
GROUP BY payment_method
ORDER BY txn_count DESC;

----Year-over-year (YoY) revenue and order volume breakdown:----
SELECT 
    sale_year,
    COUNT(transaction_id) AS total_orders,
    SUM(units_sold) AS units_sold,
    ROUND(SUM(units_sold * price_per_unit)::numeric, 2) AS annual_revenue
FROM mobile_sales
GROUP BY sale_year
ORDER BY sale_year ASC;

----Identify mobile models with an average rating below 3.65:---
SELECT 
    brand ,
    "Mobile Model",
    COUNT(*) AS reviews,
    ROUND(AVG("Customer Ratings"), 2) AS avg_rating
FROM mobile_sales
GROUP BY "Brand", "Mobile Model"
HAVING AVG("Customer Ratings") < 3.65
ORDER BY avg_rating ASC;

---Reconstruct a proper SQL DATE from Year, Month, Day and find Q4 sales:---
SELECT 
    MAKE_DATE(sale_year, sale_month , sale_day ) AS sale_date,
    brand,
   mobile_model,
    ( units_sold  * price_per_unit ) AS revenue
FROM mobile_sales
WHERE sale_month IN (10, 11, 12)
ORDER BY sale_date DESC
LIMIT 20;


---Count low-rated (1 or 2 stars) vs. high-rated (4 or 5 stars) orders per Brand using conditional aggregation:
SELECT 
    brand ,
    SUM(CASE WHEN customer_ratings <= 2 THEN 1 ELSE 0 END) AS dissatisfied_orders,
    SUM(CASE WHEN customer_ratings >= 4 THEN 1 ELSE 0 END) AS satisfied_orders
FROM mobile_sales
GROUP BY brand   ;

-----Find repeat customer names with more than 8 orders and total spend above ₹15 Lakhs:
SELECT 
    customer_name,
    COUNT(*) AS purchase_count,
    ROUND(SUM(units_sold  *  price_per_unit)::numeric, 2) AS total_spent
FROM mobile_sales
GROUP BY customer_name
HAVING COUNT(*) > 8 
   AND SUM(units_sold  *  price_per_unit) > 1500000
ORDER BY total_spent DESC;

----Rank the top 2 highest-revenue mobile models within each Brand (DENSE_RANK):
WITH model_sales AS (
    SELECT 
       brand,
        mobile_model ,
        ROUND(SUM(units_sold  * price_per_unit )::numeric, 2) AS revenue,
        DENSE_RANK() OVER (
            PARTITION BY brand 
            ORDER BY SUM(units_sold  * price_per_unit ) DESC
        ) AS brand_rank
    FROM mobile_sales
    GROUP BY brand,  mobile_model 
)
SELECT * FROM model_sales WHERE brand_rank <= 2;

----Calculate Month-over-Month (MoM) revenue growth percentage (LAG):
WITH monthly_rev AS (
    SELECT 
		sale_year,
        sale_month,
        ROUND(SUM(units_sold  * price_per_unit)::numeric, 2) AS revenue
    FROM mobile_sales
    GROUP BY  sale_year, sale_month
)
SELECT 
    sale_year,
   sale_month,
    revenue,
    LAG(revenue) OVER (ORDER BY  sale_year, sale_month) AS prev_month_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY  sale_year, sale_month)) * 100.0 / 
        NULLIF(LAG(revenue) OVER (ORDER BY  sale_year, sale_month), 0), 2
    ) AS mom_growth_pct
FROM monthly_rev;

----Compute cumulative (running) revenue across each year (SUM() OVER):
WITH monthly_rev AS (
    SELECT 
        sale_year,
       sale_month,
        ROUND(SUM(units_sold  * price_per_unit)::numeric, 2) AS monthly_revenue
    FROM mobile_sales
    GROUP BY sale_year, sale_month
)
SELECT 
    sale_year,
    sale_month,
    monthly_revenue,
    SUM(monthly_revenue) OVER (
        PARTITION BY sale_year 
        ORDER BY sale_month
    ) AS ytd_cumulative_revenue
FROM monthly_rev;

---Calculate each City's revenue contribution % within its respective Brand:
SELECT 
    brand,
    city,
    ROUND(SUM(units_sold  * price_per_unit)::numeric, 2) AS city_brand_rev,
    ROUND(
        SUM(units_sold  * price_per_unit) * 100.0 / 
        SUM(SUM(units_sold  * price_per_unit)) OVER (PARTITION BY brand), 2
    ) AS pct_of_brand_total
FROM mobile_sales
GROUP BY brand, city
ORDER BY brand, pct_of_brand_total DESC;

---Find transactions whose unit price exceeds their own Mobile Model's average price (Correlated Subquery / Window):
WITH model_avg AS (
    SELECT 
        transaction_id,
        mobile_model ,
        price_per_unit,
        ROUND(AVG(price_per_unit) OVER (PARTITION BY mobile_model)::numeric, 2) AS avg_model_price
    FROM mobile_sales
)
SELECT *
FROM model_avg
WHERE price_per_unit > avg_model_price * 1.5
ORDER BY price_per_unit DESC;

---Segment all 3,835 transactions into 4 revenue quartiles (NTILE(4)):
WITH quartiles AS (
    SELECT 
        transaction_id,
        (units_sold * price_per_unit) AS order_value,
        NTILE(4) OVER (ORDER BY (units_sold  * price_per_unit)) AS revenue_quartile
    FROM mobile_sales
)
SELECT 
    revenue_quartile,
    COUNT(*) AS txn_count,
    ROUND(MIN(order_value)::numeric, 2) AS min_val,
    ROUND(MAX(order_value)::numeric, 2) AS max_val
FROM quartiles
GROUP BY revenue_quartile
ORDER BY revenue_quartile;

---Identify the most preferred payment method per City (FIRST_VALUE or ROW_NUMBER):
WITH city_payment AS (
    SELECT 
        city,
       payment_method,
        COUNT(*) AS usage_count,
        ROW_NUMBER() OVER (PARTITION BY city ORDER BY COUNT(*) DESC) AS rn
    FROM mobile_sales
    GROUP BY city, payment_method
)
SELECT city, payment_method AS top_payment_method, usage_count
FROM city_payment
WHERE rn = 1
ORDER BY usage_count DESC;

---Calculate a 3-month moving average of units sold:
WITH monthly_units AS (
    SELECT 
        sale_year,
        sale_month,
        SUM(units_sold) AS units
    FROM mobile_sales
    GROUP BY sale_year, sale_month
)
SELECT 
    sale_year,
   sale_month,
    units,
    ROUND(AVG(units) OVER (
        ORDER BY sale_year, sale_month 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS rolling_3m_avg_units
FROM monthly_units;

---Measure time gap (in days) between consecutive purchases for repeat customer names (LAG with MAKE_DATE):
WITH customer_dates AS (
    SELECT 
        customer_name ,
        transaction_id,
        MAKE_DATE(sale_year, sale_month, day_name ) AS purchase_date
    FROM mobile_sales
),
gaps AS (
    SELECT 
        customer_name ,
        purchase_date,
        purchase_date - LAG(purchase_date) OVER (
            PARTITION BY customer_name 
            ORDER BY purchase_date
        ) AS days_since_last_order
    FROM customer_dates
)
SELECT *
FROM gaps
WHERE days_since_last_order IS NOT NULL
ORDER BY customer_name , purchase_date;

----Build a Brand-by-Payment-Method Pivot Matrix using FILTER (PostgreSQL):
SELECT 
    brand,
    ROUND(SUM(units_sold  * price_per_unit) FILTER (WHERE payment_method = 'UPI')::numeric, 2) AS upi_rev,
    ROUND(SUM(units_sold  * price_per_unit) FILTER (WHERE payment_method = 'Credit Card')::numeric, 2) AS cc_rev,
    ROUND(SUM(units_sold  * price_per_unit) FILTER (WHERE payment_method = 'Debit Card')::numeric, 2) AS dc_rev,
    ROUND(SUM(units_sold  * price_per_unit) FILTER (WHERE payment_method = 'Cash')::numeric, 2) AS cash_rev
FROM mobile_sales
GROUP BY brand
ORDER BY brand;