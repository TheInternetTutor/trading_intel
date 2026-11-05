
include "utilities";

def increase_position($live):

  debug(">>> increase_position() EXECUTING")
  | . as $records

  | ($records
      | map(
          select(.record_type == "summary")
          | {(.symbol): .quantity}
        )
      | add
    ) as $li_positions

  | ($live
      | map(
          select(
            .position > 0
            and
            (.symbol as $s
             | ($li_positions[$s] // 0) > 0
             and
             .position > ($li_positions[$s] // 0)
            )
          )
        )
    ) as $increases

  | reduce $increases[] as $p
      ($records;

       ($p.position - ($li_positions[$p.symbol] // 0)) as $increase


| debug(
    ">>> INCREASE CONFIRMED: "
    + $p.symbol
    + " live=" + ($p.position | tostring)
    + " summary=" + ($li_positions[$p.symbol] | tostring)
    + " increase=" + (($p.position - ($li_positions[$p.symbol] // 0)) | tostring)
  )

       | make_derived_record($records[0]; $p; "lot")


       | .quantity = $increase
       | .position_value = ($increase * $p.mark_price)
       | .lot_id = "---"

       | . as $lot

| debug(
    ">>> DERIVED RECORD: "
    + "symbol=" + (.symbol | tostring)
    + " quantity=" + (.quantity | tostring)
    + " lock_state=" + (.lock_state | tostring)
    + " lot_id=" + (.lot_id | tostring)
  )

       | $records + [$lot]

       | map(
           if .symbol == $p.symbol
              and .record_type == "summary"
           then
             .quantity = $p.position
           else
             .
           end
         )
      )
;
