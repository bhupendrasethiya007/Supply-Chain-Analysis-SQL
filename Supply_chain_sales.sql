----------------------------------------------------------------------

----------------RETAIL AND SUPPLY CHAIN ANLYTICS----------------------

----------------------------------------------------------------------

----------------------------------------------------------------------
------------------CREATE DATE TABLE ----------------------------------
----------------------------------------------------------------------
CREATE TABLE date_dimension (
    date_               DATE,
    year_               INT,
    quarter_num         INT,
    quarter_name        VARCHAR(2),
    quarter_year        VARCHAR(10),
    month_num           INT,
    month_name          VARCHAR(3),
    month_year          VARCHAR(7),
    week_of_year_num    INT,
    week_of_year        VARCHAR(10),
    day_of_week_num     INT,
    day_name            VARCHAR(10)

);
-----------------------------------------------------------------------
------------------CREATE SALES TABLE----------------------------------
-----------------------------------------------------------------------
CREATE TABLE sales_data1 (
    row_id              INT,
    order_id            VARCHAR(30),
    order_date          DATE,
    ship_date           DATE,
    ship_mode           VARCHAR(50),
    customer_id         VARCHAR(20),
    customer_name       VARCHAR(100),
    segment             VARCHAR(50),
    country             VARCHAR(100),
    city                VARCHAR(100),
    state1               VARCHAR(100),
    postal_code         VARCHAR(20),
    region              VARCHAR(50),
    retail_sales_people VARCHAR(100),
    product_id          VARCHAR(50),
    category            VARCHAR(50),
    sub_category        VARCHAR(50),
    product_name        TEXT,
    returned            VARCHAR(10),
    sales               NUMERIC(10,2),
    quantity            INT,
    discount            NUMERIC(5,2),
    profit              NUMERIC(10,2)
);

------------import csv file------------------------------

COPY sales_data1
FROM 'D:\sales.csv'
DELIMITER ','
CSV HEADER;

------------------------------------------------------------

--------MODUEL 1 BASICS AND TIME SERIES----------------------

---Q1.  Year Over Year Total sales and Profit

      SELECT d.year_ ,SUM(s.sales) as Total_sales,SUM(s.profit) as Total_profit
	  FROM 
	  Date_dimension d
	  JOIN
	  sales_data1 s
	  ON d.date_=s.order_date
	  GROUP BY d.year_
	  ORDER BY year_

---Q2.  Seasonality (The Weekend Effect) 
       "On which day of the week are the highest number of returns recorded?"
	   "On which day of the week are the highest sales generated?"

	   SELECT d.day_name ,SUM(s.sales)  as total_sales,
	   SUM
	   (CASE 
	               WHEN s.returned ='Yes' THEN 1
	               ELSE 0
		           END)
				   AS total_returned
	   FROM
	   sales_data1 s
	   JOIN
	   date_dimension d
	   ON s.order_date=d.date_
	   GROUP BY d.day_name
	   ORDER BY total_sales desc

---Q3. The Best Quarter

     SELECT d.quarter_year ,SUM(s.sales) AS Total_sales
	 FROM 
	 sales_data1 s
	 JOIN 
	 date_dimension d
	 ON 
	 s.order_date=d.date_
	 GROUP BY d.quarter_year
	 ORDER BY SUM(s.sales) DESC
	 LIMIT 1
	  

--------------------------------------------------------------  

-----------MODUEL 2 : Profit Bleeding (Where are we losing money?)

----Q.1 The Discount Trap
     "Categories and Sub-Categories with Negative Profit Due to Discounts"


	 SELECT category,sub_category,
	             SUM(sales) as total_sales,
	             SUM(profit) as Total_Profit,
				 ROUND(AVG(discount)*100.0,2) AS Average_discount
     FROM 
     sales_data1
	 GROUP BY category,sub_category
	 ORDER BY SUM(profit)

---Q.2  The Return Problem
       "Regional Product Return Analysis and Return Rate (%)"

	   SELECT region, 
	   COUNT(*) AS total_orders,
	   SUM(CASE WHEN 
	                  returned ='Yes' THEN 1 ELSE 0 END) AS return_status,
	   round(SUM(CASE WHEN 
	                  returned ='Yes' THEN 1 ELSE 0 END )*100.0/
					  COUNT(*) ,2) as  return_percentage		  
					  FROM sales_data1
					  GROUP BY region
					  ORDER BY return_status DESC


---Q.3 Top 10 Loss-Making Customers
       "Identify the top 10 least profitable customers based on total profit."
	   
	  SELECT customer_id,customer_name,
	  SUM(sales) AS total_sales,
	  SUM(Profit) as total_loss
	  FROM sales_data1
	  GROUP BY customer_id,customer_name
	  HAVING SUM(profit)< 0
	  ORDER BY total_loss
	  LIMIT 10


--------------------------------------------------------------------

--------------Module 3: Advanced Supply Chain & Logistics------------

---Q.1 Shipping Delay Analysis
       "What is the average delivery time (in days) for each ship mode    
	   (Standard Class, First Class, Second Class, Same Day, etc.)?"

	  SELECT ship_mode ,round(AVG(ship_date - order_date),2) as average_ship_days
	  FROM sales_data1
	  GROUP BY ship_mode
	  ORDER BY average_ship_days
	  
