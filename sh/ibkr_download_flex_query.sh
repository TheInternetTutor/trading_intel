#!/bin/bash

<<-'#--documentation'
# DOCUMENTATION:
https://www.interactivebrokers.com/campus/ibkr-api-page/flex-web-service/

## Error CodesCopy Location
The following is a consolidated list of error codes returnable by the
/SendRequest and /GetStatement endpoints when a server-side failure
occurs.

## ErrorCode ErrorMessage
1001  Statement could not be generated at this time. Please try again shortly.
1003  Statement is not available.
1004  Statement is incomplete at this time. Please try again shortly.
1005  Settlement data is not ready at this time. Please try again shortly.
1006  FIFO P/L data is not ready at this time. Please try again shortly.
1007  MTM P/L data is not ready at this time. Please try again shortly.
1008  MTM and FIFO P/L data is not ready at this time. Please try again shortly.
1009  The server is under heavy load. Statement could not be generated at this time. Please try again shortly.
1010  Legacy Flex Queries are no longer supported. Please convert over to Activity Flex.
1011  Service account is inactive.
1012  Token has expired.
1013  IP restriction.
1014  Query is invalid.
1015  Token is invalid.
1016  Account in invalid.
1017  Reference code is invalid.
1018  Too many requests have been made from this token. Please try again shortly. Limited to one request per second, 10 requests per minute (per token).
1019  Statement generation in progress. Please try again shortly.
1020  Invalid request or unable to validate request.
1021  Statement could not be retrieved at this time. Please try again shortly.
#--documentation

#-----------------------------------------------------------------------
function ibkr_flexqry_send_request()
{
  local query_id=${1:-1312314}; # ibkr_02_10_open_position_lots
  local token=${2:-132885608548754265284548}; # Exp(27/09/17@13:31 EDT)
  
  local https0="https://ndcdyn.interactivebrokers.com/AccountManagement/FlexWebService";
  local https1="${https0}/SendRequest?t=${token}&q=${query_id}&v=3";
  local return_code=0;
  
  curl -s ${https1} | grep --only-matching --perl-regexp '<ReferenceCode>\K[^<]+';
  return_code=${?};
  if [ ${return_code} -gt 0 ]; then {
    echo "*** INVALID QUERY ID: [${query_id}]";
    echo "    AND/OR";
    echo "*** INVALID TOKEN   : [${token}]";
  } fi > /dev/stderr;

  return ${return_code};
}

#-----------------------------------------------------------------------
function ibkr_flexqry_get_statement()
{
  local reference=${1:-3724224086}; # ibkr_02_10_open_position_lots
  local token=${2:-132885608548754265284548}; # Exp(27/09/17@13:31 EDT)

  local https0="https://ndcdyn.interactivebrokers.com/AccountManagement/FlexWebService";
  https2="${https0}/GetStatement?t=${token}&q=${reference}&v=3";
  local return_code=0;
   
  curl ${https2} \
  ;
  # | tee flex_report.psv \
  # | nl \
  # | head --lines=20 \
  return_code=${?};
  
  if [ ${return_code} -gt 0 ]; then {
    echo "*** INVALID REFERENCE ID: [${reference}]";
    echo "    AND/OR";
    echo "*** INVALID TOKEN       : [${token}]";
  } fi > /dev/stderr;

  return ${return_code};
}

#-----------------------------------------------------------------------

cat <<-'#--ibkr-query-id' > /dev/stderr
TOKEN                               : 132885608548754265284548
--- Expiration(27/09/17@13:31 EDT)

           Flex Query                  QID
----------------------------------  ----------
ibkr_02_10_open_position_lots       : 1312314
ibkr_01_06_change_dividend_accruals : 1330397
ibkr_01_10_commission_details       : 1330745
ibkr_01_02_borrow_fees_details      : 1330761
ibkr_02_20_trades                   : 739627
ibkr_02_22_trades                   : 1330755

$ REF=$(ibkr_flexqry_send_request [${QID}] [${TOKEN}]);
$ ibkr_flexqry_get_statement ${REF} [${TOKEN}];
#--ibkr-query-id

TOKEN=132885608548754265284548;
QID=1330397 ; # ibkr_01_06_change_dividend_accruals
QID=1330745 ; # ibkr_01_10_commission_details
QID=1330761 ; # ibkr_01_02_borrow_fees_details
QID=739627  ; # ibkr_02_20_trades
QID=1330755 ; # ibkr_02_22_trades
QID=1312314 ; # ibkr_02_10_open_position_lots

#-----------------------------------------------------------------------
<<-'#--variables-tracing'
declare https0="https://ndcdyn.interactivebrokers.com/AccountManagement/FlexWebService";
declare https1="${https0}/SendRequest?t=${TOKEN}&q=${QID}&v=3";
declare https2="";
echo -e '\e[33m';
echo -e "\nVariables tracing:"
declare -p TOKEN QID REF https0 https1 https2 | cut -c12- \
| sed -e 's/"https.*Service/{https0}/g' \
;
echo -e '\e[m';
#--variables-tracing

#-----------------------------------------------------------------------
# <<-'#--execution-output'
REF=$(ibkr_flexqry_send_request ${QID} ${TOKEN});
ibkr_flexqry_get_statement ${REF} ${TOKEN};
#--execution-output

alias ib.dfq='source /finanzas/ibkr/bash/shexe/ibkr_download_flex_query.sh ';
