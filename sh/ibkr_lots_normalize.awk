#!/usr/bin/awk -f

###############################################################################
# ibkr_lots_normalize.awk
#
# Input:
#   Open Position Lots CSV
#   Header row must be present.
#
# Output:
#   JSONL (one JSON object per line)
#
###############################################################################

BEGIN {
    FPAT = "([^,]+)|(\"([^\"]|\"\")*\")"
}

###############################################################################
# utility functions
###############################################################################

function trim_quotes(s)
{
    gsub(/^"/, "", s)
    gsub(/"$/, "", s)
    gsub(/""/, "\"", s)
    return s
}

function json_escape(s)
{
    gsub(/\\/,"\\\\",s)
    gsub(/"/,"\\\"",s)
    gsub(/\t/,"\\t",s)
    gsub(/\r/,"\\r",s)
    gsub(/\n/,"\\n",s)
    return s
}

function split_dt(dt, arr,   d,t)
{
    arr["date"] = ""
    arr["time"] = ""

    if (dt == "")
        return

    split(dt, tmp, ";")

    d = tmp[1]
    t = tmp[2]

    if (length(d) == 8)
        arr["date"] = substr(d,1,4) "-" substr(d,5,2) "-" substr(d,7,2)

    if (length(t) == 6)
        arr["time"] = substr(t,1,2) ":" substr(t,3,2) ":" substr(t,5,2)
}

#-----------------------------------------------------------------------
function display_jsonl_record_v01() # **legacy**
{
  printf "{"

  printf "\"record_type\":\"%s\",", record_type
  printf "\"lot_id\":\"%s\",", json_escape(lot_id)
  printf "\"lock_state\":\"%s\",", lock_state
  printf "\"lot_icons\":\"%s\",", lot_icons;

  printf "\"lock_condition\":\"%s\",", lock_condition
  printf "\"locking_lot_id\":\"%s\",", locking_lot_id

  printf "\"locking_lot_price\":\"%s\",", locking_lot_price;
  printf "\"locking_lot_age\":\"%s\",", locking_lot_age;
  printf "\"locking_lot_pnl\":\"%s\",", locking_lot_pnl;
  printf "\"locking_lot_id\":\"%s\",", locking_lot_id;

  printf "\"report_date\":\"%s\",", report_date
  printf "\"symbol\":\"%s\",", json_escape(symbol)
  printf "\"conid\":\"%s\",", conid
  printf "\"asset_class\":\"%s\",", asset_class
  printf "\"currency\":\"%s\",", currency

  printf "\"open_datetime_raw\":\"%s\",", open_datetime_raw
  printf "\"open_date\":\"%s\",", odt["date"]
  printf "\"open_time\":\"%s\",", odt["time"]

  printf "\"quantity\":%s,", quantity
  printf "\"cost_basis_price\":%s,", cost_basis_price
  printf "\"open_price\":%s,", open_price
  printf "\"mark_price\":%s,", mark_price
  printf "\"fifo_pnl_unrealized\":%s,", fifo_pnl_unrealized
  printf "\"position_value\":%s,", position_value

  printf "\"account_id\":\"%s\",", account_id
  printf "\"account_alias\":\"%s\",", account_alias

  printf "\"originating_transaction_id\":\"%s\",",
         originating_transaction_id

  printf "\"originating_order_id\":\"%s\",",
         originating_order_id

  printf "\"serial_number\":\"%s\",", serial_number
  printf "\"listing_exchange\":\"%s\",", listing_exchange
  printf "\"side\":\"%s\",", side

  printf "\"multiplier\":%s,", multiplier

  printf "\"description\":\"%s\",",
         json_escape(description)

  printf "\"holding_datetime_raw\":\"%s\",",
         holding_datetime_raw

  printf "\"holding_date\":\"%s\",",
         hdt["date"]

  printf "\"holding_time\":\"%s\",",
         hdt["time"]

  printf "\"accrued_interest\":\"%s\"",
         accrued_interest

  printf "}\n"

  return 0;
}

#-----------------------------------------------------------------------
function display_jsonl_record()
{
  printf "{"

  printf "\"symbol\":\"%s\",", json_escape(symbol)
  printf "\"lock_state\":\"%s\",", lock_state
  printf "\"quantity\":%s,", quantity
  printf "\"mark_price\":%s,", mark_price
  printf "\"open_price\":%s,", open_price
  printf "\"fifo_pnl_unrealized\":%s,", fifo_pnl_unrealized
  printf "\"open_date\":\"%s\",", odt["date"]
  printf "\"open_time\":\"%s\",", odt["time"]
  printf "\"position_value\":%s,", position_value
  printf "\"description\":\"%s\",", json_escape(description)

  printf "\"report_date\":\"%s\",", report_date
  printf "\"record_type\":\"%s\",", record_type
  printf "\"side\":\"%s\",", side
  printf "\"multiplier\":%s,", multiplier
  printf "\"accrued_interest\":\"%s\",", accrued_interest

  printf "\"holding_date\":\"%s\",", hdt["date"]
  printf "\"holding_time\":\"%s\",", hdt["time"]

  printf "\"account_id\":\"%s\",", account_id
  printf "\"account_alias\":\"%s\",", account_alias

  printf "\"lock_condition\":\"%s\",", lock_condition
  printf "\"locking_lot_id\":\"%s\",", locking_lot_id
  printf "\"locking_lots_pnl\":\"%s\",", locking_lots_pnl

  printf "\"listing_exchange\":\"%s\",", listing_exchange
  printf "\"currency\":\"%s\",", currency
  printf "\"lot_icons\":\"%s\",", lot_icons
  printf "\"lot_age\":\"%s\",", lot_age
  printf "\"asset_class\":\"%s\",", asset_class

  printf "\"lot_id\":\"%s\",", json_escape(lot_id)
  printf "\"conid\":\"%s\",", conid
  printf "\"originating_transaction_id\":\"%s\",", originating_transaction_id
  printf "\"originating_order_id\":\"%s\",", originating_order_id
  printf "\"serial_number\":\"%s\",", serial_number

  printf "\"cost_basis_price\":%s,", cost_basis_price
  printf "\"open_datetime_raw\":\"%s\",", open_datetime_raw
  printf "\"holding_datetime_raw\":\"%s\",", holding_datetime_raw

  printf "\"last_dummy\":\"%s\"", "---"

  printf "}\n"

  return 0;
}


###############################################################################
# header
###############################################################################

NR == 1 {

    for (i = 1; i <= NF; i++) {
        hdr[i] = trim_quotes($i)
    }

    next
}

###############################################################################
# records
###############################################################################

{
  # **Note to AI:**
  # Consider moving some of the initialized variables in this script to
  # the appropriate JQ script; mainly those not requiring conditional
  # logic for initialization.

  lot_id            = "---"; # currently used
  lot_icons         = "---"; # future implementation
  lot_age           = "---"; # future implementation

  lock_state        = "---"; # currently used
  lock_condition    = "---"; # currently used

  locking_lot_id    = "---"; # currently used
  locking_lots_pnl  = "---"; # sum of LOS lots acquired after current lot

  for (i = 1; i <= NF; i++) {
      v[i] = trim_quotes($i)
  }

  report_date                = (v[1]  == ""? "---": v[1] );
  symbol                     = (v[2]  == ""? "---": v[2] );
  conid                      = (v[3]  == ""? "---": v[3] );
  asset_class                = (v[4]  == ""? "---": v[4] );
  currency                   = (v[5]  == ""? "---": v[5] );
  open_datetime_raw          = (v[6]  == ""? "---": v[6] );
  quantity                   = (v[7]  == ""? "---": v[7] );
  cost_basis_price           = (v[8]  == ""? "---": v[8] );
  open_price                 = (v[9]  == ""? "---": v[9] );
  mark_price                 = (v[10] == ""? "---": v[10]);
  fifo_pnl_unrealized        = (v[11] == ""? "---": v[11]);
  position_value             = (v[12] == ""? "---": v[12]);
  account_id                 = (v[13] == ""? "---": v[13]);
  account_alias              = (v[14] == ""? "---": v[14]);
  originating_transaction_id = (v[15] == ""? "---": v[15]);
  originating_order_id       = (v[16] == ""? "---": v[16]);
  serial_number              = (v[17] == ""? "---": v[17]);
  listing_exchange           = (v[18] == ""? "---": v[18]);
  side                       = (v[19] == ""? "---": v[19]);
  multiplier                 = (v[20] == ""? "---": v[20]);
  description                = (v[21] == ""? "---": v[21]);
  holding_datetime_raw       = (v[22] == ""? "---": v[22]);
  accrued_interest           = (v[23] == ""? "---": v[23]);

  # record_type = (open_datetime_raw == "---" ? "summary" : "lot")
  if (open_datetime_raw == "---") {
    record_type = "summary";
    lock_state = "05.SMR"
  } else {
    record_type = "lot";
  }

  if (originating_transaction_id != "---")
      lot_id = originating_transaction_id
  else
      lot_id = symbol "_" report_date "_SUMMARY"

  delete odt
  delete hdt

  split_dt(open_datetime_raw, odt)
      odt["date"] = (odt["date"] != ""? odt["date"]: "---")
      odt["time"] = (odt["time"] != ""? odt["time"]: "---")
  split_dt(holding_datetime_raw, hdt)
      hdt["date"] = (hdt["date"] != ""? hdt["date"]: "---")
      hdt["time"] = (hdt["time"] != ""? hdt["time"]: "---")

  display_jsonl_record();

}