---Q.2 	Late Delivery Impact
        "Do customers return products more frequently when delivery is late (more than 3 days)? 
		Compare return rates between On-Time and Late deliveries."

        SELECT CASE WHEN ship_date - order_date >3 then 'late' ELSE 'on time' END as Delivery_Status,
		COUNT(*) AS TOTAL_ORDERS,
		SUM(CASE WHEN returned ='Yes' THEN 1 ELSE 0 END) AS TOTAL_RETURN,
		ROUND(SUM(CASE WHEN  returned ='Yes' THEN 1 ELSE 0 END) *100.0/
        COUNT(*),2) AS return_rate
		FROM 
		sales_data1 
		GROUP BY  Delivery_Status

---Q.3 Salesperson Performance
       "Which salesperson generates the highest sales, and whose profit margin (%) is the lowest?"
	   
        SELECT retail_sales_people,
		SUM(sales) as total_sales,
		SUM(profit) as total_profit,
		ROUND((SUM(profit)/SUM(sales))*100 ,2)as profit_margin
		FROM sales_data1
		GROUP BY retail_sales_people
		ORDER BY profit_margin 

------------------------------------------------------------------------

------------MODUEL 4: The "WOW" Factors (Window Functions & CTEs)

---Q.1 The Pareto Principle (80/20 Rule)
       "Do our top customers contribute 80% of total sales? 
	   Use cumulative sales and cumulative percentage to identify 
	   the customers responsible for 80% of revenue (Pareto Principle)." 

      WITH top_10_cust AS(
       SELECT customer_id,customer_name,
	   SUM(sales) as total_sales
	   FROM 
	   sales_data1
	   GROUP BY 1,2
	   ),
	   rank_customers as(
        SELECT customer_id,customer_name,total_sales,
		SUM(total_sales) OVER(ORDER BY total_sales DESC) AS running_sum,
		SUM(total_sales) OVER() AS Overall_sales
		FROM top_10_cust
	   ) 
	   SELECT * FROM(
	   SELECT *,ROUND( running_sum * 100.0 / Overall_sales,2)
	   AS prct
	   FROM 
	   rank_customers) t
	   WHERE prct<=80
	   ORDER BY total_sales DESC
	   
	   
---Q.2  Customer Churn
    
       WITH customer_churn AS
(
      SELECT
        d.year_ AS year_,
        s.customer_id
      FROM sales_data1 s
       JOIN date_dimension d
        ON s.order_date = d.date_
       GROUP BY d.year_, s.customer_id
)

        SELECT DISTINCT customer_id
        FROM customer_churn
        WHERE customer_id IN
(
       SELECT customer_id
       FROM customer_churn
       WHERE year_ IN (2015, 2016)
)
     AND customer_id NOT IN
(
    SELECT customer_id
    FROM customer_churn
    WHERE year_ = 2017
);


---Q.3	30-Day Moving Average

    WITH daily_sales AS(
    SELECT d.date_,
    SUM(s.sales) AS total_sales
	FROM 
	sales_data1 s
	JOIN
	date_dimension d
	ON s.order_date=d.date_
	GROUP BY 1
	)
	SELECT date_,total_sales,
	ROUND(AVG(total_sales) OVER(order by date_ ROWS BETWEEN 29 PRECEDING AND CURRENT ROW),2)  AS _30_days_rolling_avg
	FROM daily_sales
	ORDER BY date_
	
--- Q.4 Customer Segmentation (Mini RFM)
       SELECT customer_id, customer_name,
	  COUNT(
	  DISTINCT(order_id)) as total_orders,
	  CASE
	  WHEN COUNT(
	  DISTINCT(order_id))=1
	  THEN 'One_time_buyer'
	     WHEN SUM(sales) > 5000 THEN 'VIP'
		ELSE 'Regular'
		END AS customer_segment
		FROM sales_data1
		GROUP BY 1,2
		
---  Q.5 Month-over-Month (MoM) Growth
      WITH monthly_sales AS(
       SELECT d.year_,  d.month_num,
	    SUM(s.sales) AS total_sales
		FROM sales_data1 s
		JOIN 
		date_dimension d
		ON s.order_date=d.date_
		GROUP BY 1,2
		ORDER BY 1,2
	  ), Previous_month_sales AS(
	  SELECT  
	  year_, month_num, 
	  total_sales ,
	  LAG(total_sales) 
	  OVER(
	  ORDER BY year_ , month_num
	  )
	  as pre
	  FROM monthly_sales)
	  SELECT * ,ROUND(
	  (
	  (total_sales - pre)/pre*100.0)
	  ,2
	  ) as mom
	  FROM Previous_month_sales
	  
---  Q.6 Most Profitable Route	
	 
	WITH most_profitable AS(
     SELECT state1, city,
	 COUNT(order_id) AS total_orders,
	 SUM(profit) as total_profit,
	 ROUND(SUM(profit)/COUNT(order_id),2) AS profit_per_order
	 FROM sales_data1
	 GROUP BY 1,2
	 HAVING COUNT(order_id)>=10
	 ORDER BY profit_per_order DESC
	)
	SELECT * FROM most_profitable
		




	   
select count(*) from sales_data1
SELECT count(*) FROM DATE_DIMENSION


