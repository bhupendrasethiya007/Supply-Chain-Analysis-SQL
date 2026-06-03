# Retail & Supply Chain Analytics

## Project Overview

This project focuses on analyzing retail sales and supply chain performance using PostgreSQL. The objective is to uncover business insights related to sales growth, profitability, customer behavior, product returns, shipping performance, and customer retention.

---

## Dataset Information

This project uses two datasets:

* **sales_data1** containing **23 columns** and **9,900+ retail sales records**.
* **date_dimension** containing **13 columns** and used for time-series analysis such as YoY, MoM, and trend analysis.

---

## Business Problems

 Q1. Year-over-Year (YoY) Sales and Profit Analysis

 Q2. Day-wise Sales and Return Analysis

 Q3. Best Performing Quarter

 Q4. Discount Impact Analysis

 Q5. Regional Return Rate Analysis

 Q6. Top 10 Loss-Making Customers

 Q7. Average Delivery Time by Ship Mode

 Q8. Late Delivery vs Product Returns

 Q9. Salesperson Performance Analysis

 Q10. Pareto Principle (80/20 Rule)

 Q11. Customer Churn Analysis

 Q12. 30-Day Rolling Average Analysis

 Q13. Customer Segmentation

 Q14. Month-over-Month (MoM) Sales Growth

 Q15. Most Profitable Routes

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
