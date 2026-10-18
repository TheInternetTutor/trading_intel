
group_by(.symbol)

| map(

    . as $lots

    |

    reduce range(0; length) as $i (

      $lots;

      if .[$i].record_type == "lot"
      and .[$i].lock_state == "10.HVT"

      and

      (
        any(
          .[$i+1:][];

          .record_type == "lot"
          and .lock_state == "50.LOS"
        )
      )

      then

        .[$i].lock_state = "30.LKD"

      else

        .

      end

    )

)

| add
| .[]
