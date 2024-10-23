-- ========================================================================
-- Data Cleaning Script for 'layoffs' Table
-- ========================================================================

SELECT
	*
FROM
	layoffs;
	
--=============================================================================

-- 1. Create a staging table to hold a working copy of the original data.

CREATE TABLE 
	layoffs_staging
(LIKE layoffs);

-- Verify creation of staging table.
SELECT 
	*
FROM 
	layoffs_staging;
	
-- Populate the staging table with data from the main table.
INSERT INTO
	layoffs_staging
SELECT 
	*
FROM
	layoffs;

--=============================================================================

-- 2. Remove duplicates.
-- Using a CTE to identify duplicates based on key fields and assign row numbers.

WITH duplicate_cte AS
(
	SELECT
		ctid,-- Use `ctid` to uniquely identify rows
		ROW_NUMBER() OVER(
		PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions) AS row_num
	FROM
		layoffs_staging
)
DELETE FROM -- Delete duplicate rows by keeping only the first occurrence of each.
	layoffs_staging
WHERE 
	ctid IN 
(
	SELECT
		ctid
	FROM
		duplicate_cte
	WHERE
		row_num > 1
);

-- 3. Standardize company names
-- Trim leading and trailing spaces from company names.

UPDATE 
	layoffs_staging
SET 
	company = TRIM(company);

-- 4. Standardize company names by handling case differences
-- Convert all company names to lowercase and identify duplicates.

WITH lower_company_cte AS
(
	SELECT DISTINCT
	    company,
	   	LOWER(company) AS lower_company
	FROM 
	    layoffs_staging
	GROUP BY 
	    company
	ORDER BY
		1
), 
similar_companies_cte AS
(
	SELECT
		lower_company
	FROM
		lower_company_cte
	GROUP BY
		lower_company		
	HAVING
		COUNT(lower_company) > 1
),
standard_company_names AS
(
	SELECT
		lower_company AS company_to_update,
		MIN(company) AS standardized_company
	FROM
		lower_company_cte
	GROUP BY
		lower_company
)
-- Update the staging table with standardized company names.
UPDATE
	layoffs_staging
SET
	company = scn.standardized_company
FROM
	standard_company_names AS scn
WHERE
	LOWER(layoffs_staging.company) = scn.company_to_update;

-- 5. Clean up industry names
-- Trim any leading/trailing spaces and standardize variations like.

UPDATE 
	layoffs_staging
SET 
	industry = TRIM(industry);

SELECT DISTINCT
	industry, COUNT(*)
FROM
	layoffs_staging
GROUP BY 
	industry
ORDER BY
	industry;
	
-- Standardize common industry variations.

UPDATE
	layoffs_staging  -- Standardize "Crypto" variations that were spotted by scanning distinct values.
SET
	industry = 'Crypto'
WHERE 
	industry like 'Crypto%';

-- 6. Standardize country names.
-- Trim spaces and standardize country names.

UPDATE 
	layoffs_staging
SET 
	country = TRIM(country);

SELECT DISTINCT
	country
FROM
	layoffs_staging
ORDER BY
	1;

UPDATE
	layoffs_staging -- Standardize "United States" variations that were spotted by scanning distinct values.
SET
	country = 'United States'
WHERE
	country LIKE 'United States%';

-- 7. Handle NULL values.
-- Remove rows where both total_laid_off and percentage_laid_off are NULL

SELECT 
	*
FROM 
	layoffs_staging
WHERE
	total_laid_off IS NULL
	AND percentage_laid_off IS NULL;

DELETE
FROM 
	layoffs_staging
WHERE
	total_laid_off IS NULL
	AND percentage_laid_off IS NULL;

-- 8. Populate missing industry values based on existing data for the same company.

SELECT 
	t1.company,
	t2.company,
	t1.industry,
	t2.industry
FROM
	layoffs_staging AS t1
JOIN
	layoffs_staging As t2
ON 	
	t1.company = t2.company
WHERE 
	(t1.industry IS NULL OR t1.industry ='')
	AND t2.industry IS NOT NULL
ORDER BY
	t1.company;

UPDATE
	layoffs_staging AS t1
SET 
	industry = t2.industry
FROM 
	layoffs_staging as t2
WHERE 
	t1.company = t2.company
	AND (t1.industry IS NULL OR t1.industry ='');

-- 9. Verify the data cleanup
-- Check for remaining rows with NULL or empty industry fields.

SELECT *
FROM 
	layoffs_staging
WHERE 
	industry IS NULL 
	OR industry = '';

-- Check for any remaining duplicate company names after cleaning.

WITH lower_company_cte AS 
(
    SELECT 
		company, 
		LOWER(company) AS lower_company
    FROM layoffs_staging
)
SELECT 
	company, 
	COUNT(*)
FROM 
	lower_company_cte
GROUP BY 
	lower_company
HAVING COUNT(*) > 1;

-- ========================================================================
-- End of Data Cleaning Script
-- ========================================================================
