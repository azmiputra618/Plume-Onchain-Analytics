WITH protocol_txs AS (
    SELECT
        DATE_TRUNC('day', block_time) AS day,
        DATE_TRUNC('month', block_time) AS month,
        "from" AS wallet,
        CASE
            WHEN "to" = 0x30c791e4654edac575fa1700ed8633cb2fede871 THEN 'PlumeStaking'
            WHEN "to" = 0x816f722424b49cf1275cc86da9840fbd5a6167e9 THEN 'Vault'
        END AS protocol
    FROM plume.transactions
    WHERE
        success = TRUE
        AND "to" IN (
            0x30c791e4654edac575fa1700ed8633cb2fede871,
            0x816f722424b49cf1275cc86da9840fbd5a6167e9
        )
),

lifecycle_base AS (
    SELECT
        wallet,
        protocol,
        MIN(day)  AS first_seen,
        MAX(day)  AS last_seen,
        COUNT(DISTINCT month) AS active_months
    FROM protocol_txs
    GROUP BY wallet, protocol
),

lifecycle_classification AS (
    SELECT
        wallet,
        protocol,
        first_seen,
        last_seen,
        active_months,
        DATE_DIFF('day', last_seen, CURRENT_DATE) AS days_since_last_seen,
        CASE
            WHEN active_months = 1 THEN 'NEW'
            WHEN active_months >= 2 THEN 'RETAINED'
        END AS retention_status,
        CASE
            WHEN DATE_DIFF('day', last_seen, CURRENT_DATE) <= 14 THEN 'ACTIVE'
            WHEN DATE_DIFF('day', last_seen, CURRENT_DATE) > 60 THEN 'CHURNED'
            ELSE 'INACTIVE'
        END AS activity_status
    FROM lifecycle_base
)

SELECT *
FROM lifecycle_classification;
