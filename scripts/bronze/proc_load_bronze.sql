/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files. 
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `BULK INSERT` command to load data from csv Files to bronze tables.

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze;
===============================================================================
*/


-- load data from source file into bronze layer and check quality of each table 
/*-- loade inside table bronze.crm_cust_info
BULK INSERT bronze.crm_cust_info
FROM 'D:\AI ENGINEER\Data Engineering\DataWarehouse\DWH Project\dw_Project\datasets\source_crm\cust_info.csv' 
WITH(
    FIRSTROW = 2,      -- exclude header
    FIELDTERMINATOR = ',',  --seprator of csv
    TABLOCK              -- LOCK table when loading it => increase performance 
    );

-- Test quality of bronze.crm_cust_info table
SELECT * FROM bronze.crm_cust_info

-- count rows inside table 
SELECT COUNT(*) FROM bronze.crm_cust_info
*/


CREATE OR ALTER PROCEDURE bronze.load_bronze AS 
    BEGIN
     DECLARE @start_time DATETIME , @end_time DATETIME, @start_time_bronze DATETIME , @end_time_bronze DATETIME;
     BEGIN TRY
     SET @start_time_bronze = GETDATE()
        PRINT '*************************************************************';
        PRINT 'Loading Bronze Layer';
        PRINT '*************************************************************';

        PRINT '-------------------------------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '-------------------------------------------------------------';
            -- what if i load the table again => misakes 
            -- we will use TRUNCATE method for make table empty and then load it again
            --*************** This is The Full Load***************--

            PRINT '>>Truncating Table: bronze.crm_cust_info';
            TRUNCATE TABLE bronze.crm_cust_info;

            SET @start_time = GETDATE()  -- GET THE EXACT TIME 
            PRINT '>>Inserting Data Into : bronze.crm_cust_info';
            BULK INSERT bronze.crm_cust_info
            FROM 'D:\AI ENGINEER\Data Engineering\DataWarehouse\DWH Project\dw_Project\datasets\source_crm\cust_info.csv' 
            WITH(
                FIRSTROW = 2,      -- exclude header
                FIELDTERMINATOR = ',',  --seprator of csv
                TABLOCK              -- LOCK table when loading it => increase performance 
                );
                SET @end_time = GETDATE() 
                PRINT '>> Load Duration: '+ CAST(DATEDIFF(SECOND , @start_time, @end_time) AS NVARCHAR ) + 'seconds.'
                PRINT '>>------------<<'
            --DATEDIFF(UNIT,start Time, end Time ) => calculates difference between 2 dates , return days , months ,or years
            -- Test quality of bronze.crm_cust_info table
           -- SELECT * FROM bronze.crm_cust_info;

            -- count rows inside table 
            --SELECT COUNT(*) FROM bronze.crm_cust_info;



            -- loade inside table bronze.crm_prd_info
        
            PRINT '>>Truncating Table: bronze.crm_prd_info';
            TRUNCATE TABLE bronze.crm_prd_info;

            SET @start_time = GETDATE()
            PRINT '>>Inserting Data Into : bronze.crm_prd_info';
            BULK INSERT bronze.crm_prd_info
            FROM 'D:\AI ENGINEER\Data Engineering\DataWarehouse\DWH Project\dw_Project\datasets\source_crm\prd_info.csv' 
            WITH(
                FIRSTROW = 2,      -- exclude header
                FIELDTERMINATOR = ',',  --seprator of csv
                TABLOCK              -- LOCK table when loading it => increase performance 
                );

            SET @end_time = GETDATE() 
            PRINT '>> Load Duration: '+ CAST(DATEDIFF(SECOND , @start_time, @end_time) AS NVARCHAR ) + 'seconds.'
            PRINT '>>------------<<'

            -- Test quality of bronze.crm_prd_info table
          --  SELECT * FROM bronze.crm_prd_info;

            -- count rows inside table 
           -- SELECT COUNT(*) FROM bronze.crm_prd_info;


            -- loade inside table bronze.crm_sales_details
        
            PRINT '>>Truncating Table: bronze.crm_sales_details';
            TRUNCATE TABLE bronze.crm_sales_details;

            SET @start_time = GETDATE()
            PRINT '>>Inserting Data Into : bronze.crm_sales_details';
            BULK INSERT bronze.crm_sales_details
            FROM 'D:\AI ENGINEER\Data Engineering\DataWarehouse\DWH Project\dw_Project\datasets\source_crm\sales_details.csv' 
            WITH(
                FIRSTROW = 2,      -- exclude header
                FIELDTERMINATOR = ',',  --seprator of csv
                TABLOCK              -- LOCK table when loading it => increase performance 
                );

            SET @end_time = GETDATE() 
            PRINT '>> Load Duration: '+ CAST(DATEDIFF(SECOND , @start_time, @end_time) AS NVARCHAR ) + 'seconds.'
            PRINT '>>------------<<'
           
           -- Test quality of bronze.crm_sales_details table
            --SELECT * FROM bronze.crm_sales_details;

            -- count rows inside table 
            --SELECT COUNT(*) FROM bronze.crm_sales_details;


        PRINT '-------------------------------------------------------------';
        PRINT 'Loading ERP Tables';
        PRINT '-------------------------------------------------------------';

            -- loade inside table bronze.erp_loc_a101
        
            PRINT '>>Truncating Table: bronze.erp_loc_a101';
            TRUNCATE TABLE bronze.erp_loc_a101;

            SET @start_time = GETDATE()
            PRINT '>>Inserting Data Into : bronze.erp_loc_a101';
            BULK INSERT bronze.erp_loc_a101
            FROM 'D:\AI ENGINEER\Data Engineering\DataWarehouse\DWH Project\dw_Project\datasets\source_erp\LOC_A101.csv' 
            WITH(
                FIRSTROW = 2,      -- exclude header
                FIELDTERMINATOR = ',',  --seprator of csv
                TABLOCK              -- LOCK table when loading it => increase performance 
                );

            SET @end_time = GETDATE() 
            PRINT '>> Load Duration: '+ CAST(DATEDIFF(SECOND , @start_time, @end_time) AS NVARCHAR ) + 'seconds.'
            PRINT '>>------------<<'

            -- Test quality of bronze.erp_loc_a101 table
           -- SELECT * FROM bronze.erp_loc_a101;

            -- count rows inside table 
           -- SELECT COUNT(*) FROM bronze.erp_loc_a101;






            -- loade inside table bronze.erp_cust_az12
        
            PRINT '>>Truncating Table: bronze.erp_cust_az12';
            TRUNCATE TABLE bronze.erp_cust_az12;

            SET @start_time = GETDATE()
            PRINT '>>Inserting Data Into : bronze.erp_cust_az12';
            BULK INSERT bronze.erp_cust_az12
            FROM 'D:\AI ENGINEER\Data Engineering\DataWarehouse\DWH Project\dw_Project\datasets\source_erp\CUST_AZ12.csv' 
            WITH(
                FIRSTROW = 2,      -- exclude header
                FIELDTERMINATOR = ',',  --seprator of csv
                TABLOCK              -- LOCK table when loading it => increase performance 
                );

            SET @end_time = GETDATE() 
            PRINT '>> Load Duration: '+ CAST(DATEDIFF(SECOND , @start_time, @end_time) AS NVARCHAR ) + 'seconds.'
            PRINT '>>------------<<'

            -- Test quality of bronze.erp_cust_az12 table
            --SELECT * FROM bronze.erp_cust_az12;

            -- count rows inside table 
            --SELECT COUNT(*) FROM bronze.erp_cust_az12;



            -- loade inside table bronze.erp_px_cat_g1v2
        
            PRINT '>>Truncating Table: bronze.erp_px_cat_g1v2';
            TRUNCATE TABLE bronze.erp_px_cat_g1v2;

            SET @start_time = GETDATE()
            PRINT '>>Inserting Data Into : bronze.erp_px_cat_g1v2';
            BULK INSERT bronze.erp_px_cat_g1v2
            FROM 'D:\AI ENGINEER\Data Engineering\DataWarehouse\DWH Project\dw_Project\datasets\source_erp\PX_CAT_G1V2.csv' 
            WITH(
                FIRSTROW = 2,      -- exclude header
                FIELDTERMINATOR = ',',  --seprator of csv
                TABLOCK              -- LOCK table when loading it => increase performance 
                );
            SET @end_time = GETDATE() 
            PRINT '>> Load Duration: '+ CAST(DATEDIFF(SECOND , @start_time, @end_time) AS NVARCHAR ) + 'seconds.'
            PRINT '>>------------<<'

            -- Test quality of bronze.erp_px_cat_g1v2 table
           -- SELECT * FROM bronze.erp_px_cat_g1v2;

            -- count rows inside table 
           -- SELECT COUNT(*) FROM bronze.erp_px_cat_g1v2;
            PRINT 'Loading Bronze Layer is Completed'
            SET @end_time_bronze = GETDATE()
            PRINT '>>Total Load Duration: '+ CAST(DATEDIFF(SECOND , @start_time_bronze, @end_time_bronze) AS NVARCHAR ) + 'seconds.'
            PRINT '>>------------<<'
        END TRY
        BEGIN CATCH
            PRINT '^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^'
            PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
            PRINT 'ERROR Message' + ERROR_MESSAGE();
            PRINT 'ERROR Message' + CAST(ERROR_NUMBER()AS  NVARCHAR);
            PRINT 'ERROR Message' + ERROR_STATE();
            PRINT '^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^'
        END CATCH

    END;



-- test procedure 
EXEC bronze.load_bronze;
