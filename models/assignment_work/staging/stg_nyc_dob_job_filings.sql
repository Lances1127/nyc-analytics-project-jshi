
-- Clean and standardize NYC DOB job filing data
-- One row per job filing

WITH source AS (
   SELECT * FROM {{ source('raw', 'source_nyc_dob_job_apps') }}
), -- Easier to refer to the dbt reference to a long name table this way

cleaned AS (
   SELECT
       -- Get all columns from source, except ones we're transforming below
       -- To do cleaning on them or explicitly cast them as types just in case
       * EXCEPT (
           job_filing_number,
           filing_date,
           approved_date,
           current_status_date,
           filing_status,
           job_type,
           building_type,
           initial_cost,
           job_description,
           zip,
           borough,
           house_no,
           street_name,
           block,
           lot,
           bin,
           latitude,
           longitude
       ),

       -- Identifiers
       CAST(job_filing_number AS STRING) AS filing_id,

       -- Date/Time
       CAST(filing_date AS TIMESTAMP) AS filing_date,
       CAST(approved_date AS TIMESTAMP) AS approved_date,
       CAST(current_status_date AS TIMESTAMP) AS current_status_date,

       -- Job details
       CAST(job_type AS STRING) AS job_type,
       UPPER(TRIM(CAST(filing_status AS STRING))) AS filing_status,
       CAST(building_type AS STRING) AS building_type,
       CAST(job_description AS STRING) AS job_description,
       CAST(initial_cost AS NUMERIC) AS initial_cost,

       -- Location - clean zip code, handling several common zip code data problems
       CASE
           WHEN UPPER(TRIM(CAST(zip AS STRING))) IN ('N/A', 'NA') THEN NULL
           WHEN LENGTH(CAST(zip AS STRING)) = 5 THEN CAST(zip AS STRING)
           WHEN LENGTH(CAST(zip AS STRING)) = 9 THEN CAST(zip AS STRING)
           WHEN LENGTH(CAST(zip AS STRING)) = 10
               AND REGEXP_CONTAINS(CAST(zip AS STRING), r'^\d{5}-\d{4}')
           THEN CAST(zip AS STRING)
           ELSE NULL
       END AS zip,

       -- Location - standardized borough, just in case
       CASE
           WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('1', 'MANHATTAN') THEN 'Manhattan'
           WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('2', 'BRONX') THEN 'Bronx'
           WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('3', 'BROOKLYN') THEN 'Brooklyn'
           WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('4', 'QUEENS') THEN 'Queens'
           WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('5', 'STATEN ISLAND') THEN 'Staten Island'
           ELSE 'UNKNOWN or CITYWIDE'
       END AS borough,

       CAST(house_no AS STRING) AS house_number,
       CAST(street_name AS STRING) AS street_name,
       CAST(block AS STRING) AS block,
       CAST(lot AS STRING) AS lot,
       CAST(bin AS STRING) AS building_id,
       CAST(latitude AS DECIMAL) AS latitude,
       CAST(longitude AS DECIMAL) AS longitude,

       -- Metadata
       CURRENT_TIMESTAMP() AS _stg_loaded_at

   FROM source

   -- Filters
   WHERE job_filing_number IS NOT NULL
   AND filing_date IS NOT NULL
   AND CAST(filing_date AS DATE) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 YEAR)
   AND borough IS NOT NULL

   -- Deduplicate
   QUALIFY ROW_NUMBER() OVER (PARTITION BY job_filing_number ORDER BY filing_date DESC) = 1
)

SELECT * FROM cleaned
-- All should be part of this table after running: stg_nyc_dob_job_filings
