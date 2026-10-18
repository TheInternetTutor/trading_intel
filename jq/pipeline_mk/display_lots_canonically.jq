
sort_by(
  .symbol,
  .open_datetime_raw,
  .originating_transaction_id,
  .originating_order_id
)
| .[]
