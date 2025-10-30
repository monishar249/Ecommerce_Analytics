-- CREATE DATABASE
create database Project;
use project;

select * from seller_enrollment;

-- CLEAN ANY INCONSISTENCY IN DATA
select distinct (seller_id) from seller_enrollment;
select distinct(campaign_id) from seller_enrollment;
select distinct (platform) from seller_enrollment;
select distinct (category) from seller_enrollment;
select distinct (kind) from seller_enrollment;
select distinct (region) from seller_enrollment;
select distinct (manual_file_ingested) from seller_enrollment;
select distinct (optin_cta_tagged) from seller_enrollment;
select distinct (impression_tag_valid) from seller_enrollment;

SELECT COUNT(*) AS total_rows,
       SUM(CASE WHEN enrollment_date = '' THEN 1 ELSE 0 END) AS blank_date
FROM seller_enrollment;

DELETE FROM seller_enrollment
WHERE enrollment_date IS NULL OR TRIM(enrollment_date) = '';

-- FUNNEL DROP ANALYSIS
 select impressions, clicks,enrolled from seller_enrollment;
 
 -- PLATFORM
with platform_stages_count as(
select platform,sum(impressions) as impression_sum,
				sum(clicks) as clicks_sum,
                sum(enrolled) as enrolled_sum,
                (sum(clicks)/sum(impressions))*100 as ctr,
                (sum(enrolled)/sum(clicks))*100 as enrollment_from_clicks,
                (sum(enrolled)/sum(impressions))*100 as enrollment_from_impressions,
                (100-(sum(clicks)/sum(impressions))*100) as drop_off1,
                (100- (sum(enrolled)/sum(clicks))*100) as dropoff2
 from seller_enrollment
 group by platform)
 select *from platform_stages_count;

-- CATEGORY
WITH category_stages_count AS (
    SELECT category, SUM(impressions) AS impression_sum,
					SUM(clicks) AS clicks_sum,
					SUM(enrolled) AS enrolled_sum,
					(SUM(clicks)/SUM(impressions))*100 AS ctr,
					(SUM(enrolled)/SUM(clicks))*100 AS enrollment_from_clicks,
					(SUM(enrolled)/SUM(impressions))*100 AS enrollment_from_impressions,
					(100 - (SUM(clicks)/SUM(impressions))*100) AS drop_off1,
					(100 - (SUM(enrolled)/SUM(clicks))*100) AS dropoff2
    FROM seller_enrollment
    GROUP BY category)
SELECT * FROM category_stages_count;

WITH kind_stages_count AS (
    SELECT kind, SUM(impressions) AS impression_sum,
				SUM(clicks) AS clicks_sum,
				SUM(enrolled) AS enrolled_sum,
				(SUM(clicks)/SUM(impressions))*100 AS ctr,
				(SUM(enrolled)/SUM(clicks))*100 AS enrollment_from_clicks,
				(SUM(enrolled)/SUM(impressions))*100 AS enrollment_from_impressions,
				(100 - (SUM(clicks)/SUM(impressions))*100) AS drop_off1,
				(100 - (SUM(enrolled)/SUM(clicks))*100) AS dropoff2
    FROM seller_enrollment
    GROUP BY kind)
SELECT * FROM kind_stages_count;

WITH manual_file_ingested_stages_count AS (
    SELECT manual_file_ingested, SUM(impressions) AS impression_sum,
								SUM(clicks) AS clicks_sum,
								SUM(enrolled) AS enrolled_sum,
								(SUM(clicks)/SUM(impressions))*100 AS ctr,
								(SUM(enrolled)/SUM(clicks))*100 AS enrollment_from_clicks,
								(SUM(enrolled)/SUM(impressions))*100 AS enrollment_from_impressions,
								(100 - (SUM(clicks)/SUM(impressions))*100) AS drop_off1,
								(100 - (SUM(enrolled)/SUM(clicks))*100) AS dropoff2
    FROM seller_enrollment
    GROUP BY manual_file_ingested)
SELECT * FROM manual_file_ingested_stages_count;

-- CORRELATION FOR POOR ENROLMENT AND OPTIN_CTA_TAGGED

WITH seller_metrics AS (
    SELECT  
        optin_cta_tagged,
        SUM(clicks) AS clicks,
        SUM(enrolled) AS enrolled,
        (SUM(enrolled)*1.0 / NULLIF(SUM(clicks),0)) AS enroll_rate
    FROM seller_enrollment
    GROUP BY optin_cta_tagged
),
overall_avg AS (
    SELECT AVG(enroll_rate) AS avg_rate FROM seller_metrics
),
flagged AS (
    SELECT 
        optin_cta_tagged,
        enroll_rate,
        CASE 
            WHEN enroll_rate < (SELECT avg_rate FROM overall_avg) THEN 1 
            ELSE 0 
        END AS poor_flag,
        CASE 
            WHEN optin_cta_tagged = 'Yes' THEN 1 
            ELSE 0 
        END AS optin_flag
    FROM seller_metrics
),
correlation_calc AS (
    SELECT
        (
            (AVG(poor_flag * optin_flag) - (AVG(poor_flag) * AVG(optin_flag))) /
            (STDDEV(poor_flag) * STDDEV(optin_flag))
        ) AS corr_poor_optin
    FROM flagged
)
SELECT * FROM correlation_calc;

-- CORRELATION FOR POOR ENROLMENT AND IMPRESSION TAG VALID

