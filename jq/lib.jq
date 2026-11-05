#=======================================================================
# lib.jq
#
# Internal contract:
#
#   array -> stage -> array
#
# The final .[] converts the completed array back into JSONL.
#=======================================================================
#<disec>----------------------------------------------------------------
########################################################################
# SCRIPT: lib.js
#</disec>----------------------------------------------------------------


include "utilities";
include "increase_position";

#=======================================================================
def display_lots_canonically:

  sort_by(
    .symbol,
    .open_datetime_raw,
    .originating_transaction_id,
    .originating_order_id
  )
;

#=======================================================================
def update_mark_prices($live):

  ($live | live_positions_to_index) as $live_index

  | map(

    if $live_index[.symbol] then

      .mark_price =
        $live_index[.symbol].mark_price

      | .position_value =
          (
            .mark_price
            * .quantity
            * .multiplier
          )

      | .fifo_pnl_unrealized =
          (
            .position_value
            -
            (
              .cost_basis_price
              * .quantity
              * .multiplier
            )
          )

    else

      .

    end

  )
;

#=======================================================================
def consolidate_lots:

  group_by(
    [
      .symbol,
      .open_datetime_raw,
      .originating_transaction_id,
      .originating_order_id
    ]
  )

  | map(

    if length == 1 then

      .[0]

    else

      .[0]

      + {
          quantity:
            (
              map(.quantity)
              | add
            ),

          position_value:
            (
              map(.position_value)
              | add
            ),

          fifo_pnl_unrealized:
            (
              map(.fifo_pnl_unrealized)
              | add
            ),

          cost_basis_price:
            (
              (
                map(
                  .cost_basis_price
                  * .quantity
                )
                | add
              )
              /
              (
                map(.quantity)
                | add
              )
            ),

          open_price:
            (
              (
                map(
                  .open_price
                  * .quantity
                )
                | add
              )
              /
              (
                map(.quantity)
                | add
              )
            )
        }

    end

  )
;

#=======================================================================
def classify_bke:

  map(

    if .record_type == "lot"
    and (.fifo_pnl_unrealized >= -5)
    and (.fifo_pnl_unrealized <= 5)

    then

      .lock_state = "40.BKE"

    else

      .

    end

  )
;

#=======================================================================
def classify_los:

  map(

    if .record_type == "lot"
    and .lock_state == "---"
    and (.fifo_pnl_unrealized < -5)

    then

      .lock_state = "50.LOS"

    else

      .

    end

  )
;

#=======================================================================
def classify_hvt:

  map(

    if .record_type == "lot"
    and .lock_state == "---"
    and (.fifo_pnl_unrealized > 5)

    then

      .lock_state = "10.HVT"

    else

      .

    end

  )
;

#=======================================================================
def classify_lkd:

  group_by(.symbol)

  | map(

    . as $lots

    | reduce range(0; length) as $i
      (

        $lots;

        if .[$i].record_type == "lot"
        and (
          .[$i].lock_state == "10.HVT"
          or .[$i].lock_state == "40.BKE"
        )
        and any(
          .[$i + 1:][];
          .record_type == "lot"
          and .lock_state == "50.LOS"
        )

        then

          .[$i].lock_state = "30.LKD"

        else

          .

        end

      )

  )

  | add
;

#=======================================================================
def calculate_locking_lots_pnl:

  group_by(.symbol)

  | map(

    . as $lots

    | reduce range(0; length) as $i
      (

        $lots;

        if .[$i].record_type == "lot"
        and .[$i].lock_state == "30.LKD"

        then

          (
            .[$i + 1:]

            | map(
                select(
                  .record_type == "lot"
                  and .lock_state == "50.LOS"
                )
                | .fifo_pnl_unrealized
              )

            | if length > 0 then
                add
              else
                0
              end
          ) as $locking_lots_pnl

          | .[$i].locking_lots_pnl =
              $locking_lots_pnl

        else

          .

        end

      )

  )

  | add
;

