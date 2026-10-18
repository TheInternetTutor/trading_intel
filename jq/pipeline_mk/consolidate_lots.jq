
group_by([
  .symbol,
  .open_datetime_raw,
  .originating_transaction_id,
  .originating_order_id
])

| map(

    if length == 1 then .[0]

    else

      .[0] + {

        quantity:
          (map(.quantity) | add),

        position_value:
          (map(.position_value) | add),

        fifo_pnl_unrealized:
          (map(.fifo_pnl_unrealized) | add),

        cost_basis_price:
          (
            (map(.cost_basis_price * .quantity) | add)
            /
            (map(.quantity) | add)
          ),

        open_price:
          (
            (map(.open_price * .quantity) | add)
            /
            (map(.quantity) | add)
          )

      }

    end

)

| .[]
