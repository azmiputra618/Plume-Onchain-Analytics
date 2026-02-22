WITH wplume_txs AS (
    SELECT
        block_time,
        hash AS tx_hash,
        "from" AS wallet
    FROM plume.transactions
    WHERE
        "to" = 0xea237441c92cae6fc17caaf9a7acb3f953be4bd1
        AND success = TRUE
),

wallet_activity AS (
    SELECT
        wallet,
        COUNT(*) AS tx_count,
        COUNT(DISTINCT block_time) AS active_days,
        MIN(block_time) AS first_tx,
        MAX(block_time) AS last_tx
    FROM wplume_txs
    GROUP BY wallet
),

ranked AS (
    SELECT
        wallet,
        tx_count,
        active_days,
        first_tx,
        last_tx,
        ROW_NUMBER() OVER (ORDER BY tx_count DESC) AS rank
    FROM wallet_activity
)

SELECT *
FROM ranked
WHERE rank <= 20
ORDER BY rank;
