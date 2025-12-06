-- channel_funnel_monthly.sql
-- Daily channel funnel performance
-- Grain: date x channel

DROP TABLE IF EXISTS public.channel_funnel_monthly;

CREATE TABLE public.channel_funnel_monthly AS
WITH marketing AS (
    SELECT
        DATE_TRUNC('month', DATE(date))::DATE as month,
        channel,
        SUM(spend_usd)      AS spend_usd,
        SUM(clicks)         AS clicks,
        SUM(impressions)    AS impressions,
        SUM(sessions)       AS sessions,
        SUM(conversions)    AS conversions
    FROM public.marketing_funnel_daily
    GROUP BY 1, 2
),
sales AS (
    SELECT
        DATE_TRUNC('month', DATE(created_date))::DATE as month,
        source as channel,
        COUNT(*)                                  AS opps_created,
        SUM(CASE WHEN upper(stage) = 'CLOSED WON' THEN 1 ELSE 0 END) AS opps_closed_won,
        SUM(CASE WHEN upper(stage) = 'CLOSED WON' THEN amount_usd ELSE 0 END) AS revenue_closed_won
    FROM public.salesforce_opportunities
    GROUP BY 1, 2
)
SELECT
    COALESCE(m.month, s.month)::DATE     AS month,
    COALESCE(m.channel, s.channel) AS channel,
    COALESCE(m.spend_usd, 0)       AS spend_usd,
    COALESCE(m.clicks, 0)          AS clicks,
    COALESCE(m.impressions, 0)     AS impressions,
    COALESCE(m.sessions, 0)        AS sessions,
    COALESCE(m.conversions, 0)     AS conversions,
    COALESCE(s.opps_created, 0)    AS opps_created,
    COALESCE(s.opps_closed_won, 0) AS opps_closed_won,
    COALESCE(s.revenue_closed_won, 0) AS revenue_closed_won,
    -- Derived metrics
    CASE WHEN COALESCE(m.sessions, 0) = 0 THEN NULL
         ELSE m.conversions::numeric / NULLIF(m.sessions, 0)
    END AS session_to_conversion_rate,
    CASE WHEN COALESCE(m.conversions, 0) = 0 THEN NULL
         ELSE s.opps_created::numeric / NULLIF(m.conversions, 0)
    END AS conversion_to_opp_rate,
    CASE WHEN COALESCE(m.conversions, 0) = 0 THEN NULL
         ELSE m.spend_usd / NULLIF(m.conversions, 0)
    END AS cost_per_conversion
FROM marketing m
FULL OUTER JOIN sales s
    ON  m.month   = s.month
    AND m.channel = s.channel
ORDER BY month, channel;