#-----------------------------------------------------------------------
# update_mark_prices.jq
#
# Input:
#   One JSONL stream containing:
#     - Flex records (lots + summaries)
#     - Live records (record_type == "live")
#
# Output:
#   Updated Flex records only.
#-----------------------------------------------------------------------

# Build an index of live records.
reduce inputs as $r
(
  {
    "live": {},
    "flex": []
  };

  if $r.record_type == "live" then
    .live[$r.symbol] = $r
  else
    .flex += [$r]
  end
)

# Emit the updated Flex records.
| . as $db
| $db.flex[]
| if $db.live[.symbol] then
    .mark_price = $db.live[.symbol].mark_price
    | .position_value =
        (
            .mark_price
            * .quantity
            * .multiplier
        )
    | .fifo_pnl_unrealized =
        (
            .position_value
            - (
                .cost_basis_price
                * .quantity
                * .multiplier
            )
        )
  else
    .
  end
