group_by(.symbol)

| map(

    . as $lots

    |

    reduce range(0; length) as $i (

      $lots;

      if .[$i].record_type == "lot"
      and .[$i].lock_state == "30.LKD"

      then

        (
          .[$i+1:]
          | map(
              select(
                .record_type == "lot"
                and .lock_state == "50.LOS"
              )
            )
          | last
        ) as $locker

        |

        if $locker then

          .[$i].locking_lot_id = $locker.lot_id

          |
          .[$i].lock_condition =
            "◆"
            + ((($locker.open_price + 3 / $locker.quantity) | floor) | tostring)
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
| .[]
