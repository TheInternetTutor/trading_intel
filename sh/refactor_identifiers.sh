#!/usr/bin/env bash

#-----------------------------------------------------------------------
function usage()
{
cat <<EOF

Usage:

    $SCRIPT_NAME [options] rename_map.csv file...

Options

    --dry-run
    --backup
    --verbose
    --summary
    --help

EOF
}

#-----------------------------------------------------------------------
function error()
{
    printf '%s: %s\n' "$SCRIPT_NAME" "$*" >&2
    exit 1
}

#-----------------------------------------------------------------------
function validate_csv()
{
    [[ -f "$CSV_FILE" ]] \
        || error "CSV file not found: $CSV_FILE"

    [[ -r "$CSV_FILE" ]] \
        || error "CSV file is not readable: $CSV_FILE"
}

#-----------------------------------------------------------------------
function validate_files()
{
    local f

    for f in "${FILES[@]}"
    do
        [[ -f "$f" ]] \
            || error "Input file not found: $f"

        [[ -r "$f" ]] \
            || error "Input file is not readable: $f"

        [[ -w "$f" ]] \
            || error "Input file is not writable: $f"
    done
}

#-----------------------------------------------------------------------
function create_backup()
{
    local file="$1"

    (( BACKUP )) || return 0

    cp -p "$file" "$file.bak"
}

#-----------------------------------------------------------------------
function parse_arguments()
{
    while (($#))
    do
        case "$1" in

            --dry-run)
                DRY_RUN=1
                ;;

            --backup)
                BACKUP=1
                ;;

            --verbose)
                VERBOSE=1
                ;;

            --summary)
                SUMMARY=1
                ;;

            --help|-h)
                usage
                exit 0
                ;;

            --*)
                error "Unknown option: $1"
                ;;

            *)
                if [[ -z "$CSV_FILE" ]]
                then
                    CSV_FILE="$1"
                else
                    FILES+=("$1")
                fi
                ;;
        esac

        shift
    done

    [[ -n "$CSV_FILE" ]] \
        || error "Missing rename_map.csv"

    ((${#FILES[@]} > 0)) \
        || error "No input files specified"
}

#-----------------------------------------------------------------------
function process_file()
{
    local input="$1"

    TEMP_FILE="$(mktemp)";
    
    awk \
        -f "$AWK_ENGINE" \
        -v csv="$CSV_FILE" \
        -v verbose="$VERBOSE" \
        "$input" > "$TEMP_FILE"

    ((FILES_PROCESSED++))

    if cmp -s "$input" "$TEMP_FILE"
    then
        rm -f "$TEMP_FILE"
        ((FILES_UNCHANGED++))
        ((VERBOSE)) && printf "UNCHANGED  %s\n" "$input"
        return
    fi

    ((FILES_MODIFIED++))
    if ((DRY_RUN))
    then
        rm -f "$TEMP_FILE"
        ((VERBOSE)) && printf "WOULD MODIFY  %s\n" "$input"
        return
    fi

    create_backup "$input"
    mv "$TEMP_FILE" "$input"
    ((VERBOSE)) && printf "MODIFIED   %s\n" "$input"
}

#-----------------------------------------------------------------------
function print_summary()
{
    local end_time
    local elapsed

    end_time=$(date +%s)
    elapsed=$((end_time - START_TIME))

    printf "\n"

    printf "Files processed : %d\n" "$FILES_PROCESSED"
    printf "Modified        : %d\n" "$FILES_MODIFIED"
    printf "Unchanged       : %d\n" "$FILES_UNCHANGED"

    if (( TOTAL_REPLACEMENTS > 0 ))
    then
        printf "Replacements    : %d\n" "$TOTAL_REPLACEMENTS"
    fi

    printf "Elapsed time    : %ds\n" "$elapsed"
}

#-----------------------------------------------------------------------
function cleanup()
{
    [[ -n "${TEMP_FILE:-}" && -f "$TEMP_FILE" ]] && rm -f "$TEMP_FILE"
}

trap cleanup EXIT INT TERM

#-----------------------------------------------------------------------
function validate_engine()
{
    [[ -f "$AWK_ENGINE" ]] \
        || error "AWK engine not found: $AWK_ENGINE"

    [[ -r "$AWK_ENGINE" ]] \
        || error "Cannot read AWK engine: $AWK_ENGINE"
}

#-----------------------------------------------------------------------
function main()
{
    parse_arguments "$@"
    validate_csv
    validate_engine
    validate_files
    for file in "${FILES[@]}"
    do
        process_file "$file"
    done
    print_summary
}

#=======================================================================
# MAIN
#=======================================================================
# set -euo pipefail

SCRIPT_DIR=${PWD}/${BASH_SOURCE[0]};
SCRIPT_DIR=${SCRIPT_DIR%/*};
AWK_ENGINE=${SCRIPT_DIR}/refactor_identifiers.awk;
SCRIPT_NAME=${BASH_SOURCE[0]##*/};


DRY_RUN=0
BACKUP=0
VERBOSE=0
SUMMARY=0

CSV_FILE=""

FILES=()

FILES_PROCESSED=0
FILES_MODIFIED=0
FILES_UNCHANGED=0
TOTAL_REPLACEMENTS=0

START_TIME=$(date +%s)

main "$@"

<<-'#--var-tracer'
declare -p \
SCRIPT_DIR \
AWK_ENGINE \
SCRIPT_NAME \
DRY_RUN \
BACKUP \
VERBOSE \
SUMMARY \
CSV_FILE \
FILES \
FILES_PROCESSED \
FILES_MODIFIED \
FILES_UNCHANGED \
TOTAL_REPLACEMENTS \
START_TIME \
;
#--var-tracer

