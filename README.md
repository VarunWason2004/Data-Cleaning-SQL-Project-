# Data-Cleaning-SQL-Project-
An end-to-end SQL data cleaning and ETL pipeline executing multi-step data standardization, duplicate removal, and type-casting on global tech layoffs data.
# Automated Data Cleaning & ETL Pipeline for Global Layoff Records

## Project Overview
Raw, uncleaned datasets often suffer from structural inconsistencies, duplicate entries, data type mismatches, and missing values. This project showcases a robust, multi-step data cleaning pipeline built entirely using **MySQL**. 

Using a real-world dataset detailing tech company layoffs, this script establishes a staging environment, handles security constraints, purges duplicate records, normalizes string entries, fixes date formats, populates missing attributes via self-joins, and casts optimal data types for production analytical use.

## Tech Stack & Core Concepts
* **Database Management System:** MySQL / SQL Server
* **Key SQL Techniques:** Common Table Expressions (CTEs), Window Functions (`ROW_NUMBER()`), Self-Joins (`UPDATE JOIN`), Data Type Alterations, and Data Sanitization (`TRIM`, `STR_TO_DATE`).

## Data Pipeline Steps Explained

### 1. Environment & Staging Setup
To protect production source data, the pipeline creates secondary staging tables (`layoffs_staging` and `layoffs_staging2`). Safe update restrictions are temporarily adjusted (`SET SQL_SAFE_UPDATES = 0`) to allow large-scale batch alterations.

### 2. Duplicate Deduplication
Utilizing the `ROW_NUMBER()` window function partitioned over all core entity attributes, unique numerical row IDs are assigned. Records with a row count greater than 1 are identified as absolute duplicates and systematically removed via a targeting delete query.

### 3. Null and Missing Value Handling
Inconsistent blank text formatting and pseudo-null strings (literal `'NULL'` texts) are normalized into real relational SQL `NULL` states across performance metrics (`total_laid_off`, `percentage_laid_off`, `funds_raised_millions`) and operational dates.

### 4. Text Standardization & Sanitization
* **String Trimming:** Leading and trailing white spaces are stripped from company titles using `TRIM()`.
* **Category Merging:** Redundant overlapping industry values (e.g., 'Crypto Currency' and 'CryptoCurrency') are compressed into a unified industry label ('Crypto').
* **Trailing Character Removal:** Structural typos, like trailing periods in country names (e.g., 'United States.'), are isolated and removed.

### 5. Temporal Data Type Transformation
Raw date fields tracking time as raw text elements are scrubbed and parsed using formatting templates (`STR_TO_DATE`). Once standardized into structural records, the column definition is permanently optimized via `ALTER TABLE` to use a native `DATE` data type.

### 6. Relational Self-Joins for Data Imputation
Blank industries for specific corporations (e.g., missing labels for companies like Airbnb) are programmatically populated by running a conditional `JOIN` matching identical company fields that possess populated data values elsewhere in the matrix.

### 7. Logical Row Pruning & Final Schema Optimization
Records containing missing data for both primary analytical metrics (`total_laid_off` and `percentage_laid_off` both null) are pruned as noise. Auxiliary tracking vectors are cleanly dropped, and columns are explicitly cast to proper spatial definitions (`INT`, `DOUBLE`).

## How to Deploy and Run
1. Run your source script to import the raw `layoffs.csv` data into your MySQL server.
2. Execute the provided script file (`data_cleaning_pipeline.sql`) sequentially.
3. Verify output integrity via the final query statement: `SELECT * FROM world_layoffs.layoffs_staging2;`
