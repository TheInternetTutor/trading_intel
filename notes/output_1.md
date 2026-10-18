# Added but missing "05.SMR"
DK  12:28:40    BOT 3 78.00 MRGN  1.00
MDB 09:54:41    BOT 1 385.00  MRGN  1.00

# Changes not accounted for
NVDA  05:01:10    SLD 2 221.24  MRGN  1.01
NVDA  07:00:17    BOT 5 220.60  MRGN  1.00

# Not added
AMD 05:02:00    BOT 3 550.00  MRGN  1.00
TQQQ  12:23:32    BOT 10  71.00 MRGN  1.00
WMT 15:58:12    BOT 5 106.70  MRGN  1.00

WMT 2026-04-29, 17:58:42  5 127.3000  -636.50 -1.00 637.50  0.00  O
WMT 2026-09-18, 15:58:12  5 106.7000  -533.50 -1.00 534.50  0.00  O
Total WMT 10    -1,170.00 -2.00 1,172.00  0.00   

# Closed but still appearing
ALGM  11:56:06    SLD 10  33.79 MRGN  1.01
HPE 10:51:10    SLD 10  60.4035 MRGN  1.01

---

10/17/23:38:07-Sat$ for_command ()
{
    local command=${1:-'echo ${TK}'};
    local IFS=${2:-'
'};
    cat - | for TK in $(cat);
    do
        {
            eval ${command}
        };
    done
}

10/17/23:38:07-Sat$ {
  echo AMD TQQQ WMT \
  | for_command 'cat data/ibkr_live_positions.jsonl | grep ${TK}' \
  | jq -c . | cut -c1-110;
  echo;
  echo AMD TQQQ WMT \
  | for_command 'cat data/ibkr_open_lots.jsonl | grep ${TK}' \
  | jq -c . | cut -c1-110 | grep -v '15.HVT';
}

{"account":"U8546916","symbol":"AMD","exchange":"NASDAQ","position":28.0,"avg_cost":426.6667896,"mark":559.5,"
{"account":"U8546916","symbol":"TQQQ","exchange":"NASDAQ","position":15.0,"avg_cost":69.800002,"mark":72.655,"
{"account":"U8546916","symbol":"WMT","exchange":"NASDAQ","position":10.0,"avg_cost":117.2000015,"mark":106.715
{"symbol":"AMD","lock_state":"05.SMR","quantity":25,"mark_price":559.5,"open_price":411.826803,"fifo_pnl_unrea
{"symbol":"AMD","lock_state":"10.HVT","quantity":5,"mark_price":559.5,"open_price":359.200003,"fifo_pnl_unreal
{"symbol":"AMD","lock_state":"10.HVT","quantity":5,"mark_price":559.5,"open_price":353.200003,"fifo_pnl_unreal
{"symbol":"AMD","lock_state":"10.HVT","quantity":5,"mark_price":559.5,"open_price":382.500003,"fifo_pnl_unreal
{"symbol":"AMD","lock_state":"10.HVT","quantity":2,"mark_price":559.5,"open_price":448.515003,"fifo_pnl_unreal
{"symbol":"AMD","lock_state":"10.HVT","quantity":1,"mark_price":559.5,"open_price":445.480003,"fifo_pnl_unreal
{"symbol":"AMD","lock_state":"10.HVT","quantity":2,"mark_price":559.5,"open_price":520.500003,"fifo_pnl_unreal
{"symbol":"AMD","lock_state":"10.HVT","quantity":1,"mark_price":559.5,"open_price":493.160003,"fifo_pnl_unreal
{"symbol":"AMD","lock_state":"10.HVT","quantity":4,"mark_price":559.5,"open_price":486.125003,"fifo_pnl_unreal
{"symbol":"TQQQ","lock_state":"05.SMR","quantity":5,"mark_price":72.655,"open_price":67.200003,"fifo_pnl_unrea
{"symbol":"TQQQ","lock_state":"10.HVT","quantity":5,"mark_price":72.655,"open_price":67.200003,"fifo_pnl_unrea
{"symbol":"WMT","lock_state":"05.SMR","quantity":10.0,"mark_price":106.715,"open_price":127.5,"fifo_pnl_unreal
{"symbol":"WMT","lock_state":"20.PBA","quantity":5,"mark_price":106.715,"open_price":127.5,"fifo_pnl_unrealize
{"symbol":"WMT","lock_state":"50.LOS","quantity":5,"mark_price":106.715,"open_price":117.2000015,"fifo_pnl_unr
09/20/12:29:07-Sun$



09/20/12:55:34-Sun$ jq -c . data/jsonl/view_lots_260917_180727.jsonl | grep WMT | cut -c1-110
{"symbol":"WMT","lock_state":"05.SMR","quantity":5,"mark_price":106.78999999999999,"open_price":127.5,"fifo_pn
{"symbol":"WMT","lock_state":"20.PBA","quantity":5,"mark_price":106.78999999999999,"open_price":127.5,"fifo_pn