WITH seller_metrics AS (
    SELECT  
        impression_tag_valid,
        SUM(clicks) AS clicks,
        SUM(enrolled) AS enrolled,
        (SUM(enrolled)*1.0 / NULLIF(SUM(clicks),0)) AS enroll_rate
    FROM seller_enrollment
    GROUP BY impression_tag_valid
),
overall_avg AS (
    SELECT AVG(enroll_rate) AS avg_rate FROM seller_metrics
),
flagged AS (
    SELECT 
        impression_tag_valid,
        enroll_rate,
        CASE 
            WHEN enroll_rate < (SELECT avg_rate FROM overall_avg) THEN 1 
            ELSE 0 
        END AS poor_flag,
        CASE 
            WHEN impression_tag_valid = 'Yes' THEN 1 
            ELSE 0 
        END AS impression_flag
    FROM seller_metrics
),
correlation_calc AS (
    SELECT
        (
            (AVG(poor_flag * impression_flag) - (AVG(poor_flag) * AVG(impression_flag))) /
            (STDDEV(poor_flag) * STDDEV(impression_flag))
        ) AS corr_poor_impression
    FROM flagged
)
SELECT * FROM correlation_calc;

-- TAGGING VALIDATION

WITH tagging_metrics AS (
    SELECT  
        optin_cta_tagged,
        impression_tag_valid,
        SUM(clicks) AS total_clicks,
        SUM(enrolled) AS total_enrolled,
        (SUM(enrolled)*1.0 / NULLIF(SUM(clicks), 0)) AS enroll_rate
    FROM seller_enrollment
    GROUP BY optin_cta_tagged, impression_tag_valid
),
overall_avg AS (
    SELECT AVG(enroll_rate) AS avg_rate FROM tagging_metrics
),
flagged AS (
    SELECT 
        optin_cta_tagged,
        impression_tag_valid,
        enroll_rate,
        CASE 
            WHEN enroll_rate < (SELECT avg_rate FROM overall_avg) THEN 1 
            ELSE 0 
        END AS poor_flag
    FROM tagging_metrics
)
SELECT 
    optin_cta_tagged,
    impression_tag_valid,
    COUNT(*) AS total_groups,
    SUM(poor_flag) AS poor_groups,
    ROUND(SUM(poor_flag)*100.0/COUNT(*),2) AS pct_poor_groups,
    ROUND(AVG(enroll_rate)*100,2) AS avg_enroll_rate
FROM flagged
GROUP BY optin_cta_tagged, impression_tag_valid
ORDER BY pct_poor_groups DESC;

select distinct(seller_tenure_months) as mn
from seller_enrollment
order by mn;

-- seller_tenure_months vs enrollment conversion

WITH seller_metrics AS (
    SELECT  
        seller_tenure_months,
        SUM(clicks) AS total_clicks,
        SUM(enrolled) AS total_enrolled,
        CASE 
            WHEN SUM(clicks) = 0 THEN 0 
            ELSE (SUM(enrolled)*1.0 / SUM(clicks))*100 
        END AS conversion_rate
    FROM seller_enrollment
    GROUP BY seller_tenure_months
),
bucketed AS (
    SELECT
        CASE 
            WHEN seller_tenure_months BETWEEN 0 AND 12 THEN 'BEGINNER'
            WHEN seller_tenure_months BETWEEN 13 AND 24 THEN 'INTERMEDIATE'
            WHEN seller_tenure_months BETWEEN 25 AND 36 THEN 'EXPERIENCE'
            ELSE '36+ months'
        END AS tenure_bucket,
        ROUND(AVG(conversion_rate),2) AS avg_conversion_rate,
        SUM(total_clicks) AS total_clicks,
        SUM(total_enrolled) AS total_enrolled
    FROM seller_metrics
    GROUP BY tenure_bucket
)
SELECT * FROM bucketed
ORDER BY tenure_bucket;

--  if higher risk_rating impacts enrollment likelihood
WITH risk_metrics AS (
    SELECT  
        risk_rating,
        SUM(clicks) AS total_clicks,
        SUM(enrolled) AS total_enrolled,
        CASE 
            WHEN SUM(clicks) = 0 THEN 0 
            ELSE (SUM(enrolled)*1.0 / SUM(clicks))*100 
        END AS enrollment_rate
    FROM seller_enrollment
    GROUP BY risk_rating
),
stats AS (
    SELECT
        AVG(enrollment_rate) AS avg_enrollment_rate
    FROM risk_metrics
),
flagged AS (
    SELECT
        r.risk_rating,
        r.enrollment_rate,
        CASE WHEN r.enrollment_rate < s.avg_enrollment_rate THEN 1 ELSE 0 END AS poor_flag
    FROM risk_metrics r
    CROSS JOIN stats s
)
SELECT * FROM flagged
ORDER BY risk_rating;

-- which products (product_opted) are more popular across seller types
WITH product_popularity AS (
SELECT 
        kind,
        product_opted,
        COUNT(DISTINCT seller_id) AS seller_count,
        SUM(enrolled) AS total_enrollments
    FROM seller_enrollment
    GROUP BY kind, product_opted),
ranked_products AS (
    SELECT 
        kind,
        product_opted,
        seller_count,
        total_enrollments,
        RANK() OVER (PARTITION BY kind ORDER BY total_enrollments DESC) AS product_rank
    FROM product_popularity
)
SELECT * 
FROM ranked_products
WHERE product_rank = 1;

