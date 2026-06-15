-- TURN OFF SAFETY SWITCH (Allows us to bulk clean rows)
SET SQL_SAFE_UPDATES = 0;

-- STEP 1: DROP OLD COPIES & CREATE CLEAN STAGING TABLES
DROP TABLE IF EXISTS world_layoffs.layoffs_staging;
DROP TABLE IF EXISTS world_layoffs.layoffs_staging2;

-- Copy structure from the raw data
CREATE TABLE world_layoffs.layoffs_staging LIKE world_layoffs.layoffs;
INSERT INTO world_layoffs.layoffs_staging SELECT * FROM world_layoffs.layoffs;

-- Create staging2 with generic text formatting to prevent file format crashes
CREATE TABLE world_layoffs.layoffs_staging2 (
    company TEXT, location TEXT, industry TEXT, total_laid_off TEXT,
    percentage_laid_off TEXT, `date` TEXT, stage TEXT, country TEXT,
    funds_raised_millions TEXT, row_num INT
);


-- STEP 2: REMOVE EXACT DUPLICATES
INSERT INTO world_layoffs.layoffs_staging2
SELECT *, ROW_NUMBER() OVER (
    PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
) AS row_num FROM world_layoffs.layoffs_staging;

DELETE FROM world_layoffs.layoffs_staging2 WHERE row_num > 1;


-- STEP 3: FIX BLANK SPACES AND TEXT 'NULL' ERRORS
UPDATE world_layoffs.layoffs_staging2 SET industry = NULL WHERE industry = '' OR industry = 'NULL';
UPDATE world_layoffs.layoffs_staging2 SET total_laid_off = NULL WHERE total_laid_off = '' OR total_laid_off = 'NULL';
UPDATE world_layoffs.layoffs_staging2 SET percentage_laid_off = NULL WHERE percentage_laid_off = '' OR percentage_laid_off = 'NULL';
UPDATE world_layoffs.layoffs_staging2 SET `date` = NULL WHERE `date` = '' OR `date` = 'NULL';
UPDATE world_layoffs.layoffs_staging2 SET funds_raised_millions = NULL WHERE funds_raised_millions = '' OR funds_raised_millions = 'NULL';


-- STEP 4: STANDARDIZE TEXT VALUES
UPDATE world_layoffs.layoffs_staging2 SET company = TRIM(company);
UPDATE world_layoffs.layoffs_staging2 SET industry = 'Crypto' WHERE industry IN ('Crypto Currency', 'CryptoCurrency');
UPDATE world_layoffs.layoffs_staging2 SET country = TRIM(TRAILING '.' FROM country);


-- STEP 5: FIX DATE FORMATS
UPDATE world_layoffs.layoffs_staging2 SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y') WHERE `date` IS NOT NULL;
ALTER TABLE world_layoffs.layoffs_staging2 MODIFY COLUMN `date` DATE;


-- STEP 6: POPULATE BLANK INDUSTRIES FROM COPIES (e.g. Airbnb)
UPDATE world_layoffs.layoffs_staging2 t1
JOIN world_layoffs.layoffs_staging2 t2 ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL AND t2.industry IS NOT NULL;


-- STEP 7: REMOVE USELESS ROWS & FIX DATA TYPES
DELETE FROM world_layoffs.layoffs_staging2 WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

ALTER TABLE world_layoffs.layoffs_staging2 DROP COLUMN row_num;
ALTER TABLE world_layoffs.layoffs_staging2 
    MODIFY COLUMN total_laid_off INT,
    MODIFY COLUMN percentage_laid_off DOUBLE,
    MODIFY COLUMN funds_raised_millions INT;


-- TURN SAFETY SWITCH BACK ON
SET SQL_SAFE_UPDATES = 1;

-- SHOW FINAL DATASET
SELECT * FROM world_layoffs.layoffs_staging2;