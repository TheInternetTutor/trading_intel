
if .record_type == "lot"
and (.fifo_pnl_unrealized >= -10)
and (.fifo_pnl_unrealized <= 10)
then
  .lock_state = "40.BKE"
else
  .
end
