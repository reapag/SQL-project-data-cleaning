# Layoffs Data Cleaning Project

Overview
This project involves cleaning and standardizing a dataset of company layoffs. The dataset includes details such as company name, location, industry, and layoff information (total laid off, percentage laid off, etc.). The objective is to clean the data by removing duplicates, standardizing values, and handling missing data to ensure consistency and accuracy.

Key Cleaning Steps
Duplicate Removal:

Identified and removed duplicate records using a ROW_NUMBER window function.

Standardizing Text Fields:

Trimmed extra spaces from company names, locations, and other text fields.
Standardized variations in company names (e.g., "ByteDance" vs. "Bytedance").
Unified industry names to ensure consistency (e.g., standardizing "Crypto" and similar variations).

Handling Missing Values:

Identified and addressed missing or null values in columns like total_laid_off, percentage_laid_off, and industry.
Filled missing industry values based on existing data for the same company.

Data Validation:

Checked for invalid or inconsistent data entries (e.g., leading or trailing spaces, incorrect industry names).
Removed rows with insufficient data (e.g., rows with both total_laid_off and percentage_laid_off missing).