#=======================================================================
def classify_pba:

  group_by(.symbol)

  | map(

    (
      map(
        select(
          .record_type == "lot"
          and .lock_state == "50.LOS"
        )
      )
    ) as $los

    | if ($los | length) == 0 then

        .

      else

        (
          $los
          | max_by(.cost_basis_price)
          | .cost_basis_price
        ) as $max_cost

        | map(

            if .record_type == "lot"
            and .lock_state == "50.LOS"
            and .cost_basis_price == $max_cost
            and .cost_basis_price >= .mark_price

            then

              .lock_state = "20.PBA"

            else

              .

            end

          )

      end

  )

  | add
;

#=======================================================================
def aggregate_hvt:

  . as $records

  | [
      $records[]

      | select(
          .record_type == "lot"
          and .lock_state == "10.HVT"
        )
    ]

  | group_by(.symbol)

  | map(

      sort_by(.open_datetime_raw)

      | . as $lots

      | $lots[0] as $oldest

      | $oldest

      | .record_type = "aggregate"

      | .lock_state = "15.HVT"

      | .quantity =
          (
            $lots
            | map(.quantity)
            | add
          )

      | .open_price =
          (
            $lots
            | map(.open_price)
            | max
          )

      | .cost_basis_price =
          (
            $lots
            | map(.cost_basis_price)
            | max
          )

      | .fifo_pnl_unrealized =
          (
            (
              $lots
              | map(.fifo_pnl_unrealized)
              | add
            )

            - 1.12
          )

    )

  | ($records + .)
;

#=======================================================================
def classify_locking:

  group_by(.symbol)

  | map(

    . as $lots

    | reduce range(0; length) as $i
    (

      $lots;

      if .[$i].record_type == "lot"
      and .[$i].lock_state == "30.LKD"

      then

        (
          .[$i + 1:]

          | map(
              select(
                .record_type == "lot"
                and .lock_state == "50.LOS"
              )
            )

          | last
        ) as $locker

        | if $locker then

            .[$i].locking_lot_id =
              $locker.lot_id

            | .[$i].lock_condition =
                "◆"
                + (
                    (
                      (
                        $locker.open_price
                        + 3 / $locker.quantity
                      )
                      | floor
                    )
                    | tostring
                  )
                + "x"
                + ($locker.quantity | tostring)
                + "▶"
                + ($locker.open_date | sub("^20"; ""))

          else

            .

          end

      else

        .

      end

    )

  )

  | add
;

#=======================================================================
def calculate_lot_age:

  . as $records

  | (now | strftime("%Y-%m-%d")) as $current_date

  | $records

  | map(

      if (
        .record_type == "lot"
        or .record_type == "aggregate"
      )

      then

        .lot_age = (
          (
            (
              (
                (
                  ($current_date + "T00:00:00Z" | fromdateiso8601)
                  -
                  (.open_date + "T00:00:00Z" | fromdateiso8601)
                )
                / 86400
              )
              # * (5 / 7)
              # * (1 - 12 / 365)
            )
            | ceil
          )
          | if . < 1 then 1 else . end
        )

      else

        .

      end

    )

;

#=======================================================================
def format_lot_age:

  map(
    if (
      .record_type == "lot"
      or .record_type == "aggregate"
      or .record_type == "summary"
    )
    and (.lot_age | type) == "number"

    then
      .lot_age = (.lot_age | human_duration)

    else
      .
    end
  )

;

#=======================================================================
def calculate_summary_lot_age: # test 28

  . as $records

  | map(

      if .record_type == "summary"

      then

        .symbol as $symbol

        | .lot_age = (
            $records
            | map(
                select(
                  .record_type == "lot"
                  and .symbol == $symbol
                )
                | .lot_age
              )
            | max
          )

      else

        .

      end

    )

;


