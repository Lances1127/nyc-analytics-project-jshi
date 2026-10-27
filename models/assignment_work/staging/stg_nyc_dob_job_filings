
-- Clean and standardize NYC DOB job application data
-- One row per job application filing

WITH source AS (
   SELECT * FROM {{ source('raw', 'source_nyc_dob_job_apps') }}
), -- Easier to refer to the dbt reference to a long name table this way

cleaned AS (
   SELECT
       -- Get all columns from source, except ones we're transforming below
       -- To do cleaning on them or explicitly cast them as types just in case
       * EXCEPT (
           job_s1_no,
           job__,
           doc__,
           pre__filing_date,
           latest_action_date,
           approved,
           job_type,
           job_status,
           job_status_descrp,
           building_type,
           zip,
           borough,
           house__,
           street_name,
           block,
           lot,
           bin__,
           initial_cost,
           job_description
       ),

       -- Identifiers
       CAST(job_s1_no AS STRING) AS filing_id,
       CAST(job__ AS STRING) AS job_id,
       CAST(doc__ AS STRING) AS document_number,

       -- Date/Time
       CAST(pre__filing_date AS TIMESTAMP) AS filing_date,
       CAST(latest_action_date AS TIMESTAMP) AS latest_action_date,
       CAST(approved AS TIMESTAMP) AS approved_date,

       -- Job details
       CAST(job_type AS STRING) AS job_type,
       CAST(job_status AS STRING) AS job_status,
       CAST(job_status_descrp AS STRING) AS job_status_description,
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

       CAST(house__ AS STRING) AS house_number,
       CAST(street_name AS STRING) AS street_name,
       CAST(block AS STRING) AS block,
       CAST(lot AS STRING) AS lot,
       CAST(bin__ AS STRING) AS building_id,

       -- Metadata
       CURRENT_TIMESTAMP() AS _stg_loaded_at

   FROM source

   -- Filters
   WHERE job_s1_no IS NOT NULL
   AND latest_action_date IS NOT NULL
   AND CAST(latest_action_date AS DATE) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 YEAR)
   AND borough IS NOT NULL

   -- Deduplicate
   QUALIFY ROW_NUMBER() OVER (PARTITION BY job_s1_no ORDER BY latest_action_date DESC) = 1
)

SELECT * FROM cleaned
-- All should be part of this table after running: stg_nyc_dob_job_apps
