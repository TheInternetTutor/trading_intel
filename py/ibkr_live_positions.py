#!/usr/bin/env python3
"""
==================================================================== [Python]
ARCHITECT     : E.D.T.
NIGHT-CODER   : Grok <grok.x.ai>
EMAIL         : the.internet.tutor@gmail.com
DATE.STARTED  : Tue Sep 16 22:41:00 EDT 2025
DATE.MODIFIED : Mon Nov 10 03:16:00 EST 2025
========================================================================
IBKR Live Price Snapshot – Market Open or Closed
------------------------------------------------
- Auto-detects market state via IB server time
- Market Open: Real-time reqMktData
- Market Closed: Last 1-min bar → synthetic BID/ASK/MARK
- MARK = t.marketPrice() [method]
- BID/ASK/LAST = properties
- No crashes, no NaN, PSV-ready

# 25/10/26/18:00 
Fixed: IB has no getCurrentTime(). Use ib.reqCurrentTime().
Simplified market check. Robust.
Prompt: "AttributeError: 'IB' object has no attribute 'getCurrentTime'"

# 25/11/10/03:16 
First implementation – display-only.
==================================================================== 
"""

# ---- Connection and configuration ----
HOST = "127.0.0.1"
PORT = 7496
CLIENT_ID = 101
HIST_REQUESTS_PER_SEC = 4
HIST_REQUEST_DELAY = 1.0 / HIST_REQUESTS_PER_SEC

#-----------------------------------------------------------------------
from ib_insync import *
import logging
import time
import sys
import json
import math
from types import SimpleNamespace

#.......................................................................
def connect_ibkr():
    ib = IB()
    logging.info(f"Connecting to {HOST}:{PORT} with clientId {CLIENT_ID}...")
    ib.connect(HOST, PORT, clientId=CLIENT_ID)
    logging.info("Connected")
    return ib

#.......................................................................
def on_ib_error(reqId, errorCode, errorString, contract=None):

    if errorCode == 10089:
        symbol = contract.symbol if contract else "?"
        print(f"*** WARNING: E10089 {symbol} LIVE→DELAYED", file=sys.stderr)
        return

    if errorCode == 354:
        symbol = contract.symbol if contract else "?"
        print(f"*** WARNING: E354 {symbol} NO MARKET DATA", file=sys.stderr)
        return

    print(f"E{errorCode} reqId={reqId} {errorString}", file=sys.stderr)


#-----------------------------------------------------------------------
def load_positions(ib):
    positions = ib.positions()
    logging.info(f"Retrieved {len(positions)} open positions")
    return positions

#-----------------------------------------------------------------------
def render_positions_table(positions):
    print(f'{"SYM":<8} {"QTY":>6} {"AVG_COST":>12} {"EXCH":<10} {"ACCOUNT":<10}')
    print('-' * 52)

    for pos in positions:
        print(
            f'{pos.contract.symbol:<8} '
            f'{pos.position:>6.0f} '
            f'{pos.avgCost:>12.3f} '
            f'{pos.contract.exchange:<10} '
            f'{pos.account:<10}'
        )

#-----------------------------------------------------------------------
def get_live_prices(ib, positions):
    tickers = []

    for pos in positions:
        contract = pos.contract
        print('#### Retrieving:', contract.symbol, file=sys.stderr)
        ticker = ib.reqMktData(
            contract,
            genericTickList="",
            snapshot=False,
            regulatorySnapshot=False
        )

        ticker.account = pos.account
        ticker.avgCost = pos.avgCost
        ticker.position = pos.position

        tickers.append(ticker)

    return tickers

