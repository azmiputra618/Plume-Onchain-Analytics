WITH protocol_txs AS (
    SELECT
        block_date,
        "from" AS wallet,
        CASE
            WHEN "to" = 0x30c791e4654edac575fa1700ed8633cb2fede871
                THEN 'PlumeStaking'
            WHEN "to" = 0x816f722424b49cf1275cc86da9840fbd5a6167e9
                THEN 'Vault'
        END AS protocol
    FROM plume.transactions
    WHERE
        success = TRUE
        AND "to" IN (
            0x30c791e4654edac575fa1700ed8633cb2fede871,
            0x816f722424b49cf1275cc86da9840fbd5a6167e9
        )
),

wallet_activity AS (
    SELECT
        wallet,
        protocol,
        COUNT(*) AS tx_count,
        COUNT(DISTINCT block_date) AS active_days
    FROM protocol_txs
    GROUP BY wallet, protocol
),

ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY protocol
            ORDER BY tx_count DESC
        ) AS rank
    FROM wallet_activity
),

summary AS (
    SELECT
        protocol,
        SUM(tx_count) AS total_tx,
        SUM(CASE WHEN rank <= 20 THEN tx_count ELSE 0 END) AS top20_tx,
        COUNT(DISTINCT wallet) AS total_wallets,
        COUNT(DISTINCT CASE WHEN active_days >= 120 THEN wallet END) AS long_term_wallets
    FROM ranked
    GROUP BY protocol
)

SELECT
    protocol,
    total_wallets,
    long_term_wallets,
    ROUND(top20_tx * 1.0 / total_tx, 4) AS top20_activity_share,
    CASE
        WHEN top20_tx * 1.0 / total_tx > 0.7 THEN 'HIGH'
        WHEN top20_tx * 1.0 / total_tx > 0.5 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS centralization_risk
FROM summary
ORDER BY protocol;
