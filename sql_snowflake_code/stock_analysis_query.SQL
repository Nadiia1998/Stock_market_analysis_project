---- This query is created to answer the following questions:
-- 1. Stock weight in the portfolio
-- 2. Total shares, total cost, and average cost per company
-- 3. Total spend (USD & PLN)
-- 4. Total portfolio value
-- 5. Monthly investment trend
-- 6. Earnings from non-invested funds

        
USE ROLE ACCOUNTADMIN;

USE WAREHOUSE stock_whs;

USE DATABASE STOCKS_ANALYSIS_DB;

USE SCHEMA STOCKS_SCHEMA;

/* Create a view to calculate the stock purchase price in PLN.
      This query takes information from the stocks table when shares are bought in PLN,
      and from the stock_buy_in_usd table when shares are bought in USD
*/
CREATE OR REPLACE  VIEW shares_buy as ( 
    SELECT  time::date as stock_buy,
        ticker,
        no_of_shares,
        price_per_share ,
        no_of_shares*price_per_share as usd_spent,
        no_of_shares*price_per_share*usd as pln_spent
    FROM stocks as s
    LEFT JOIN currency_rates as c
    ON s.time::date= CASE
                        WHEN DAYOFWEEK(s.time::date) = 1 
                            THEN DATEADD(DAY, 3, TO_DATE(TO_VARCHAR(c.data), 'YYYYMMDD')) 
                        WHEN s.time::date in('2024-12-27','2024-05-31') 
                            THEN DATEADD(DAY, 3, TO_DATE(TO_VARCHAR(c.data), 'YYYYMMDD')) --non_working day in Poland;
                        ELSE DATEADD(DAY, 1, TO_DATE(TO_VARCHAR(data), 'YYYYMMDD')) -- default +1
                   END
    WHERE action in ('Market buy', 'Limit buy') and currency_result ='PLN'
    UNION ALL
    SELECT *
    FROM stock_buy_in_usd
    ORDER BY stock_buy
    );

    

--  stock’s weight in the portfolio;
SELECT ticker,
       ROUND(total_stock_amount_per_company,2),
       ROUND(total_stock_amount_per_company/ total_stock_amount * 100, 2)::text || '%' AS stock_share_percent,
FROM (
    SELECT ticker,
           SUM(no_of_shares*price_per_share) AS total_stock_amount_per_company,
           SUM(total_stock_amount_per_company) OVER () AS total_stock_amount
    FROM shares_buy
    GROUP BY ticker
) AS t
ORDER BY total_stock_amount_per_company desc;





-- Total Shares, Total Cost & Average Cost per Company
SELECT ticker,
        ROUND(SUM(no_of_shares),3) as total_shares,
        ROUND(AVG(price_per_share),3) as average_price_per_share,
        ROUND(SUM(usd_spent),3) as total_usd_spent,
        ROUND(SUM(pln_spent),3) as total_pln_spent
FROM shares_buy
GROUP BY ALL
ORDER BY total_shares desc;


-- Total Spend (USD & PLN)
SELECT ROUND(SUM(usd_spent),2) as total_spent_usd,
        ROUND(SUM(pln_spent),2) as total_spent_pln
FROM shares_buy;


-- Total Portfolio Value;
SELECT SUM(total) AS total_deposit_pln
FROM stocks
WHERE action='Deposit';

-- Monthly Investment Trend;
SELECT TRUNC(time,'MONTH')::DATE as deposid_date,
        SUM(total) AS deposit_pln
FROM stocks
WHERE action='Deposit'
GROUP BY ALL
ORDER BY deposid_date;

-- Earnings from Non-Invested Funds;
SELECT SUM(total) as total_interest_on_cash_pln
FROM stocks
WHERE action='Interest on cash';