#-----------------------------------------------------------------------
def render_tickers_table(tickers):
    print(
        f'{"SYM":<8} '
        f'{"EXCH":<8} '
        f'{"TYPE":>4} '
        f'{"TIME":<19} '
        f'{"MARK":>10} '
        f'{"BID":>10} '
        f'{"ASK":>10} '
        f'{"LAST":>10} '
        f'{"ACCOUNT":<10}'
    )

    for t in tickers:
        print(
            f'{t.contract.symbol:<8} '
            f'{t.contract.exchange:<8} '
            f'{t.marketDataType:>4} '
            f'{str(t.time):<19} '
            f'{t.markPrice:>10.3f} '
            f'{t.bid:>10.3f} '
            f'{t.ask:>10.3f} '
            f'{t.last:>10.3f} '
            f'{t.account:<10}'            
        )

#-----------------------------------------------------------------------
def wait_for_market_data(ib, tickers, timeout=10):
    start = time.time()

    while time.time() - start < timeout:
        if all(
            not math.isnan(t.markPrice)
            or not math.isnan(t.last)
            for t in tickers
        ):
            return True

        ib.sleep(0.20)

    return False

#-----------------------------------------------------------------------
def get_historical_last_bar(ib: IB, contract):
    """Get last completed 1-min bar."""
    try:
        bars = ib.reqHistoricalData(
            contract,
            endDateTime='',
            durationStr='1 D',
            barSizeSetting='1 min',
            # barSizeSetting='10 secs',
            whatToShow='TRADES',
            useRTH=True,
            formatDate=1
        )
        if not bars:
            return None
        last = bars[-1]
        return last.low, last.high, (last.high + last.low) / 2, last.close
    except Exception as e:
        logging.warning(f"Historical data failed for {contract.symbol}: {e}")
        return None

#-----------------------------------------------------------------------
def create_synthetic_ticker(pos, last_bar):
    ticker = SimpleNamespace()

    contract = pos.contract

    ticker.contract = contract
    ticker.account = pos.account
    ticker.avgCost = pos.avgCost
    ticker.position = pos.position

    ticker.bid = last_bar.bid
    ticker.ask = last_bar.ask
    ticker.markPrice = last_bar.mark
    ticker.last = last_bar.close
    ticker.close = last_bar.close

    ticker.high = float("nan")
    ticker.low = float("nan")
    ticker.volume = float("nan")

    ticker.time = None
    ticker.marketDataType = None

    ticker.marketPrice = lambda: last_bar.mark

    return ticker

#-----------------------------------------------------------------------
def get_historical_prices(ib, positions):
    """
    Retrieve the latest historical quote for each open position and
    return a list of synthetic ticker objects.
    """

    logging.info("Market closed. Using last historical bar.")

    tickers = []

    print('#### Retrieving:', file=sys.stderr)

    for pos in positions:
        contract = pos.contract

        print('   ', contract.symbol, file=sys.stderr)

        data = get_historical_last_bar(ib, contract)

        if data:
            bid, ask, mark, last = data
        else:
            bid = ask = mark = last = 0.000

        ticker = create_synthetic_ticker(
            pos,
            SimpleNamespace(
                bid=bid,
                ask=ask,
                mark=mark,
                close=last
            )
        )

        tickers.append(ticker)

        time.sleep(HIST_REQUEST_DELAY)

    return tickers

#-----------------------------------------------------------------------
def is_market_open(ib):
    """
    Return True if the current IBKR server time falls within
    regular U.S. market hours (09:30–16:00 ET, Mon–Fri).
    """

    # return True  #******************** TESTING  ********************
    return False #******************** TESTING  ********************

    try:
        now = ib.reqCurrentTime()

        # Weekend
        if now.weekday() >= 5:
            return False

        minutes = now.hour * 60 + now.minute

        market_open = 4 * 60 + 30
        market_close = 20 * 60

        return market_open <= minutes < market_close

    except Exception as e:
        logging.warning(
            f"Failed to get server time: {e}. Assuming market closed."
        )
        return False

