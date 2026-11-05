
#=======================================================================
def live_positions_to_index:

  reduce .[] as $r
  (
    {};

    .[$r.symbol] = $r
  )
;


#=======================================================================
def human_duration:
  . as $n
  | ($n / 365 | floor) as $y
  | ($n % 365) as $r1
  | ($r1 / 30 | floor) as $m
  | ($r1 % 30) as $r2
  | ($r2 / 7 | floor) as $w
  | ($r2 % 7) as $d
  | (
      (if $y > 0 then ($y | tostring) + "y" else "" end) +
      (if $m > 0 then ($m | tostring) + "m" else "" end) +
      (if $w > 0 then ($w | tostring) + "w" else "" end) +
      (if $d > 0 or $n == 0 then ($d | tostring) + "d" else "" end)
    )
;

#=======================================================================
def now_local:
  now
  -
  (
    if
      ((now | strftime("%j") | tonumber) >= 308)
      or
      ((now | strftime("%j") | tonumber) < 70)
    then
      5 * 3600
    else
      4 * 3600
    end
  )
;

#=======================================================================
def make_derived_record($template; $p; $type):

  $template
  | .symbol = $p.symbol
  | .lock_state = "---"
  | .quantity = $p.position
  | .mark_price = $p.mark_price
  | .open_price = $p.avg_cost
  | .fifo_pnl_unrealized = "---"
  | .position_value = "---"
  | .description = "---"
  | .report_date = (now | strftime("%Y%m%d"))
  | .record_type = $type
  | .side = (if $p.position > 0 then "Long" else "Short" end)
  | .accrued_interest = "---"
  | .account_id = $p.account
  | .account_alias = "---"
  | .lock_condition = "---"
  | .locking_lot_id = "---"
  | .locking_lots_pnl = "---"
  | .listing_exchange = $p.exchange
  | .currency = "---"
  | .lot_icons = "---"
  | .lot_age = "---"
  | .asset_class = "---"
  | .conid = "---"
  | .originating_transaction_id = "---"
  | .originating_order_id = "---"
  | .serial_number = "---"
  | .cost_basis_price = $p.avg_cost
  | .last_dummy = "---"

  | if $type == "summary" then
      .open_date = "---"
      | .open_time = "---"
      | .holding_date = "---"
      | .holding_time = "---"
      | .lot_id = ($p.symbol + "_" + (now | strftime("%Y%m%d")) + "_SUMMARY")
      | .open_datetime_raw = "---"
      | .holding_datetime_raw = "---"

    else
      .open_date = (now_local | strftime("%Y-%m-%d"))
      | .open_time = (now_local | strftime("%H:%M:%S"))
      | .holding_date = (now_local | strftime("%Y-%m-%d"))
      | .holding_time = (now_local | strftime("%H:%M:%S"))
      | .lot_id = "---"
      | .open_datetime_raw = (now_local | strftime("%Y%m%d;%H%M%S"))
      | .holding_datetime_raw = (now_local | strftime("%Y%m%d;%H%M%S"))
    end
;

#=======================================================================
def retain_reversal_records($symbol):

  . as $records

  | ($records
      | map(select(.symbol == $symbol and .record_type == "summary"))
      | .[0]
    ) as $summary

  | ($records
      | map(select(.symbol == $symbol and .record_type == "lot"))
      | .[-1]
    ) as $lot

  | $records
  | map(select(.symbol != $symbol))
  | if $summary and $lot then
      . + [$summary, $lot]
    else
      .
    end
;
