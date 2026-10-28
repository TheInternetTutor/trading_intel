#!/bin/bash
#================================================================ [Bash]
# ARCHITECT     : Emilio J. Nemura
# NIGHT CODER   : Sage Ai. ChatGPTA
# EMAIL         : the.internet.tutor@gmail.com
# DATE.STARTED  : Sat Jun 20 17:01:11 EDT 2026
# DATE.MODIFIED : Thu Jun 25 17:01:11 EDT 2026
#=======================================================================
# Build printf() format strings from a schema.
#
# Input:
#   $1 : ref_labels
#   $2 : ref_hdr
#   $3 : ref_rcd
#   $4 : ref_jq
#   $5 : schema (At some point to become optional external file)
#
# Output:
#   ${LABELS}
#   ${fmt_hdr}
#   ${fmt_rcd}
#   ${jq_filter}
##############################################################################

#-----------------------------------------------------------------------
cat <<-'#--documentation'
VIEW LOTS — command/function reference
======================================

Core viewer
-----------
vl              : render the current lots dataset.
vl.sym <symbol> : show all lots for a symbol.
vl.ls           : list unique symbols.

Lot-state reports
-----------------
vl.hvt          : report harvestable (10.HVT) lots.
vl.lkd          : report locked (30.LKD) lots.
vl.bke          : report break-even (40.BKE) lots.
vl.pnl          : report the remaining profitable/P&L lots.
vl.hvti         : expand HVT symbols into their complete inventories.

IBKR
----
vl.ib           : generate the IBKR lot-symbol import file.

Reports
-------
vl.rpt          : generate the terminal lots report.
vl.rptf         : generate the lots report file.
vl.up           : execute the complete lots update/report workflow.
#--documentation

<<-'#--documentation'
Implementation
--------------
render_lots_view          : JSONL → jq → AWK → terminal PSV stream.
generate_lot_state_report : common engine for lot-state reports.
write_ib_lot_symbols      : generate IBKR symbols for a lot state.
generate_ibkr_lot_import  : build the IBKR import file.
generate_lots_report      : assemble the terminal report.
generate_lots_report_file : generate the persistent report.
update_lots_view          : orchestrate the complete update workflow.

Refactoring status
------------------
Completed:
  • consolidated repeated lot-state reports
  • removed eval-based input verification
  • consolidated duplicated IBKR symbol generation
  • converted implementation-heavy aliases into functions
  • clarified viewer/report/orchestration responsibilities
  • optimized HVT inventory expansion
  • established descriptive implementation names with vl.* aliases

Deferred:
  • jq-based filtering/selection
  • AWK-based calculations/aggregation
  • further optimization of repeated data scans
  • possible elimination/reduction of get_formats()
  • future terminal presentation enhancements
  • eventual web/one-page application frontend

Principle:
  Refactor and optimize the current Bash implementation first;
  redesign the processing architecture only after its behavior and 
  responsibilities are stable.
#--documentation