#=======================================================================
def close_position($live):

  debug(">>> close_position() EXECUTING")
  | . as $records

  | $live
  | map({(.symbol): .position})
  | add as $positions

  | $records
  # | debug(
  #     ">>> LIVE POSITION MAP: "
  #     + ($positions | tojson)
  #   )

  | (map(.symbol) | unique) as $record_symbols
  | ($record_symbols
      | map(select(($positions[.] // 0) == 0))
    ) as $closed_symbols

  | debug(
      ">>> CLOSE CONFIRMED: "
      + ($closed_symbols | join(", "))
    )

  | map(
      select(
        ($positions[.symbol] // 0) != 0
      )
    ) as $remaining

  | debug(
      ">>> close_position() RECORDS: "
      + ($records | length | tostring)
      + " -> "
      + ($remaining | length | tostring)
    )

  | $remaining

;

#=======================================================================
def new_position($live):

  . as $records
  | ($records | map(.symbol) | unique) as $li_symbols

  | ($live
      | map(
          select(
            .position != 0
            and
            (.symbol as $s | ($li_symbols | index($s)) == null)
          )
        )
    ) as $new_positions

  | reduce $new_positions[] as $p
      ($records;

       make_derived_record($records[0]; $p; "summary") as $summary
       | make_derived_record($records[0]; $p; "lot") as $lot
       | . + [$summary, $lot]
      )
;

#=======================================================================
def transform_reversal_records($symbol; $p):

  map(
    if .symbol == $symbol then

      .quantity = $p.position
      | .mark_price = $p.mark_price
      | .open_price = $p.avg_cost
      | .cost_basis_price = $p.avg_cost
      | .side = (if $p.position > 0 then "Long" else "Short" end)
      # | .position_value = ($p.position * $p.mark_price)
      | .report_date = (now | strftime("%Y%m%d"))
      | .open_date = (now | strftime("%Y-%m-%d"))

    else
      .
    end
  )
;

#=======================================================================
def reverse_position($live):

  . as $records

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
            .position != 0
            and
            (.symbol as $s
             | ($li_positions[$s] // 0) != 0
             and
             (
               (($li_positions[$s] > 0) and (.position < 0))
               or
               (($li_positions[$s] < 0) and (.position > 0))
             )
            )
          )
        )
    ) as $reversals

  | reduce $reversals[] as $p
    ($records;
     retain_reversal_records($p.symbol)
     | transform_reversal_records($p.symbol; $p)
    )
;

#=======================================================================
def decrease_position($live):

  . as $records

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
             | ($li_positions[$s] // 0) > .position
            )
          )
        )
    ) as $decreases

  | reduce $decreases[] as $p
      ($records;

       ($li_positions[$p.symbol] - $p.position) as $decrease

       | reduce range((length - 1); -1; -1) as $i
           ({records: ., remaining: $decrease};

            if .remaining <= 0 then
              .

            elif .records[$i].symbol != $p.symbol
              or .records[$i].record_type != "lot"
              or .records[$i].quantity <= 0 then
              .

            else
              (.records[$i].quantity) as $qty

              | if $qty <= .remaining then
                  .records[$i].quantity = 0
                  | .remaining -= $qty
                else
                  .records[$i].quantity = $qty - .remaining
                  | .remaining = 0
                end
            end
           )

       | .records

       | map(
           select(
             .symbol != $p.symbol
             or .record_type != "lot"
             or .quantity != 0
           )
         )

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
#<disec>----------------------------------------------------------------
#...
#=======================================================================
# Pipeline
#=======================================================================
def pipeline($live):

  display_lots_canonically

  # | close_position($live)    # new stages
  # | new_position($live)      # new stages
  # | reverse_position($live)  # new stages
  # | increase_position($live) # new stages
  # | decrease_position($live) # new stages (LIFO)

  | update_mark_prices($live)

  | consolidate_lots
#...
#</disec>---------------------------------------------------------------
  | classify_bke
  | classify_los
  | classify_hvt

  | classify_lkd # f(HVT_i, LOS_i)
  | calculate_locking_lots_pnl # f(HVT_i, LOS_i)

  | classify_pba # f(LOS_i)

  | aggregate_hvt # f(HVT_i)

  | calculate_lot_age
  | calculate_summary_lot_age
  | format_lot_age

  # | classify_locking # optional --> legacy?
;

pipeline($live)
| .[]


#<disec>----------------------------------------------------------------
########################################################################
# OUTPUT:

#</disec>----------------------------------------------------------------
