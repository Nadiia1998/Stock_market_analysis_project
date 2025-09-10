USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE DATABASE stocks_analysis_db;

USE DATABASE stocks_analysis_db;

CREATE OR REPLACE SCHEMA stocks_schema;

USE SCHEMA stocks_schema;

-- 1. Create table 
CREATE OR REPLACE TABLE stocks (
    action	                                     VARCHAR(100),
    time	                                       DATETIME,
    isin	                                       VARCHAR(100),
    ticker	                                     VARCHAR(100),
    name                                         VARCHAR(100),
    notes	                                       VARCHAR(100),
    id	                                         VARCHAR(100),   
    no_of_shares	                               NUMBER(10,7),
    price_per_share	                             NUMBER(10,7),
    currency_price_per_share	                   VARCHAR(10),
    exchange_rate	                               VARCHAR(50),
    currency_result	                             VARCHAR(10),
    total	                                       NUMBER(10,3),
    currency_Total                               VARCHAR(10),
    withholding_tax	                             NUMBER(10,3),
    currency_withholding_tax	                   VARCHAR(10),
    currency_conversion_from_amount	             NUMBER(10,2),
    currency_currency_conversion_from_amount	   VARCHAR(10),
    currency_conversion_to_amount	               NUMBER(10,2),
    currency_currency_conversion_to_amount	     VARCHAR(10), 
    currency_conversion_fee                      NUMBER(10,2),
    currency_currency_conversion_fee             VARCHAR(10)
);


CREATE OR REPLACE TABLE currenc_rates (
    data                        DATE NOT NULL,
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

--2. create storage integration

CREATE OR REPLACE  STORAGE INTEGRATION stocks_s
    TYPE=EXTERNAL_STAGE
    STORAGE_PROVIDER='S3'
    ENABLED=TRUE
    STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::030540332769:role/stock_analysys_snowflake_role'
    STORAGE_ALLOWED_LOCATIONS = ('s3://stocks-analysys-own-project/');

--3. Info about connect to AWS S3
DESC STORAGE INTEGRATION stocks_s;

-- 4. Create file format 'CSV'
CREATE OR REPLACE FILE FORMAT CSV_FORMAT
TYPE='CSV'
FIELD_DELIMITER=','
RECORD_DELIMITER='\n'
SKIP_HEADER=1;

--5.CREATE EXTERNAL STAGE S3 AWS for stocks table;
CREATE OR REPLACE STAGE stock_stage
    STORAGE_INTEGRATION=stocks_s
    URL='s3://stocks-analysys-own-project/stocks/'
    FILE_FORMAT =CSV_FORMAT;

LIST @stock_stage;

--INSER DATA TO stocks TABLE;
COPY INTO stocks
FROM @stock_stage
FILE_FORMAT=(FORMAT_NAME=CSV_FORMAT);

SELECT *
FROM stocks
LIMIT 5;

--CREATE EXTERNAL STAGE S3 AWS for currenc_rates table;
CREATE OR REPLACE STAGE currecy_stage
    STORAGE_INTEGRATION=stocks_s
    URL='s3://stocks-analysys-own-project/archiwum_tab/'
    FILE_FORMAT=CSV_FORMAT;


LIST @currecy_stage;

--INSER DATA TO currenc_rates TABLE;
COPY INTO currenc_rates
FROM @currecy_stage
FILE_FORMAT=(FORMAT_NAME=CSV_FORMAT);


SELECT *
FROM currenc_rates
LIMIT 5;
