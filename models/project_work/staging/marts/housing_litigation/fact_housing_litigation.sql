-- One row per litigation_id from stg_nyc_housing_litigations.
-- Dimension joins use the full natural-key combinations currently used by the dimensions.
{{ config(materialized='table') }}

WITH stg_litigation AS (
    SELECT * FROM {{ ref('stg_nyc_housing_litigations') }}
),
dim_date AS (
    SELECT * FROM {{ ref('dim_date') }}
),
dim_building AS (
    SELECT * FROM {{ ref('dim_building') }}
),
dim_location AS (
    SELECT * FROM {{ ref('dim_location') }}
),
fact AS (
    SELECT
        s.litigation_id,
        b.building_key,
        COALESCE(l.location_key, '-1') AS location_key,
        COALESCE(open_d.date_key, -1) AS caseopendate_key,
        COALESCE(finding_d.date_key, -1) AS findingdate_key,
        s.case_type,
        s.status AS case_status,
        s.case_judgement,
        s.harassment_finding,
        s.penalty_usd,
        s.respondent
    FROM stg_litigation AS s
    LEFT JOIN dim_building AS b
        ON s.building_id IS NOT DISTINCT FROM b.buildingid
       AND s.street_name IS NOT DISTINCT FROM b.streetname
       AND s.zip IS NOT DISTINCT FROM b.zip
       AND REGEXP_EXTRACT(s.incident_address, r'^\S*\d+') IS NOT DISTINCT FROM b.housenumber
    LEFT JOIN dim_location AS l
        ON s.borough IS NOT DISTINCT FROM l.borough
       AND s.council_district IS NOT DISTINCT FROM l.council_district
       AND s.zip IS NOT DISTINCT FROM l.zip
       -- dim_location's litigation UNION currently places street_name in incident_address
       AND s.street_name IS NOT DISTINCT FROM l.incident_address
       AND s.bbl IS NOT DISTINCT FROM l.bbl
       AND s.community_district IS NOT DISTINCT FROM l.community_board
       AND s.latitude IS NOT DISTINCT FROM l.latitude
       AND s.longitude IS NOT DISTINCT FROM l.longitude
    LEFT JOIN dim_date AS open_d
        ON CAST(s.created_date AS DATE) = open_d.full_date
    LEFT JOIN dim_date AS finding_d
        ON CAST(s.harassment_finding_date AS DATE) = finding_d.full_date
)
SELECT * FROM fact
