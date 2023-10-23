{{
    config(
        materialized = "incremental",
        on_schema_change = "fail",
        schema = "stage"
       
    )
}}

SELECT
  DISTINCT number,
  SUM(transaction_count) AS total
FROM
  `elegant-device-332415.raw.crypto_bitcoin_blocks`
GROUP BY
  1
ORDER BY
  2 DESC