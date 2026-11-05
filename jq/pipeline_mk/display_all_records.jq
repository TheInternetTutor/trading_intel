
group_by([
  .symbol,
  .open_datetime_raw,
  .originating_transaction_id,
  .originating_order_id
])
| map(select(length > 1))
| .[]
| .[]
| to_entries
| map(.value|tostring)
| join(" | ")
