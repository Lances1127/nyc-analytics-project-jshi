WITH stg_311 AS (

    SELECT *
    FROM {{ ref('stg_nyc_hpd_311_service_requests') }}

),

dim_time AS (

    SELECT *
    FROM {{ ref('dim_time') }}

),

fact_data AS (

    SELECT
        s.unique_key,

        COALESCE(
            EXTRACT(HOUR FROM s.created_date),
            -1
        ) AS created_time_key,

        COALESCE(
            EXTRACT(HOUR FROM s.closed_date),
            -1
        ) AS closed_time_key

    FROM stg_311 s

)

SELECT
    f.unique_key,
    f.created_time_key,
    f.closed_time_key

FROM fact_data f

LEFT JOIN dim_time ct
    ON f.created_time_key = ct.time_key

LEFT JOIN dim_time cl
    ON f.closed_time_key = cl.time_key