USE ROLE ACCOUNTADMIN;

--Creeate new DataWarehouse;
CREATE OR REPLACE WAREHOUSE stock_whs;

USE WAREHOUSE stock_whs;

--Create new Database;
CREATE OR REPLACE DATABASE stocks_analysis_db;

USE DATABASE stocks_analysis_db;

--Cretae new schema;
CREATE OR REPLACE SCHEMA stocks_schema;

USE SCHEMA stocks_schema;

-- 1. Create 'stocks' table . It`s containe informaion information from the broker about actions on the stock exchange in 2024;
CREATE OR REPLACE TABLE stocks (
    action	                                     VARCHAR(100),
    time	                                     DATETIME,
    isin	                                     VARCHAR(100),
    ticker	                                     VARCHAR(100),
    name                                         VARCHAR(100),
    notes	                                     VARCHAR(100),
    id	                                         VARCHAR(100),   
    no_of_shares	                             NUMBER(10,7),
    price_per_share	                             NUMBER(10,7),
    currency_price_per_share	                 VARCHAR(10),
    exchange_rate	                             VARCHAR(50),
    currency_result	                             VARCHAR(10),
    total	                                     NUMBER(10,3),
    currency_Total                               VARCHAR(10),
    withholding_tax	                             NUMBER(10,3),
    currency_withholding_tax	                 VARCHAR(10),
    currency_conversion_from_amount	             NUMBER(10,2),
    currency_currency_conversion_from_amount	 VARCHAR(10),
    currency_conversion_to_amount	             NUMBER(10,2),
    currency_currency_conversion_to_amount	     VARCHAR(10), 
    currency_conversion_fee                      NUMBER(10,2),
    currency_currency_conversion_fee             VARCHAR(10)
);

--2. Create 'currency_rates' table. This table containinformation about exchange rate in National Bank of Poland 'Table_A'.
    /*For tax calculation in Poland, the currency exchange rate to PLN must be taken from the NBP Table A on the day preceding the transaction date (purchase or        sale of shares).
        -If the previous day is a weekend or public holiday, the exchange rate from the last available business day before the transaction should be used.
        -This rule applies both to purchases and sales of shares(also from the received dividends) */
CREATE OR REPLACE TABLE currency_rates (
    data                        INT NOT NULL,
    THB                         DECIMAL(18,4) NULL,
    USD                         DECIMAL(18,4) NULL,
    AUD                         DECIMAL(18,4) NULL,
    HKD                         DECIMAL(18,4) NULL,
    CAD                         DECIMAL(18,4) NULL,
    NZD                         DECIMAL(18,4) NULL,
    SGD                         DECIMAL(18,4) NULL,
    EUR                         DECIMAL(18,4) NULL,
    HUF_100                     DECIMAL(18,4) NULL,
    CHF                         DECIMAL(18,4) NULL,
    GBP                         DECIMAL(18,4) NULL,
    UAH                         DECIMAL(18,4) NULL,
    JPY_100                     DECIMAL(18,4) NULL,
    CZK                         DECIMAL(18,4) NULL,
    DKK                         DECIMAL(18,4) NULL,
    ISK_100                     DECIMAL(18,4) NULL,
    NOK                         DECIMAL(18,4) NULL,
    SEK                         DECIMAL(18,4) NULL,
    RON                         DECIMAL(18,4) NULL,
    BGN                         DECIMAL(18,4) NULL,
    TRY                         DECIMAL(18,4) NULL,
    ILS                         DECIMAL(18,4) NULL,
    CLP_100                     DECIMAL(18,4) NULL,
    PHP                         DECIMAL(18,4) NULL,
    MXN                         DECIMAL(18,4) NULL,
    ZAR                         DECIMAL(18,4) NULL,
    BRL                         DECIMAL(18,4) NULL,
    MYR                         DECIMAL(18,4) NULL,
    IDR_10000                   DECIMAL(18,4) NULL,
    INR_100                     DECIMAL(18,4) NULL,
    KRW_100                     DECIMAL(18,4) NULL,
    CNY                         DECIMAL(18,4) NULL,
    XDR                         DECIMAL(18,4) NULL,
    nr_tabeli                   INT NULL,
    numer_tabelicomposed        NVARCHAR(20) NULL
);


-- 3. Create 'stock_price' table.
-- This table need for known price per shere in 2024;
CREATE OR REPLACE TABLE stock_price (
    stock_date          DATE,
    ticker              VARCHAR(50),
    open_price          NUMBER(18,10),
    close_price         NUMBER(18,10)
);



-- 4. Create dtorage integration with AWS S3-bucket.
CREATE OR REPLACE  STORAGE INTEGRATION stocks_s
    TYPE=EXTERNAL_STAGE
    STORAGE_PROVIDER='S3'
    ENABLED=TRUE
    STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::030540332769:role/role_in_AWS'
    STORAGE_ALLOWED_LOCATIONS = ('s3://bucket_name/');

    
--5. Info about connect to AWS S3.
-- To find the necessary information for the connection
DESC STORAGE INTEGRATION stocks_s;

-- 6. Create file format 'CSV'
CREATE OR REPLACE FILE FORMAT CSV_FORMAT
TYPE='CSV'
FIELD_DELIMITER=','
RECORD_DELIMITER='\n'
SKIP_HEADER=1;

-- 5.CREATE EXTERNAL STAGE S3 AWS for stocks table;
CREATE OR REPLACE STAGE stock_stage
    STORAGE_INTEGRATION=stocks_s
    URL='s3://bucket_name/folder/'
    FILE_FORMAT =CSV_FORMAT;

-- Info about stage;
LIST @stock_stage;

-- 7.INSER DATA TO stocks TABLE;
COPY INTO stocks
FROM @stock_stage
FILE_FORMAT=(FORMAT_NAME=CSV_FORMAT);


-- 8. Сhecking correct insert to table;
SELECT *
FROM stocks
LIMIT 30;


-- 9. CREATE EXTERNAL STAGE S3 AWS for currency_rates table;
CREATE OR REPLACE STAGE currecy_stage
    STORAGE_INTEGRATION=stocks_s
    URL='s3://bucket_name/folder'
    FILE_FORMAT=CSV_FORMAT;

-- Info about stage
LIST @currecy_stage;

--10. INSER DATA TO currency_rates TABLE;
COPY INTO currency_rates
FROM @currecy_stage
FILE_FORMAT=(FORMAT_NAME=CSV_FORMAT);

--11. Сhecking correct insert to table;
SELECT *
FROM currency_rates
LIMIT 5;


--12. CREATE EXTERNAL STAGE S3 AWS for stock_price table;
CREATE OR REPLACE STAGE stock_price_stage
    STORAGE_INTEGRATION=stocks_s
    URL='s3:bucket_name/folder'
    FILE_FORMAT=CSV_FORMAT;

--13.INSER DATA TO 'stock_price' TABLE;
COPY INTO stock_price
FROM @stock_price_stage
FILE_FORMAT=(FORMAT_NAME=CSV_FORMAT);


-- 14. Create 'end_of_month_2024' table with data on the last working day of the month
CREATE OR REPLACE TABLE end_of_month_2024 (
    month_end DATE,
    last_working_day DATE
);

INSERT INTO end_of_month_2024 (month_end, last_working_day) VALUES
('2024-01-31', '2024-01-31'),
('2024-02-29', '2024-02-29'),
('2024-03-31', '2024-03-28'), 
('2024-04-30', '2024-04-30'),
('2024-05-31', '2024-05-31'), 
('2024-06-30', '2024-06-28'), 
('2024-07-31', '2024-07-31'),
('2024-08-31', '2024-08-30'), 
('2024-09-30', '2024-09-30'),
('2024-10-31', '2024-10-31'),
('2024-11-30', '2024-11-29'), 
('2024-12-31', '2024-12-31');
