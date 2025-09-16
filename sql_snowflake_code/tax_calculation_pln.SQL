-- Project Description:
-- This project calculates dividend tax obligations for a Polish tax resident.
-- Dividends are reported in broker statements (USD) and must be converted to PLN
-- using the official NBP exchange rate (Table A) from the day prior to the payment date
-- (Friday’s rate if payment is on Monday).
-- Tax rules: 15% withheld in the US, 19% total in Poland → additional 4% payable in Poland.
-- The output summarizes dividends in PLN, US tax withheld, and Polish tax due.
USE ROLE ACCOUNTADMIN;

USE WAREHOUSE stock_whs;

USE DATABASE STOCKS_ANALYSIS_DB;

USE SCHEMA STOCKS_SCHEMA;

-- preliminary review of the 'stocks' table
SELECT *
FROM stocks
WHERE action='Dividend (Dividend)';

--  choosing  needed columns;
SELECT action,
        cast(time as date) as date,
        isin,
        ticker,
        name,
        no_of_shares,
        price_per_share as dividend_per_share_usd,
        total as total_pln,
        withholding_tax as withholding_tax_usd
FROM stocks
WHERE action='Dividend (Dividend)';


-- preliminary review of the 'currency_rates' table
SELECT *
FROM currency_rates
LIMIT 5;

-- choose needed columns;
SELECT TO_DATE(TO_VARCHAR(data), 'YYYYMMDD') AS currency_date,
        usd
FROM currency_rates


CREATE OR REPLACE VIEW dividend_view AS
-- Create a CTE to join the 'stocks' table with the 'currency_rates' table using specific conditions;
WITH stocks_cte AS (
    SELECT CAST(time AS DATE) AS stock_date,
           ticker,
           name,
           no_of_shares,
           price_per_share AS dividend_per_share_usd,
           total AS total_pln,
           withholding_tax AS withholding_tax_usd
    FROM stocks
    WHERE action = 'Dividend (Dividend)'
), currency_cte AS (
    SELECT TO_DATE(TO_VARCHAR(data), 'YYYYMMDD') AS currency_date,
           usd
    FROM currency_rates
)

/* condition : 
             If in 'stocks' table  day of week ='MONDAY'-> in 'currency_rates' table day pf week = 'FRIDAY';
             If in 'stocks' table  date=2024-12-27'-> in 'currency_rates' date = '2024-12-24';
            Else stock_date=(currency_date-1);*/ 

SELECT s.*,
       c.currency_date,
       c.usd
FROM stocks_cte AS s
LEFT JOIN currency_cte AS c
    ON s.stock_date = CASE
                         WHEN DAYOFWEEK(s.stock_date) = 1 THEN DATEADD(DAY, 3, c.currency_date) -- Friday → +3
                         WHEN s.stock_date = '2024-12-27' THEN DATEADD(DAY, 3, c.currency_date) -- special case
                         ELSE DATEADD(DAY, 1, c.currency_date) -- default +1
                      END;



-- review 'dividend_view';
SELECT *
FROM dividend_view;


-- Create a CTE to calculate tax in poland;
WITH calc_divident_tax as (
    SELECT  ticker,
            name,
            stock_date,
            no_of_shares,
            dividend_per_share_usd,                                     --in netto;
            no_of_shares*dividend_per_share_usd as divident_netto_usd, --dividend netto;
            no_of_shares*dividend_per_share_usd + withholding_tax_usd  as dividend_brutto_usd,  --dividend in brutto;
            withholding_tax_usd,
            usd
    FROM dividend_view
)

, ready_tax_table as(
    SELECT ticker,
            no_of_shares,
            dividend_per_share_usd,
            dividend_brutto_usd,
            divident_netto_usd,
            withholding_tax_usd,
            dividend_brutto_usd*0.15 as tax_in_usa_15_persent_usd, -- 15% in USD;
            dividend_brutto_usd*0.15*usd as tax_in_usa_15_persent_pln,--15% in PLN;
            dividend_brutto_usd*0.19 as tax_in_usa_19_persent_usd, -- 19% in USD;
            dividend_brutto_usd*0.19*usd as tav_in_usa_19_persent_pln,-- 19% in PLN;
            dividend_brutto_usd*0.19*usd -  dividend_brutto_usd*0.15*usd as tax_need_pay_in_poland_pln -- 4% tax in Poland;
    FROM calc_divident_tax
)
SELECT *
FROM ready_tax_table;


SELECT SUM(tax_need_pay_in_poland_pln) as total_tax_in_poland_pln
FROM ready_tax_table;
