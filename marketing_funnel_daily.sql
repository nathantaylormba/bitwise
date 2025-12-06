-- marketing_funnel_daily.sql
-- Description: Daily marketing funnel table (spend → clicks → sessions → conversions)
-- Grain: date x channel x utm_source x utm_campaign

DROP TABLE IF EXISTS public.marketing_funnel_daily;

CREATE TABLE public.marketing_funnel_daily AS
WITH ad_agg AS (
    SELECT
        DATE(date) as date,
        channel,
        utm_source,
        utm_campaign,
        SUM(spend_usd) AS spend_usd,
        SUM(clicks) AS clicks,
        SUM(impressions) AS impressions
    FROM public.ad_spend
    GROUP BY 1, 2, 3, 4
),

web_agg AS (
    SELECT
        DATE(session_date) AS date,
        utm_source,
        utm_campaign,
        COUNT(*) AS sessions,
        SUM(pageviews) AS pageviews,
        SUM(conversions) AS conversions
    FROM public.web_analytics
    GROUP BY 1, 2, 3
)

SELECT
    a.date::DATE,
    a.channel,
    a.utm_source,
    a.utm_campaign,
    a.spend_usd,
    a.clicks,
    a.impressions,
    COALESCE(w.sessions, 0) AS sessions,
    COALESCE(w.pageviews, 0) AS pageviews,
    COALESCE(w.conversions, 0) AS conversions
FROM ad_agg a
LEFT JOIN web_agg w
    ON a.date = w.date
    AND a.utm_source = w.utm_source
    AND a.utm_campaign = w.utm_campaign
ORDER BY
    a.date,
    a.channel;