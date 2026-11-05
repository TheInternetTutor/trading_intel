
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

    |

    if ($los | length) == 0
    then
      .
    else

      (
        $los
        | max_by(.cost_basis_price)
        | .cost_basis_price
      ) as $max_cost

      |

      map(

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
| .[]
