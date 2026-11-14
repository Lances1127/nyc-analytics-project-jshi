 SELECT
     unique_key,
     created_date,
     complaint_type,
     borough
 FROM {{ source('raw', 'stg_nyc_hpd_311_service_requests') }}
 LIMIT 10