/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC Silver.load_silver;
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver
AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME; 
    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '================================================';
        PRINT 'Loading Silver Layer';
        PRINT '================================================';

		PRINT '------------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '------------------------------------------------';

		-- Loading silver.crm_cust_info
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.crm_cust_info ';
        TRUNCATE TABLE silver.crm_cust_info ;
        PRINT '>> INSERTING DATA INTO: silver.crm_cust_info ';
        INSERT INTO silver.crm_cust_info (cust_id ,
                cst_key ,
                cst_firstname,
                cst_lastname ,
                cst_marital_status ,
                cst_gndr ,
                cst_create_date ) 
        SELECT cust_id,
               cst_key,
               TRIM(cst_firstname) AS cst_firstname, -- to trim space  
               TRIM(cst_lastname) AS cst_lastname,
        CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
             WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married' 
             ELSE 'n/a' 
        END cst_marital_status ,
        CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
             WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male' 
             ELSE 'n/a' 
        END cst_gndr ,
               cst_create_date
        FROM(
        SELECT * , 
        ROW_NUMBER() OVER (PARTITION BY cust_id ORDER BY cst_create_date DESC)  AS flag_last
        FROM
           bronze.crm_cust_info ) t 
           WHERE flag_last =1  -- there is the data we aren't need
           SET @end_time = GETDATE();
           PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
           PRINT '>> -------------';



           --*********************************************************************************************
		-- Loading silver.crm_prd_info
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.crm_prd_info ';
        TRUNCATE TABLE silver.crm_prd_info ;
        PRINT '>> INSERTING DATA INTO: silver.crm_prd_info ';
        INSERT INTO silver.crm_prd_info(
                prd_id,       
                cat_id,        
                prd_key,        
                prd_nm  ,       
                prd_cost ,      
                prd_line  ,     
                prd_star_date  , 
                prd_end_date
                )
            SELECT 
                 prd_id,
                 REPLACE(SUBSTRING(prd_key,1,5), '-','_') AS cat_id, --(COLUMN , START_POSITION , NUMBER OF CHAR)
                 SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key, -- use len => becuase number of char is differnt in each raw => make it dynamic 
                 prd_nm,
                 ISNULL(prd_cost,0) AS prd_cost , -- Replace null with defualt value based on business
                 CASE  UPPER(TRIM(prd_line))
                     WHEN 'M' THEN 'Mountain'
                     WHEN 'R' THEN 'Road'
                     WHEN 'S' THEN 'Other Sales'
                     WHEN 'T' THEN 'Touring'
                     ELSE 'n/a'
                 END AS prd_line,
                 prd_star_date,
                 DATEADD(day , -1 ,
                 LEAD(prd_star_date) OVER 
                 (PARTITION BY prd_key ORDER BY prd_star_date )) 
                 AS prd_end_date
            FROM 
                bronze.crm_prd_info
            SET @end_time = GETDATE();
            PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
            PRINT '>> -------------';

        


           --*********************************************************************************************
        -- Loading crm_sales_details
        SET @start_time = GETDATE();
           -- RULES
           --  if sales is -ve , 0 , NULLs  => derive it using quantity and price
           --  if price is  0 , NULLs  => derive it using quantity and sales
           --  if price is -ve => convert it to a +ve valus
        PRINT '>> Truncating Table: silver.crm_sales_details ';
        TRUNCATE TABLE silver.crm_sales_details ;
        PRINT '>> INSERTING DATA INTO: silver.crm_sales_details ';
        INSERT INTO silver.crm_sales_details(
                sls_ord_num    ,
                sls_prd_key    ,
                sls_cust_id    ,
                sls_order_dt   ,
                sls_ship_dt    ,
                sls_due_dt     ,
                sls_sales      ,
                sls_quantity   ,
                sls_price )

          SELECT
                sls_ord_num  ,
                sls_prd_key  ,
                sls_cust_id  ,
                CASE 
                 WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
                 ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE) -- CONVERT INT TO STRING ,THEN CONVERT STRING TO DATE
                END sls_order_dt ,
                CASE 
                 WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
                 ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE) -- CONVERT INT TO STRING ,THEN CONVERT STRING TO DATE
                END sls_ship_dt  ,
                CASE 
                 WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
                 ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE) -- CONVERT INT TO STRING ,THEN CONVERT STRING TO DATE
                END sls_due_dt   , 
                CASE 
                    WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales !=  sls_quantity * ABS(sls_price)
                    THEN sls_quantity * ABS(sls_price)
                    ELSE sls_sales
                END sls_sales,
                sls_quantity ,
                CASE 
                   WHEN sls_price IS NULL OR sls_price <= 0
                   THEN  sls_sales / NULLIF(sls_quantity,0) -- TO AVOID DIVIDE BY 0
                   ELSE sls_price
                END sls_price   
        FROM 
            bronze.crm_sales_details
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';




           --*********************************************************************************************
		PRINT '------------------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '------------------------------------------------';

        -- Loading erp_loc_a101
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.erp_cust_az12 ';
        TRUNCATE TABLE silver.erp_cust_az12 ;
        PRINT '>> INSERTING DATA INTO: silver.erp_cust_az12 ';
        INSERT INTO  silver.erp_cust_az12(
                                         cid, bdate, gen) 
          SELECT 
          CASE
              WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid , 4 , LEN(cid))
              ELSE cid
          END cid,
          CASE 
              WHEN bdate > GETDATE() THEN NULL
              ELSE bdate
          END bdate,
          CASE
              WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE')  THEN 'Female'
              WHEN UPPER(TRIM(gen)) IN ('M', 'MALE')  THEN 'Male'
              ELSE 'n/a'
          END gen
        FROM 
            bronze.erp_cust_az12
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

            --*********************************************************************************************
        -- Loading erp_loc_a101
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.erp_loc_a101 ';
        TRUNCATE TABLE silver.erp_loc_a101 ;
        PRINT '>> INSERTING DATA INTO: silver.erp_loc_a101 ';
        INSERT INTO silver.erp_loc_a101
                                       (cid,cntry)
        SELECT 
           REPLACE(cid, '-','') AS cid  ,
           CASE 
            WHEN TRIM(cntry) = ('DE')THEN 'Germany'
            WHEN TRIM(cntry) IN ('USA', 'US ')THEN 'United States'
            WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
            ELSE TRIM(cntry)
           END cntry
        FROM  
           bronze.erp_loc_a101
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';
 
 
         --*********************************************************************************************
		-- Loading erp_px_cat_g1v2
		SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.erp_px_cat_g1v2 ';
        TRUNCATE TABLE silver.erp_px_cat_g1v2 ;
        PRINT '>> INSERTING DATA INTO: silver.erp_px_cat_g1v2 ';
        INSERT INTO silver.erp_px_cat_g1v2(
                                id , 
                                cat ,
                                subcat , 
                                maintenance)
        SELECT 
            id , 
            cat ,
            subcat , 
            maintenance
        FROM 
           bronze.erp_px_cat_g1v2
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';
        
        SET @batch_end_time = GETDATE();
		PRINT '=========================================='
		PRINT 'Loading Silver Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '=========================================='
		
	END TRY
	BEGIN CATCH
		PRINT '=========================================='
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '=========================================='
	END CATCH
END



