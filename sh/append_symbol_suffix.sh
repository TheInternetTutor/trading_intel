#!/usr/bin/env bash
# Append a suffix to the Symbol column of a CSV or the .symbol field of JSONL.
# Reads FILE, writes transformed content to stdout, and never modifies FILE.
# Usage: sh/append_symbol_suffix.sh FILE SUFFIX
set -euo pipefail

usage() {
    printf 'Usage: %s FILE SUFFIX\n' "${0##*/}" >&2
    printf 'Reads .csv or .jsonl; writes transformed content to stdout.\n' >&2
    printf 'Example: %s data/ibkr_lot_inventory.csv "~DBG" > data/ibkr_lot_inventory_debug.csv\n' "${0##*/}" >&2
    exit 2
}

[[ $# -eq 2 ]] || usage
input=$1
suffix=$2
[[ -f "$input" && -r "$input" ]] || { printf 'Error: input file is not readable: %s\n' "$input" >&2; exit 1; }
[[ -n "$suffix" ]] || { printf 'Error: suffix must not be empty.\n' >&2; exit 2; }

case "${input,,}" in
    *.jsonl)
        command -v jq >/dev/null 2>&1 || { printf 'Error: jq is required for JSONL input.\n' >&2; exit 1; }
        # Process one JSON value per line. Preserve records without a symbol field.
        jq -c --arg suffix "$suffix" '
            if type != "object" then error("each JSONL record must be an object")
            elif has("symbol") and .symbol != null and (.symbol | type) != "string"
                then error("symbol must be a string or null")
            elif (.symbol | type) == "string" then .symbol += $suffix
            else . end
        ' "$input"
        ;;
    *.csv)
        # CSV-aware AWK parser: tracks quoted fields, including commas and escaped quotes.
        # It preserves every untouched field's text and appends suffix only to Symbol values.
        LC_ALL=C awk -v suffix="$suffix" '
            function parse_csv(s, fields,    i,c,n,quoted,field) {
                delete fields; n=1; quoted=0; field=""
                for (i=1; i<=length(s); i++) {
                    c=substr(s,i,1)
                    if (c == "\"") {
                        field = field c
                        if (quoted && substr(s,i+1,1) == "\"") {
                            field = field "\""; i++
                        } else quoted = !quoted
                    } else if (c == "," && !quoted) {
                        fields[n++] = field; field=""
                    } else field = field c
                }
                fields[n] = field
                return n
            }
            function field_value(raw,    v) {
                v=raw
                if (substr(v,1,1)=="\"") {
                    v=substr(v,2,length(v)-2)
                    gsub(/""/, "\"", v)
                }
                return v
            }
            function quote_field(v) {
                gsub(/"/, """", v)
                return "\"" v "\""
            }
            {
                n=parse_csv($0, f)
                if (!header_found) {
                    for (i=1; i<=n; i++) {
                        name=tolower(field_value(f[i]))
                        gsub(/^\xef\xbb\xbf/, "", name)
                        if (name == "symbol") { symbol_col=i; header_found=1; break }
                    }
                    print $0
                    next
                }
                if (symbol_col <= n) {
                    value=field_value(f[symbol_col])
                    if (value != "") {
                        f[symbol_col]=quote_field(value suffix)
                        out=f[1]
                        for (i=2; i<=n; i++) out=out "," f[i]
                        print out
                        next
                    }
                }
                print $0
            }
            END {
                if (!header_found) {
                    print "Error: could not find a CSV header containing a Symbol column." > "/dev/stderr"
                    exit 2
                }
            }
        ' "$input"
        ;;
    *)
        printf 'Error: unsupported file extension: %s (expected .csv or .jsonl)\n' "$input" >&2
        exit 2
        ;;
esac
