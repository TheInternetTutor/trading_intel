
if .record_type == "lot"
and .lock_state == "---"
and (.fifo_pnl_unrealized > 10)
then
  .lock_state = "10.HVT"
else
  .
end