#-----------------------------------------------------------------------
function get_formats()
{
    local -n ref_labels="${1}";
    local -n ref_hdr="${2}";
    local -n ref_rcd="${3}";
    local -n ref_jq="${4}";
    local schema="${5}";
    local delimiter='|';

    ref_labels='';
    ref_hdr='';
    ref_rcd='';
    ref_jq='[';

    local title field type width prec
    while IFS='|' read -r title field type width prec
    do
        # strip spaces
        # title=${title// /};
        field=${field// /};
        type=${type// /};
        width=${width// /};
        prec=${prec// /};

        title=${title//\"/};
        ref_labels+="${title} ";

        ref_hdr+="%-${width}s${delimiter}"

        case "${type}" in

            s)
                ref_rcd+="%-${width}s${delimiter}"
                ;;

            d)
                ref_rcd+="%${width}d${delimiter}"
                ;;

            f)
                ref_rcd+="%${width}.${prec}f${delimiter}"
                ;;

            *)
                ref_rcd+="%s${delimiter}"
                ;;

        esac

        ref_jq+=".${field}, "

    done <<< "${schema}"

    ref_labels=${ref_labels}-SPC-;
    ref_labels=${ref_labels/ -SPC-/};
    ref_hdr+=$'\n'
    ref_rcd+=$'\n'
    ref_jq+=']| @tsv'
    ref_jq=${ref_jq/', ]|'/'] |'}

    return 0
}

#-----------------------------------------------------------------------
# Note to AI: next function should be implemented in {jq}
function vl.fieldx()
{
    local symbol="${1:?*** MISSING SYMBOL! ***}";
    local field="${2:?*** MISSING FIELD NUMBER! ***}";
    local factor="${3:?*** MISSING FACTOR! ***}";

    awk -F'|' -v OFS='|' \
        -v sym="${symbol}" \
        -v fld="${field}" \
        -v fac="${factor}" '
    BEGIN {
        all = (sym == "*" || sym == "." || sym == "")
    }

    {
        if (all || $1 == sym) {
            $fld = sprintf("%10.3f", $fld * fac)
        }
        print
    }'
}

#-----------------------------------------------------------------------
function require_input_data()
{
  if [ ! -f "${FLI_DATA_VL}" ]; then
    echo "***NOT FOUND: ${FLI_DATA_VL}";
    return 1;
  fi

  return 0;
}

#-----------------------------------------------------------------------
function render_lots_view()
{
  require_input_data || return 1;

  local awk_render='
  BEGIN {
      FS = "\t"
  }

  {
    printf fmt_rcd,                    \
    $1,  $2,  $3,  $4,  $5,            \
    $6,  $7,  $8,  $9,  $10,           \
    $11, $12, $13, $14, $15,           \
    $16, $17, $18, $19, $20,           \
    $21, $22, $23, $24, $25,           \
    $26, $27, $28, $29, $30,           \
    $31, $32, $33, $34, $35,           \
    $36, $37, $38, $39, $40,           \
    $41, $42, $43, $44, $45,           \
    $46, $47, $48, $49, $50
  }
  ';

  jq --raw-output                \
     "${jq_filter}"              \
     "${FLI_DATA_VL}"            \
  | awk                          \
    -F $"\t"                     \
    -v fmt_rcd="${fmt_rcd}"      \
    "${awk_render}"              \
  | vl.fieldx 268A.T 4 0.0062    \
  ;
  # |   head -n24                  \

  return 0;
}
alias vl=render_lots_view;

#-----------------------------------------------------------------------
# assume field is already sorted
# print new line if field > than value_i
function group_by_pnl()
{
  local value_i=${1:-'-5000 -1000 -500 -200 -100 -50 -20 -10 10 20 50 100 500 1000 5000'};
  local field=${2:-1};
  local separator=${3:-'|'};
  return 0;
}

#-----------------------------------------------------------------------
function group_by_month()
{
  local date_column=${1:-9};
  awk -v date_column=${date_column} -F'|' '
  NR == 1 {
    print
    next
  }

  {
    date = $date_column
    split(date, d, "-")
    month = d[2]

    if (previous_month != "" && month != previous_month)
      print ""

    print # date "[" month "][" previous_month "]";
    previous_month = month
  }
  ';
  return 0;
}

#-----------------------------------------------------------------------
function generate_lot_state_report()
{
  require_input_data || return 1;

  local report_label="${1:?*** MISSING REPORT LABEL! ***}";
  local cols=${2:-${FIELDS}};
  local sort_key="${3:?*** MISSING SORT KEY! ***}";
  shift 3;

  local table=$(
  {
    printf "${fmt_hdr}" ${LABELS};
    render_lots_view                             \
    | grep "$@"                                  \
    | sort                                       \
      --field-separator='|'                      \
      --key=${sort_key}                          \
    ;
  }                                              \
  );

  echo "${table}"                                \
  | cut --delimiter='|' --fields=${cols}         \
  | nl --number-width=4;

  local total=$(
    echo "${table}"                              \
    | grep --invert-match -e OPEN_DATE           \
    | cut --delimiter='|' --fields=4             \
    | awk "${awk_total}"                         \
    ;
  );

  printf '%-18s: $%10.3f\n' "${report_label}" ${total};

  return 0;
}
alias vl.glsr="generate_lot_state_report '## Report' 1- ${sort_by_sym} -e '.*'";

#-----------------------------------------------------------------------
function report_harvestable_lots()
{
  generate_lot_state_report            \
  '## 10.HVT'                          \
  1,3,4,6,7,8                          \
  "${sort_by_sym}"                     \
  -e '10.HVT'                          \
  ;
  echo;
  generate_lot_state_report            \
  '## 15.HVT'                          \
  1,3,4,6,7,8                          \
  "${sort_by_pnl}"                     \
  -e '15.HVT'                          \
  ;
  return ${?};
}
alias vl.hvt=report_harvestable_lots

#-----------------------------------------------------------------------
function report_locked_lots()
{
  generate_lot_state_report            \
  '## 30.LKD'                          \
  1,3,4,6,7,8,5                        \
  "${sort_by_pnl}"                     \
  -e '30.LKD'                          \
  ;
  return ${?};
}
alias vl.lkd=report_locked_lots

#-----------------------------------------------------------------------
function report_lossing_lots()
{
  # FIELDS=1,3,4,6,8,9,10;
  generate_lot_state_report            \
  '## P&L'                             \
  1,3,4,6,7,8                          \
  "${sort_by_pnl}"                     \
  --invert-match                       \
  -e '05.SMR'                          \
  -e '40.BKE'                          \
  -e '30.LKD'                          \
  -e '10.HVT'                          \
  -e '15.HVT'                          \
  ;
  return ${?};
}
alias vl.pnl=report_lossing_lots

#-----------------------------------------------------------------------
function report_breakeven_lots()
{
  generate_lot_state_report            \
  '## 40.BKE'                          \
  1,3,4,6,7,8                          \
  "${sort_by_pnl}"                     \
  -e '40.BKE'                          \
  ;
  return ${?};
}
alias vl.bke=report_breakeven_lots;

#-----------------------------------------------------------------------
function show_lots_by_symbol()
{
  require_input_data || return 1;

  local -u symbol=${1:-'$'};
  # read -p "Symbol: " symbol;
  {
    printf "${fmt_hdr}" ${LABELS};
    render_lots_view                   \
    | sort                             \
    --field-separator='|'              \
    --key=${sort_by_dts}               \
    | grep -e "^${symbol}[ |]"         \
    | grep --invert-match -e '15.HVT'  \
    ;
  }                                    \
  | nl --number-width=4                \
  | cut --delimiter='|' --fields=1-    \
  | group_by_month 9                   \
  ;
  # | cat -n \
  return 0;
}
alias vl.sym=show_lots_by_symbol;

#-----------------------------------------------------------------------
function list_lot_symbols()
{
  require_input_data || return 1;

  echo "## List of symbols:"
  render_lots_view \
  | cut --delimiter='|' --fields=1 \
  | sort \
  | uniq \
  | awk '
  { 
    printf "%-8s", $1; 
    if (NR % 10 == 0) print "";
  }
  END {
    print "";
  }
  ' \
  | nl --number-width=4 \
  ;
  echo;

  return 0;
}
alias vl.ls=list_lot_symbols;

#-----------------------------------------------------------------------
function show_harvestable_inventory()
{
  require_input_data || return 1;

  local fl_view_lots=$(mktemp);

  render_lots_view > "${fl_view_lots}" || {
    rm -f "${fl_view_lots}";
    return 1;
  }

  while read -r sym; do
    {
      printf "${fmt_hdr}" ${LABELS};
      grep -e "^${sym}[ |]" "${fl_view_lots}"    \
      | sort                                     \
      --field-separator='|'                      \
      --key=${sort_by_dts}                       \
      | grep --invert-match --regexp='15.HVT'    \
    ;
    }                                            \
    | cut --delimiter='|' --fields=1-6,8         \
    | nl --number-width=4;

    echo -e "<==\n\n";

  done < <(
    grep --regexp='10.HVT' "${fl_view_lots}"     \
    | cut --delimiter='|' --fields=1             \
    | sort                                       \
    | uniq
  );

  rm -f "${fl_view_lots}";

  return 0;
}
alias vl.hvti=show_harvestable_inventory;

#-----------------------------------------------------------------------
function write_ib_lot_symbols()
{
  local state=${1:-HVT}
  render_lots_view                     \
  | grep ${state}                      \
  | cut -d "|" -f1                     \
  | sort                               \
  | uniq                               \
  | tr -d " "                          \
  | ib.lsd                             \
  ;
  return 0;
}

#-----------------------------------------------------------------------
function generate_ibkr_lot_import()
{
  require_input_data || return 1;

  local fl_ib_import=/cygdrive/c/Jts/import.csv;

  write_ib_lot_symbols HVT > ${fl_ib_import};  
  echo >> ${fl_ib_import};
  write_ib_lot_symbols BKE >> ${fl_ib_import};  
    
  cat ${fl_ib_import};

  return 0;
}
alias vl.ib=generate_ibkr_lot_import;

#-----------------------------------------------------------------------
# calling this function within another will show global and local 
# variables. If a variable is out of scope, that is fine.
function declare_p()
{
  declare -p                           \
  DIR_GPARENT_VL                       \
  LABELS                               \
  fmt_hdr                              \
  fmt_rcd                              \
  jq_filter                            \
  schema                               \
  awk_render                           \
  2> /dev/null                         \
  ;
  return 0;
}

#-----------------------------------------------------------------------
function generate_lots_report()
{
  require_input_data || return 1;
  echo "# IBKR Lots Report $(date +'%y/%m/%d/%H:%M:%S')";
  echo;
  list_lot_symbols;
  report_lossing_lots;
  echo;
  report_locked_lots;
  echo;
  report_breakeven_lots;
  echo;
  report_harvestable_lots;
  echo;
  return 0;
}
alias vl.rpt=generate_lots_report;

#-----------------------------------------------------------------------
function generate_lots_report_file()
{
  require_input_data || return 1;

  local fl_out=/ibkr/data/ibkr_view_lots_report.psv;
  time {
    echo "## Report: ${fl_out}";
    show_harvestable_inventory > "${fl_out}";
    generate_lots_report >> "${fl_out}";
  }

  return 0;
}
alias vl.rptf=generate_lots_report_file

#-----------------------------------------------------------------------
function update_lots_view()
{
  # why the next two lines seems not work?
  # make update; 
  # make fetch_lot_inventory fetch_position_inventory process_lot_inventory;

  # make -q;
  # echo "0: ${?}";
  make fetch_lot_inventory;
  # echo "1: ${?}"; # return code is 0
  make fetch_position_inventory;
  # echo "2: ${?}"; # return code is 0
  make process_lot_inventory;
  # echo "3: ${?}"; # return code is 0

  # [ ${?} ] && \
  # or you may use elapsed time to determine conditional execution
  generate_ibkr_lot_import > /dev/null;
  generate_lots_report; 
  generate_lots_report_file;

  return 0;
}
alias vl.up=update_lots_view;

#-----------------------------------------------------------------------
alias vl.upt='{
  generate_ibkr_lot_import > /dev/null; 
  generate_lots_report; 
  generate_lots_report_file;
}';

