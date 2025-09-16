USE ROLE ACCOUNTADMIN;

USE WAREHOUSE stock_whs;

USE DATABASE STOCKS_ANALYSIS_DB;

USE SCHEMA STOCKS_SCHEMA;


-- Create a view to calculate the month-over-month change in stock price;
CREATE  OR REPLACE VIEW change_share_amound_MOM AS (
WITH cte_month_buy AS (
    SELECT 
        time::DATE AS stock_buy,
        ticker,
        SUM(no_of_shares) AS total_shares,
        AVG(price_per_share) AS avg_price,
        SUM(no_of_shares * price_per_share) AS usd_spent
    FROM stocks
    WHERE action IN ('Market buy', 'Limit buy')
    GROUP BY time::DATE, ticker
),
cte_price AS (
    SELECT 
        stock_date, 
        CASE
            WHEN ticker = 'VUAA.L' THEN 'VUAA'
            ELSE ticker
        END AS ticker,
        close_price
    FROM stock_price
), final_cte as(
    SELECT stock_date,
            c.ticker,
            close_price,
            total_shares,
            avg_price,
            usd_spent
    FROM cte_price AS c
    LEFT JOIN cte_month_buy AS s
        ON c.stock_date = s.stock_buy
       AND c.ticker = s.ticker)
, cte_cum_sum as(
    SELECT stock_date,
            ticker,
            close_price,
             SUM(COALESCE(total_shares,0)) 
                OVER (PARTITION BY ticker ORDER BY stock_date) AS cum_sum_of_share,
            SUM(COALESCE(usd_spent,0)) 
                OVER (PARTITION BY ticker ORDER BY stock_date) AS usd_spent_cum
    FROM final_cte)

SELECT *
FROM cte_cum_sum
WHERE cum_sum_of_share IS NOT NULL AND stock_date IN (SELECT last_working_day
                                            FROM end_of_month_2024)
ORDER by ticker,stock_date);



-- Return the end working day for each month, the ticker, and the month-over-month change in stock price for each ticker.
SELECT stock_date,
        ticker,
        CONCAT(ROUND(((cum_sum_of_share*close_price)-usd_spent_cum)/NULLIF(usd_spent_cum,0)*100,2),'%') as change_price
FROM change_share_amound_MOM
