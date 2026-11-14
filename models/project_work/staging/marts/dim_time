
-- Time dimension shared by NYC HPD 311 Service Requests
-- Used for created_time_key and closed_time_key

WITH all_hours AS (

    -- Generate all 24 hours of the day
    SELECT hour
    FROM UNNEST(GENERATE_ARRAY(0, 23)) AS hour

),

time_dimension AS (

    SELECT

        -- Hour-based surrogate key
        hour AS time_key,

        hour,

        -- Categorize time of day
        CASE
            WHEN hour >= 5 AND hour < 12
                THEN 'Morning'
            WHEN hour >= 12 AND hour < 17
                THEN 'Afternoon'
            WHEN hour >= 17 AND hour < 21
                THEN 'Evening'
            ELSE 'Night'
        END AS time_of_day,

        -- Business hours: 9 AM to 5 PM
        CASE
            WHEN hour >= 9 AND hour < 17
                THEN TRUE
            ELSE FALSE
        END AS is_business_hours

    FROM all_hours

),

-- Placeholder for missing times

null_placeholder AS (

    SELECT
        CAST(-1 AS INT64) AS time_key,
        CAST(NULL AS INT64) AS hour,
        CAST(NULL AS STRING) AS time_of_day,
        CAST(NULL AS BOOLEAN) AS is_business_hours

)

SELECT * FROM time_dimension

UNION ALL

SELECT * FROM null_placeholder
