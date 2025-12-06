-- fact_opps_monthly.sql
-- Monthly opportunity fact table by month x channel x campaign_id

DROP TABLE IF EXISTS public.fact_opps_monthly;

CREATE TABLE public.fact_opps_monthly AS
WITH marketing_monthly AS (
    SELECT
        DATE(DATE_TRUNC('month', date)) AS month,
        channel
    FROM public.marketing_funnel_daily
    GROUP BY DATE(DATE_TRUNC('month', date)), channel
),
sales_monthly AS (
    SELECT
        DATE(DATE_TRUNC('month', date(created_date))) AS month,
        source AS channel,

        -- Opportunities created
        SUM(CASE WHEN opportunity_id IS NOT NULL THEN 1 ELSE 0 END) AS ops_created,

        -- Open = any stage not closed won or closed lost
        SUM(CASE WHEN stage NOT IN ('Closed Won', 'Closed Lost') THEN 1 ELSE 0 END) AS ops_open,

        -- Closed won
        SUM(CASE WHEN stage = 'Closed Won' THEN 1 ELSE 0 END) AS ops_closed_won,

        -- Closed lost
        SUM(CASE WHEN stage = 'Closed Lost' THEN 1 ELSE 0 END) AS ops_closed_lost,

        -- Pipeline USD (open opps)
        SUM(CASE WHEN stage NOT IN ('Closed Won', 'Closed Lost') THEN amount_usd ELSE 0 END) AS open_pipeline_usd,

        -- Closed Won USD
        SUM(CASE WHEN stage = 'Closed Won' THEN amount_usd ELSE 0 END) AS closed_won_usd

    FROM public.salesforce_opportunities
    GROUP BY DATE(DATE_TRUNC('month', date(created_date))), source
)

SELECT
    COALESCE(m.month, s.month)     AS month,
    COALESCE(m.channel, s.channel) AS channel,

    -- Counts
    COALESCE(s.ops_created, 0)     AS ops_created,
    COALESCE(s.ops_open, 0)        AS ops_open,
    COALESCE(s.ops_closed_won, 0)  AS ops_closed_won,
    COALESCE(s.ops_closed_lost, 0) AS ops_closed_lost,

    -- Total closed (won + lost)
    COALESCE(s.ops_closed_won, 0)
      + COALESCE(s.ops_closed_lost, 0)
        AS ops_closed_total,

    -- Pipeline & Revenue
    COALESCE(s.open_pipeline_usd, 0) AS open_pipeline_usd,
    COALESCE(s.closed_won_usd, 0)    AS closed_won_usd

FROM marketing_monthly m
FULL OUTER JOIN sales_monthly s
    ON  m.month   = s.month
    AND m.channel = s.channel

ORDER BY month, channel;