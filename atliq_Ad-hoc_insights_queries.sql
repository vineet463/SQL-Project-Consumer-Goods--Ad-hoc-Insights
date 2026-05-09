

    -- 1. List of markets in which customer "Atliq Exlcusive" operates business in the APAC region

SELECT
    DISTINCT market FROM  dim_customer
WHERE region = 'APAC' AND customer = "Atliq Exclusive";

    -- 2. What is the percentage of unique products increase in 2021 vs 2020?

 WITH product_2020 AS (
    SELECT COUNT(DISTINCT product_code) AS unique_products_2020
    FROM fact_sales_monthly
    WHERE fiscal_year = 2020
),
product_2021 AS (
    SELECT COUNT(DISTINCT product_code) AS unique_products_2021
    FROM fact_sales_monthly
    WHERE fiscal_year = 2021
)

SELECT 
    Up20.unique_products_2020,
    Up21.unique_products_2021,
    ROUND(
        (Up21.unique_products_2021 - Up20.unique_products_2020) 
        * 100.0 / Up20.unique_products_2020, 2) AS percentage_chg
FROM product_2020 Up20
CROSS JOIN product_2021 Up21;


-- 3. A report on all unique products for each segment, sorted in descending order

SELECT segment, count(DISTINCT product_code) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;

-- 4. segment wise unique product percentage change

with product_2020 as
( select p.segment,count(distinct f.product_code) as product_count_2020
from fact_sales_monthly f
join dim_product p
on f.product_code=p.product_code
where fiscal_year=2020
group by p.segment
),
 product_2021 as
 ( select p.segment,count(distinct f.product_code) as product_count_2021
from fact_sales_monthly f
join dim_product p
on f.product_code=p.product_code
where fiscal_year=2021
group by p.segment
)
select 
Year20.segment,
    Year20.product_count_2020,
    Year21.product_count_2021,
    (Year21.product_count_2021 - Year20.product_count_2020) AS difference
FROM product_2020 Year20
JOIN product_2021 Year21 
    ON Year20.segment = Year21.segment
ORDER BY difference DESC;

-- 5. Products with highest and lowest manufacturing cost

SELECT 
    p.product_code,
    p.product,
    fmc.manufacturing_cost
FROM fact_manufacturing_cost fmc
JOIN dim_product p
    ON fmc.product_code = p.product_code
JOIN total_cost as tc
    ON fmc.manufacturing_cost IN (tc.max_cost, tc.min_cost);

-- 6. A report which contains top 5 customers who received an average high pre_invoice_discount_pct 
   for the fiscal_year 2021 and in the Indian market

select d.customer_code,c.customer,
concat(round(avg(d.pre_invoice_discount_pct)*100,2),"%") as average_discount_percentage
from dim_customer  c
join fact_pre_invoice_deductions  d
on c.customer_code=d.customer_code
where fiscal_year=2021 and market= "India"
group by d.customer_code,c.customer
order by avg(d.pre_invoice_discount_pct) desc
limit 5;

-- 7. A complete report of Gross sales amount for the customer "Atliq Exclusive" for each month

select
month(f.date) as Month,
year(f.date) as Year,
round(sum(f.sold_quantity*gp.gross_price),2) as Gross_Sales_Amount
from fact_sales_monthly f
join fact_gross_price gp
on f.product_code=gp.product_code
and f.fiscal_year=gp.fiscal_year

join dim_customer c
on f.customer_code=c.customer_code
	where c.customer= "Atliq Exclusive"
    group by year(f.date),
    month(f.date)
    order by year;

-- 8. 2020 Quarter with maximum quantities sold

 Select CASE
    when month(date) in (9,10,11) then 'Q1'
   when month(date) in (12,1,2) then 'Q2'
   when month(date) in (3,4,5) then 'Q3'
   else 'Q4'
   end as quarters,
   sum(sold_quantity) as total_quantity_sold
from fact_sales_monthly 
where fiscal_year =2020
group by quarters
order by total_quantity_sold desc;

-- 9. Channel with more gross sales in 2021 and percentage contributions

WITH Channel_sales AS (
      SELECT c.channel,sum(f.sold_quantity * gp.gross_price) AS gross_sales
  FROM
  fact_sales_monthly f 
  JOIN fact_gross_price gp 
  ON f.product_code = gp.product_code
  and f.fiscal_year=gp.fiscal_year
  JOIN dim_customer c 
  ON f.customer_code = c.customer_code
  WHERE f.fiscal_year= 2021
  GROUP BY c.channel
)
select channel,
  round(gross_sales/1000000,2) AS gross_sales_in_millions,
  round(gross_sales/sum(gross_sales) OVER()*100,2) AS percentage 
FROM channel_sales 
order by gross_sales desc;

-- 10. Top 3 products  in each division that has high total_sold_quantity for fiscal year 2021

select
    monthname(f.date) as Month,
    year(f.date) as Year,
    round(sum(f.sold_quantity * gp.gross_price) / 1000000, 2) as Gross_Sales_Millions
from fact_sales_monthly f
join fact_gross_price gp
    on f.product_code = gp.product_code
    and f.fiscal_year = gp.fiscal_year
join dim_customer c
    on f.customer_code = c.customer_code
where c.customer = "Atliq Exclusive"
group by year(f.date), month(f.date), monthname(f.date)
order by year(f.date), month(f.date);
    




