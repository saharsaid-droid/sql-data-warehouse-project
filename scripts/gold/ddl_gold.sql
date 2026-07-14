/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the data warehouse. 
    The Gold layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and combines data from the Silver layer 
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
===============================================================================
*/



-- Rename columns to friendly meaningful names
-- Sort the columns into logical groups to improve readability
-- genarte surrogate key for the dimension table as primary key for it
-- Tow Way :
--DDL- based generation 
-- Query-based using Window Function => ROW_NUMBER()

--***************************************************************************

-- =============================================================================
-- Create Dimension: gold.dim_customers
-- =============================================================================

-- use columns that will apper in customer dim  crm_cust_info join with erp_cust_az12
-- Rename columns to friendly meaningful names
-- Sort the columns into logical groups to improve readability
-- Dimension Table => contain descriptive Information about Customer
-- genarte surrogate key for the dimension table as primary key for it
-- Tow Way :
--DDL- based generation 
-- Query-based using Window Function => ROW_NUMBER()


IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers
AS
SELECT 
     ROW_NUMBER() OVER (ORDER BY cust_id) AS customer_key , -- Surrogate key => has no meaning
     ci.cust_id AS customer_id ,
     ci.cst_key AS customer_number ,
     ci.cst_firstname AS first_name,
     ci.cst_lastname AS last_name,
          la.cntry AS country,
     ci.cst_marital_status AS marital_status,
 CASE
     When ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the master for gender info
     ELSE COALESCE(ca.gen , 'n/a') 
 END AS gender ,
     ca.bdate AS birthdate,
     ci.cst_create_date AS create_date

FROM 
          silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca 
ON        ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 AS la 
ON        ci.cst_key = la.cid

  GO

--****************************************************************************************************

-- =============================================================================
-- Create Dimension: gold.dim_products
-- =============================================================================

  
-- crm_prd_info has historical & current Information 
-- WE will use current info only 
-- if End Date is NULL then it's current info of the product => after filter remove end date becuase it will be null
-- Dimension Table => contain descriptive Information about Product

IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO
  
CREATE VIEW gold.dim_product
AS
SELECT
     ROW_NUMBER() OVER(ORDER BY pn.prd_star_date, pn.prd_key) AS product_key,
     pn.prd_id AS product_id,
     pn.prd_key AS product_number,
     pn.prd_nm AS product_name,
     pn.cat_id AS category_id,
     pc.cat AS category,
     pc.subcat AS subcategory,
     pc.maintenance,
     pn.prd_cost AS cost,
     pn.prd_line AS product_line,
     pn.prd_star_date AS start_date
FROM
          silver.crm_prd_info      AS pn
LEFT JOIN   silver.erp_px_cat_g1v2 AS pc
ON        
     pn.cat_id = pc.id
WHERE
     pn.prd_end_date IS NULL  -- Filter out all historical Data 

  GO

--****************************************************************************************************

-- =============================================================================
-- Create Fact Table: gold.fact_sales
-- =============================================================================

-- Fact Table => Contain Keys ,Dates ,and Measures
-- Building Fact => USe the dimension's surrogate keys instead of IDs to 
-- easily connect facts with dimensions

IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO
  
CREATE VIEW gold.fact_sales
AS
SELECT 
     sd.sls_ord_num AS order_number,
     pr.product_key,
     cu.customer_key,
     sd.sls_order_dt AS order_date,
     sd.sls_ship_dt AS shipping_date,
     sd.sls_due_dt AS due_date,
     sd.sls_sales AS sales_amount,
     sd.sls_quantity AS quantity,
     sd.sls_price AS price
FROM  
   silver.crm_sales_details AS sd
LEFT JOIN gold.dim_product  AS pr      -- surrogate key on gold layer not silver 
ON   sd.sls_prd_key = pr.product_number 
LEFT JOIN gold.dim_customers  AS cu      -- surrogate key on gold layer not silver 
ON   sd.sls_cust_id = cu.customer_id 

  
GO



