WITH protocol_txs AS (
    SELECT
        block_time,
        block_date,
        hash AS tx_hash,
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
            0x30c791e4654edac575fa1700ed8633cb2fede871, -- PlumeStaking
            0x816f722424b49cf1275cc86da9840fbd5a6167e9  -- vault_plume
        )
),

wallet_activity AS (
    SELECT
        wallet,
        protocol,
        COUNT(*) AS tx_count,
        COUNT(DISTINCT block_date) AS active_days,
        MIN(block_time) AS first_tx,
        MAX(block_time) AS last_tx
    FROM protocol_txs
    GROUP BY wallet, protocol
),

ranked AS (
    SELECT
        wallet,
        protocol,
        tx_count,
        active_days,
        first_tx,
        last_tx,
        ROW_NUMBER() OVER (
            PARTITION BY protocol
            ORDER BY tx_count DESC
        ) AS rank
    FROM wallet_activity
)

SELECT
    protocol,
    rank,
    wallet,
    tx_count,
    active_days,
    first_tx,
    last_tx
FROM ranked
WHERE rank <= 20
ORDER BY protocol, rank;
