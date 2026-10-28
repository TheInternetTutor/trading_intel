#!/usr/bin/env bash
# Append a caller-supplied suffix to every symbol in a CSV or JSONL file.
# Usage: ./append_symbol_suffix.sh FILE SUFFIX
# The input file is replaced atomically after validation; make a copy first.
set -euo pipefail

usage() {
    printf 'Usage: %s FILE SUFFIX\n' "${0##*/}" >&2
    printf 'Supported files: .csv, .jsonl\n' >&2
    printf 'Example: %s data/ibkr_lot_inventory.csv "~DBG"\n' "${0##*/}" >&2
    exit 2
}

[[ $# -eq 2 ]] || usage
input=$1
suffix=$2
[[ -f "$input" ]] || { printf 'Error: input file not found: %s\n' "$input" >&2; exit 1; }
[[ -n "$suffix" ]] || { printf 'Error: suffix must not be empty.\n' >&2; exit 2; }

case "${input,,}" in
    *.csv)   format=csv ;;
    *.jsonl) format=jsonl ;;
    *) printf 'Error: unsupported extension: %s (expected .csv or .jsonl)\n' "$input" >&2; exit 2 ;;
esac

command -v python3 >/dev/null 2>&1 || { printf 'Error: python3 is required.\n' >&2; exit 1; }

# Python's standard csv/json libraries handle quoted CSV fields and JSON escaping.
# Write to a temporary sibling, validate the result, then atomically replace input.
python3 - "$input" "$suffix" "$format" <<'PY'
import csv
import json
import os
import stat
import sys
import tempfile

path, suffix, fmt = sys.argv[1:]
folder = os.path.dirname(os.path.abspath(path))
mode = stat.S_IMODE(os.stat(path).st_mode)
fd, tmp = tempfile.mkstemp(prefix='.symbol-suffix-', suffix='.tmp', dir=folder, text=True)
os.close(fd)
changed = 0

try:
    if fmt == 'csv':
        with open(path, 'r', encoding='utf-8-sig', newline='') as src, \
             open(tmp, 'w', encoding='utf-8', newline='') as dst:
            reader = csv.reader(src)
            writer = csv.writer(dst, quoting=csv.QUOTE_ALL, lineterminator='\n')
            symbol_index = None
            for row in reader:
                if symbol_index is None:
                    # IBKR exports may have preamble records before the actual header.
                    normalized = [cell.strip().lstrip('\ufeff').lower() for cell in row]
                    if 'symbol' in normalized:
                        symbol_index = normalized.index('symbol')
                    writer.writerow(row)
                    continue
                if len(row) > symbol_index and row[symbol_index].strip():
                    row[symbol_index] = row[symbol_index] + suffix
                    changed += 1
                writer.writerow(row)
        if symbol_index is None:
            raise ValueError("could not find a CSV header containing a 'Symbol' column")
    else:
        with open(path, 'r', encoding='utf-8-sig') as src, \
             open(tmp, 'w', encoding='utf-8', newline='') as dst:
            for line_no, line in enumerate(src, 1):
                if not line.strip():
                    dst.write(line)
                    continue
                obj = json.loads(line)
                if not isinstance(obj, dict):
                    raise ValueError(f'JSONL line {line_no} is not a JSON object')
                if 'symbol' in obj and obj['symbol'] is not None and str(obj['symbol']) != '':
                    if not isinstance(obj['symbol'], str):
                        raise ValueError(f'JSONL line {line_no}: symbol is not a string')
                    obj['symbol'] += suffix
                    changed += 1
                dst.write(json.dumps(obj, ensure_ascii=False, separators=(',', ':')) + '\n')

    # Re-read output before replacing original.
    if fmt == 'csv':
        with open(tmp, 'r', encoding='utf-8', newline='') as check:
            list(csv.reader(check))
    else:
        with open(tmp, 'r', encoding='utf-8') as check:
            for line_no, line in enumerate(check, 1):
                if line.strip():
                    json.loads(line)

    os.chmod(tmp, mode)
    os.replace(tmp, path)
    print(f'Updated {changed} symbol value(s) in: {path}')
    print(f'Appended suffix: {suffix!r}')
except Exception as exc:
    try:
        os.unlink(tmp)
    except FileNotFoundError:
        pass
    print(f'Error: {exc}; original file was not replaced.', file=sys.stderr)
    sys.exit(1)
PY
