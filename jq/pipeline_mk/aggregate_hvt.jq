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
    | .lock_state  = "15.HVT"

    | .quantity =
        ($lots | map(.quantity) | add)

    | .open_price =
        ($lots | map(.open_price) | max)

    | .cost_basis_price =
        ($lots | map(.cost_basis_price) | max)

    | .fifo_pnl_unrealized =
        (
            ($lots | map(.fifo_pnl_unrealized) | add)
            - 1.12
        )
  )

| ($records + .)[]