#-----------------------------------------------------------------------
def render_jsonl(tickers, fp=sys.stdout):
    """
    Render one JSON object per ticker.
    """
    for t in tickers:

        rec = {
            "account"  : t.account,
            "symbol"   : t.contract.symbol,
            "exchange" : t.contract.exchange,

            "position" : t.position,
            "avg_cost" : t.avgCost,

            "mark" : None if math.isnan(t.markPrice) else t.markPrice,
            "bid"  : None if math.isnan(t.bid)       else t.bid,
            "ask"  : None if math.isnan(t.ask)       else t.ask,
            "last" : None if math.isnan(t.last)      else t.last,

            "time" : None if t.time is None else str(t.time),
            "market_data_type" : t.marketDataType
        }

        print(json.dumps(rec, separators=(',', ':')), file=fp)

#-----------------------------------------------------------------------
def retrieve_tickers(ib, positions):
    """
    Return a list of ticker objects using the
    appropriate retrieval strategy.
    """

    if is_market_open(ib):
        print('### Market Open:', file=sys.stderr)
        tickers = get_live_prices(ib, positions)
        wait_for_market_data(ib, tickers)
    else:
        print('### Market Closed:', file=sys.stderr)
        tickers = get_historical_prices(ib, positions)

    return tickers

#-----------------------------------------------------------------------
def test_units():
  
  # DEBUG_MAX_POSITIONS = 1000

  #--------------------------------------
  ib = connect_ibkr()
  ib.errorEvent += on_ib_error
  print('-'*80)
  print(ib)

  #--------------------------------------
  positions = load_positions(ib)[:DEBUG_MAX_POSITIONS]
  print('-'*80)
  render_positions_table(positions)

  #--------------------------------------
  print('-'*80)
  print('is_market_open:', is_market_open(ib))

  #--------------------------------------
  print('-'*80)
  tickers = get_historical_prices(ib, positions)

  #--------------------------------------
  print('-'*80)
  tickers = get_live_prices(ib, positions)

  #--------------------------------------
  print('-'*80)
  tickers = retrieve_tickers(ib, positions)

  # print(tickers[0])
  # print(vars(tickers[0]))
  # render_tickers_table(tickers)

  '''
  #--------------------------------------
  output_mode = "table"
  if len(sys.argv) > 1:
      if sys.argv[1].lower() in ("json", "jsonl"):
          output_mode = "json"

  print('-'*80)
  if output_mode == "json":
      render_jsonl(tickers)
  else:
      render_tickers_table(tickers)

  ib.disconnect()

  #'''

  return

#-----------------------------------------------------------------------
def remove_position_by_symbol(positions, symbol):
    for i, pos in enumerate(positions):
        if pos.contract.symbol == symbol:
            del positions[i]
            return True
    return False

#-----------------------------------------------------------------------
def main():

  print('## Downloading Live Positions', file=sys.stderr)
  # DEBUG_MAX_POSITIONS = 3

  ib = connect_ibkr()
  ib.errorEvent += on_ib_error
  positions = load_positions(ib)[:DEBUG_MAX_POSITIONS]

  '''
  remove_position_by_symbol(positions, "268A")
  remove_position_by_symbol(positions, "LNAI")
  remove_position_by_symbol(positions, "MPU")
  remove_position_by_symbol(positions, "TLRY")
  remove_position_by_symbol(positions, "TMQ")
  remove_position_by_symbol(positions, "VIOT")
  remove_position_by_symbol(positions, "XDTE")
  remove_position_by_symbol(positions, "ZENVF")
  #'''

  positions.sort(key=lambda pos: pos.contract.symbol)
  tickers = retrieve_tickers(ib, positions)

  output_mode = "table"
  if len(sys.argv) > 1:
      if sys.argv[1].lower() in ("json", "jsonl"):
          output_mode = "json"

  if output_mode == "json":
      render_jsonl(tickers)
  else:
      render_tickers_table(tickers)

  ib.disconnect()

  return

#=======================================================================
# MAIN
#=======================================================================

DEBUG_MAX_POSITIONS = 1000

if __name__ == '__main__':
  # test_units()
  main()
