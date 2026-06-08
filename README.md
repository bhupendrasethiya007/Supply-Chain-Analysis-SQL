# Retail & Supply Chain Analytics

## Table of Contents

* [Project Overview](#project-overview)
* [Dataset Information](#dataset-information)
* [SQL Analysis Questions & Queries](#sql-analysis-questions--queries)
* [SQL Concepts Used](#sql-concepts-used)
* [Business Impact](#business-impact)
* [Technologies Uesd](#technologies-used)
* [Project Structure](#project-structure)
* [Author](#author)



## Project Overview

This project focuses on analyzing retail sales and supply chain performance using PostgreSQL. The objective is to uncover business insights related to sales growth, profitability, customer behavior, product returns, shipping performance, and customer retention.

---
## Dataset Information

### sales_data1 (Fact Table)

**Rows:** 9,900+
**Columns:** 23

| Column Name         | Description                |
| ------------------- | -------------------------- |
| row_id              | Unique row identifier      |
| order_id            | Unique order identifier    |
| order_date          | Order placement date       |
| ship_date           | Product shipping date      |
| ship_mode           | Shipping method used       |
| customer_id         | Unique customer identifier |
| customer_name       | Customer name              |
| segment             | Customer segment           |
| country             | Country                    |
| city                | Customer city              |
| state               | Customer state             |
| postal_code         | Postal code                |
| region              | Sales region               |
| retail_sales_people | Sales representative       |
| product_id          | Unique product identifier  |
| category            | Product category           |
| sub_category        | Product sub-category       |
| product_name        | Product name               |
| returned            | Return status (Yes/No)     |
| sales               | Sales amount               |
| quantity            | Quantity ordered           |
| discount            | Discount applied           |
| profit              | Profit earned              |

### date_dimension (Dimension Table)

**Rows:** 1,600+
**Columns:** 13

*Contains calendar attributes used for time-series analysis such as Year-over-Year (YoY), Month-over-Month (MoM), quarterly trends, and rolling averages.*


---

## SQL Analysis Questions & Queries

## Module 1: Basics & Time Series Analysis

### 1. Year-over-Year Total Sales and Profit

**Business Question:** What are the total sales and total profit generated each year?

```sql
SELECT d.year_,
       SUM(s.sales) AS total_sales,
       SUM(s.profit) AS total_profit
FROM date_dimension d
JOIN sales_data1 s
ON d.date_ = s.order_date
GROUP BY d.year_
ORDER BY d.year_;
```

---

### 2. Seasonality Analysis (Weekend Effect)

**Business Question:** On which day of the week are the highest sales generated and the highest returns recorded?

```sql
SELECT d.day_name,
       SUM(s.sales) AS total_sales,
       SUM(
           CASE
               WHEN s.returned = 'Yes' THEN 1
               ELSE 0
           END
       ) AS total_returns
FROM sales_data1 s
JOIN date_dimension d
ON s.order_date = d.date_
GROUP BY d.day_name
ORDER BY total_sales DESC;
```

---

### 3. Best Performing Quarter

**Business Question:** Which quarter generated the highest sales?

```sql
SELECT d.quarter_year,
       SUM(s.sales) AS total_sales
FROM sales_data1 s
JOIN date_dimension d
ON s.order_date = d.date_
GROUP BY d.quarter_year
ORDER BY total_sales DESC
LIMIT 1;
```

---

# Module 2: Profit Bleeding Analysis

### 4. The Discount Trap

**Business Question:** Which categories and sub-categories suffer profit losses due to high discounts?

```sql
SELECT category,
       sub_category,
       SUM(sales) AS total_sales,
       SUM(profit) AS total_profit,
       ROUND(AVG(discount) * 100, 2) AS average_discount
FROM sales_data1
GROUP BY category, sub_category
ORDER BY total_profit;
```

---

### 5. Regional Return Analysis

**Business Question:** Which region has the highest return rate?

```sql
SELECT region,
       COUNT(*) AS total_orders,
       SUM(
           CASE
               WHEN returned = 'Yes' THEN 1
               ELSE 0
           END
       ) AS total_returns,
       ROUND(
           SUM(
               CASE
                   WHEN returned = 'Yes' THEN 1
                   ELSE 0
               END
           ) * 100.0 / COUNT(*),
           2
       ) AS return_percentage
FROM sales_data1
GROUP BY region
ORDER BY total_returns DESC;
```

---

### 6. Top 10 Loss-Making Customers

**Business Question:** Which customers generate the highest losses?

```sql
SELECT customer_id,
       customer_name,
       SUM(sales) AS total_sales,
       SUM(profit) AS total_loss
FROM sales_data1
GROUP BY customer_id, customer_name
HAVING SUM(profit) < 0
ORDER BY total_loss
LIMIT 10;
```

---

# Module 3: Supply Chain & Logistics

### 7. Shipping Delay Analysis

**Business Question:** What is the average delivery time for each shipping mode?

```sql
SELECT ship_mode,
       ROUND(AVG(ship_date - order_date), 2) AS average_shipping_days
FROM sales_data1
GROUP BY ship_mode
ORDER BY average_shipping_days;
```

---

### 8. Late Delivery Impact

**Business Question:** Do late deliveries lead to higher product returns?

```sql
SELECT CASE
           WHEN ship_date - order_date > 3 THEN 'Late'
           ELSE 'On Time'
       END AS delivery_status,
       COUNT(*) AS total_orders,
       SUM(
           CASE
               WHEN returned = 'Yes' THEN 1
               ELSE 0
           END
       ) AS total_returns,
       ROUND(
           SUM(
               CASE
                   WHEN returned = 'Yes' THEN 1
                   ELSE 0
               END
           ) * 100.0 / COUNT(*),
           2
       ) AS return_rate
FROM sales_data1
GROUP BY delivery_status;
```

---

### 9. Salesperson Performance Analysis

**Business Question:** Which salesperson generates the highest sales and lowest profit margin?

```sql
SELECT retail_sales_people,
       SUM(sales) AS total_sales,
       SUM(profit) AS total_profit,
       ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin
FROM sales_data1
GROUP BY retail_sales_people
ORDER BY profit_margin;
```
# Module 4: Advanced Analytics (Window Functions & CTEs)

## 10. Pareto Principle (80/20 Rule)

**Business Question:** Do the top customers contribute 80% of total sales? Use cumulative sales and cumulative percentage to identify the customers responsible for 80% of revenue.

```sql
WITH top_10_cust AS (
    SELECT customer_id,
           customer_name,
           SUM(sales) AS total_sales
    FROM sales_data1
    GROUP BY customer_id, customer_name
),
rank_customers AS (
    SELECT customer_id,
           customer_name,
           total_sales,
           SUM(total_sales) OVER(ORDER BY total_sales DESC) AS running_sum,
           SUM(total_sales) OVER() AS overall_sales
    FROM top_10_cust
)
SELECT *
FROM (
    SELECT *,
           ROUND(running_sum * 100.0 / overall_sales, 2) AS cumulative_percentage
    FROM rank_customers
) t
WHERE cumulative_percentage <= 80
ORDER BY total_sales DESC;
```

---

## 11. Customer Churn Analysis

**Business Question:** Which customers purchased during 2015 and 2016 but did not make any purchase in 2017?

```sql
WITH customer_churn AS (
    SELECT d.year_,
           s.customer_id
    FROM sales_data1 s
    JOIN date_dimension d
    ON s.order_date = d.date_
    GROUP BY d.year_, s.customer_id
)

SELECT DISTINCT customer_id
FROM customer_churn
WHERE customer_id IN (
    SELECT customer_id
    FROM customer_churn
    WHERE year_ IN (2015, 2016)
)
AND customer_id NOT IN (
    SELECT customer_id
    FROM customer_churn
    WHERE year_ = 2017
);
```

---

## 12. 30-Day Moving Average

**Business Question:** What is the 30-day rolling average of daily sales?

```sql
WITH daily_sales AS (
    SELECT d.date_,
           SUM(s.sales) AS total_sales
    FROM sales_data1 s
    JOIN date_dimension d
    ON s.order_date = d.date_
    GROUP BY d.date_
)

SELECT date_,
       total_sales,
       ROUND(
           AVG(total_sales) OVER (
               ORDER BY date_
               ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
           ),
           2
       ) AS rolling_30_day_avg
FROM daily_sales
ORDER BY date_;
```

---

## 13. Customer Segmentation (Mini RFM)

**Business Question:** Classify customers as VIP, Regular, or One-Time Buyers based on purchase behavior.

```sql
SELECT customer_id,
       customer_name,
       COUNT(DISTINCT order_id) AS total_orders,
       CASE
           WHEN COUNT(DISTINCT order_id) = 1
                THEN 'One-Time Buyer'
           WHEN SUM(sales) > 5000
                THEN 'VIP'
           ELSE 'Regular'
       END AS customer_segment
FROM sales_data1
GROUP BY customer_id, customer_name;
```

---

## 14. Month-over-Month (MoM) Growth

**Business Question:** What is the monthly sales growth percentage compared to the previous month?

```sql
WITH monthly_sales AS (
    SELECT d.year_,
           d.month_num,
           SUM(s.sales) AS total_sales
    FROM sales_data1 s
    JOIN date_dimension d
    ON s.order_date = d.date_
    GROUP BY d.year_, d.month_num
),
previous_month_sales AS (
    SELECT year_,
           month_num,
           total_sales,
           LAG(total_sales) OVER (
               ORDER BY year_, month_num
           ) AS previous_sales
    FROM monthly_sales
)

SELECT *,
       ROUND(
           ((total_sales - previous_sales) /
            previous_sales) * 100,
           2
       ) AS mom_growth_percentage
FROM previous_month_sales;
```

---

## 15. Most Profitable Route

**Business Question:** Which city and state combinations generate the highest profit per order?

```sql
WITH most_profitable AS (
    SELECT state1,
           city,
           COUNT(order_id) AS total_orders,
           SUM(profit) AS total_profit,
           ROUND(
               SUM(profit) / COUNT(order_id),
               2
           ) AS profit_per_order
    FROM sales_data1
    GROUP BY state1, city
    HAVING COUNT(order_id) >= 10
)

SELECT *
FROM most_profitable
ORDER BY profit_per_order DESC;
```

---

## SQL Concepts Used

### Joins

* INNER JOIN

### Aggregate Functions

* SUM()
* AVG()
* COUNT()
* ROUND()

### Conditional Logic

* CASE WHEN

### Window Functions

* LAG()
* SUM() OVER()
* AVG() OVER()

### Common Table Expressions (CTEs)

* Multi-step query logic
* Improved query readability

---

## Business Impact

* **2017 was the most profitable year**, generating total sales of **733,215.19** and achieving a **12.74% profit margin**.
* **Friday recorded the highest sales volume**, indicating a strong weekend sales effect.
* **Pareto Analysis revealed that 395 out of 793 customers (49.81%) generated 80% of total sales**.
* **The customer churn rate was 12.23%**, with **97 out of 793 customers** becoming inactive.
* **Late deliveries had a return rate of 7.60%**, while **on-time deliveries recorded a return rate of 8.69%**.

---
## Technologies Used

* **Excel** - Data cleaning 
* **PostgreSQL** – Database management and data analysis.
* **GitHub** – Version control and project documentation.

## Project Structure

```text
Retail-Supply-Chain-Analytics/
│
├── sales_data1.csv
├── date_dimension.csv
├── Retail_Supply_Chain_Analysis.sql
└── README.md
```

---

## Author

**Bhupendra Sethiya**