#=======================================================================
# MAIN
#=======================================================================

declare this_path=${PWD}/${BASH_SOURCE[0]}
DIR_GPARENT_VL=${this_path%/sh/*};

# FLI_DATA_VL=${1:-${DIR_GPARENT_VL}/data/ibkr_open_lots_consolidated}
# FLI_DATA_VL=${1:-${DIR_GPARENT_VL}/data/ibkr_open_lots_40bke.jsonl}
# FLI_DATA_VL=${1:-${DIR_GPARENT_VL}/data/ibkr_open_lots_50los.jsonl}
# FLI_DATA_VL=${1:-${DIR_GPARENT_VL}/data/ibkr_open_lots.jsonl}
FLI_DATA_VL=${1:-${DIR_GPARENT_VL}/data/view_lots.jsonl}
# FLI_DATA_VL=${FLI_DATA_VL}x;

declare LABELS='';
declare fmt_hdr='';
declare fmt_rcd='';
declare jq_filter='';
declare schema='';

<<-'#--keys-[*dbg*]'
$ head --lines=1 ${FLI_DATA_VL} | jq -r 'keys[]' | tokcol 30 3 > $dcb;
account_alias                 account_id                    accrued_interest
asset_class                   conid                         cost_basis_price
currency                      description                   fifo_pnl_unrealized
holding_date                  holding_datetime_raw          holding_time
last_dummy                    listing_exchange              lock_condition
lock_state                    locking_lot_id                locking_lots_pnl
lot_age                       lot_icons                     lot_id
mark_price                    multiplier                    open_date
open_datetime_raw             open_price                    open_time
originating_order_id          originating_transaction_id    position_value
quantity                      record_type                   report_date
serial_number                 side                          symbol
#--keys-[*dbg*]
schema=$(cat <<-'EOF'
SYM        | symbol               | s   | 7    |---
STATE      | lock_state           | s   | 6    |---
QTY        | quantity             | d   | 5    |---
PNL        | fifo_pnl_unrealized  | f   | 11   |3
LCK_LOSS   | locking_lots_pnl     | f   | 10   |3
AGE        | lot_age              | s   | 8    |---
MARK       | mark_price           | f   | 10   |3
COST       | cost_basis_price     | f   | 9    |3
OPEN_DATE  | open_date            | s   | 10   |---
TIME       | open_time            | s   | 8    |---
EOF
)
# LOCK       | lock_condition       | s   | 16   |---
# MARK       | lot_id               | s   | 15   |---
# LOCK_ID    | locking_lot_id       | s   | 11   |---
# LOT_ID     | lot_id               | s   | 11   |---

declare sort_by_sym=1.1;
declare sort_by_stt=2.1;
declare sort_by_pnl=4.1;
declare sort_by_age=6.1;
declare sort_by_dts=9.1;
declare FIELDS=1,3,4,6,8,9,10;
declare columns_lkd=${FIELDS},5;

declare awk_total='
BEGIN {total = 0;}
{
  total += $1;
} 
END {
  print total;
}
';

get_formats LABELS fmt_hdr fmt_rcd jq_filter "${schema}"
# printf "${fmt_hdr}" ${LABELS};

# Export ...
# declare -fx get_formats;
# declare -fx vl.fieldx;
# declare -fx require_input_data;
# declare -fx render_lots_view;
# declare -fx group_by_pnl;
# declare -fx group_by_month;
# declare -fx generate_lot_state_report;
# declare -fx report_harvestable_lots;
# declare -fx report_locked_lots;
# declare -fx report_lossing_lots;
# declare -fx report_breakeven_lots;
# declare -fx show_lots_by_symbol;
# declare -fx list_lot_symbols;
# declare -fx show_harvestable_inventory;
# declare -fx write_ib_lot_symbols;
# declare -fx generate_ibkr_lot_import;
# declare -fx declare_p;
# declare -fx generate_lots_report;
# declare -fx generate_lots_report_file;
# declare -fx update_lots_view;
