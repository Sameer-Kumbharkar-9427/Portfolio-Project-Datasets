-- SQL Project - Data Cleaning

SELECT * FROM layoffs;

-- create a staging table to work in and clean the data.
CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT *
FROM layoffs_staging;

INSERT layoffs_staging
SELECT *
FROM layoffs;

-- For data cleaning following steps are followed
-- 1. check for duplicates and remove any
-- 2. standardize data and fix errors
-- 3. Look at null values and see what 
-- 4. remove any columns and rows that are not necessary 

-- Checking for duplicates
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, industry,total_laid_off, percentage_laid_off, `date`) as row_num
FROM layoffs_staging;

WITH duplicate_cte AS
(SELECT *,
ROW_NUMBER() OVER(PARTITION BY company,location, industry,total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- rows with row_num >1 are the duplicated and has to be deleted. But we want to be careful with our data in 'layoffs_staging' table so, 
-- we will create a new table 
-- create a new table 'layoffs_staging2'

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
);


SELECT *
FROM layoffs_staging2;

-- Insert data into layoffs_staging2 while marking duplicate rows with row_num
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company,location, industry,total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
FROM layoffs_staging;

-- delete rows were row_num is greater than 2
DELETE
FROM layoffs_staging2
WHERE row_num > 1;

SELECT *
FROM layoffs_staging2;


-- Standardizing data
-- Delete duplicate rows
SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

-- Check for inconsistencies in industry names
SELECT DISTINCT industry
FROM layoffs_staging2;

-- Standardize industry names (making 'Crypto ' consistent as 'Crypto')
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Standardizing country names (removing trailing periods)
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
Order by 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Convert date column to proper DATE format
SELECT *,
STR_TO_DATE (`date`, '%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET date = STR_TO_DATE (`date`, '%m/%d/%Y');

-- Modify column type to store proper date values
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- Handling NULL values
-- Identify rows where both total_laid_off and percentage_laid_off are NULL
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Checking data consistency for a specific company
SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

-- Filling missing industry data using known company values
SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;     
 
 
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;    

-- Standardizing empty values by converting blank industry fields to NULL
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- Filling remaining NULL industry values based on company name
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL)
AND t2.industry IS NOT NULL;  

 SELECT *
 FROM layoffs_staging2;

-- Remove rows where both total_laid_off and percentage_laid_off are NULL, as they are not useful
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2;

-- Remove unnecessary row_num column 
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;