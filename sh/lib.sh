
#!/bin/bash

# ======================================================================
# Shell Library

#-----------------------------------------------------------------------
function check_file_age() {
  local fl_output="${1:-./data/SOME_FILE.ext}";
  local tlength=${2:-$((24*60*60))}

  local -i now=0;
  local -i file_time=0;
  local -i tupdated=0;
  local -i uhours=0;
  local -i umints=0;
  local -i usecds=0;  
  local rebuild=0;
  local dir_data=${fl_output%/*};

  echo "## Checking [${fl_output}] ...";
  if [ -f "${fl_output}" ]; then {
    now=$(date +%s);
    file_time=$(stat -c %Y "${fl_output}");
    tupdated=$((file_time + tlength - now))
    if (( tupdated > 0 )); then
      uhours=$((tupdated/60/60 % 24))
      umints=$((tupdated/60 % 60))
      usecds=$((tupdated % 60))
      printf '### Update in %02d:%02d:%02d hours.\n' ${uhours} ${umints} ${usecds};
    else {
      echo "### Update Required!";
      rebuild=1;
    } fi
  } else {
    touch ${fl_output};
    echo "### Created!";
  } fi

  # touch ${fl_output};
  <<-'  #--variable-tracer-[*dbg*]'
  declare -p      \
  fl_output       \
  tlength         \
  file_time       \
  now             \
  tupdated        \
  uhours          \
  umints          \
  usecds          \
  rebuild         \
  ;
  #--variable-tracer-[*dbg*]

  return ${rebuild};
} > /dev/stderr

#-----------------------------------------------------------------------
# {check_refresh_period} owns refresh-state evaluation in the Bash
# library. When stale data is detected, it refreshes the dependency
# trigger and re-invokes the requested Make goals so that Make can
# reevaluate the dependency graph. This is intentional: the decision
# remains outside Make, while Make remains responsible for resource
# resolution and workflow execution.

# NOTE — EXTERNAL REFRESH / MAKE RE-ENTRY:
# This function intentionally crosses the normal Make/Bash orchestration
# boundary. It evaluates an external refresh period and, when the period
# has expired, updates the trigger resource and re-enters Make to execute
# the requested goal.
#
# Do not refactor this into a pure Boolean predicate without first
# redesigning the dependency mechanism. The Make re-entry is intentional:
# it allows the refresh decision to occur before Make evaluates the
# dependency-controlled acquisition target.
#
# This is an architectural exception, not accidental hidden orchestration.
function check_refresh_period() {
  local fl_tmp=${1:-/tmp/crp_260706065936.tmp};
  local tlength=${2:-$((24*60*60))};
  local makecmdgoals=${3:-classify_jsonl_fields};

  check_file_age ${fl_tmp} ${tlength};
  if [ ${?} -eq 1 ]; then {
    touch ${fl_tmp};
    make --silent ${makecmdgoals};
  } else {
    :;
  } fi

  # declare -p fl_tmp tlength makecmdgoals;

  return 0;
}

#-----------------------------------------------------------------------
# NOTE — SERVICE / TARGET SEPARATION:
# build_lots_data() is the Bash service that performs the actual Flex Query
# acquisition. The corresponding Make target is intentionally separate
# because Make controls when the Resource is eligible for reconstruction,
# while this function performs the acquisition operation itself.
#
# Do not merge the service implementation into the Make dependency rule.
function build_lots_data() {
  local fl_output="${1:-./data/ibkr_open_lots_raw.csv}";
  local fl_downloader="${2:-./sh/ibkr_download_flex_query.sh}";
  # local tlength=${3:-$((24*60*60))}
  local dir_data=${fl_output%/*};

  # check_file_age ${fl_output} ${tlength};
  # if [ ${?} == 1 ]; then {
    mkdir --parents ${dir_data};
    source ${fl_downloader} > ${fl_output};
  # } fi

  <<-'  #--variable-tracer-[*dbg*]'
  declare -p      \
  fl_output       \
  fl_downloader   \
  dir_data        \
  ;
  # tlength         \
  #--variable-tracer-[*dbg*]

  echo;
  return 0;
}

#-----------------------------------------------------------------------
function download_lots_data() { # **legacy**
  local fl_downloader="${1}";
  local fl_output="${2:-./data/ibkr_open_lots_raw.csv}";
  local tlength=${3:-$((24*60*60))};

  local -i now=0;
  local -i file_time=0;
  local -i tupdated=0;
  local -i uhours=0;
  local -i umints=0;
  local -i usecds=0;  
  local rebuild=true;
  local dir_data=${fl_output%/*};

  echo "## Checking [${fl_output}] ...";
  if [ -s "${fl_output}" ]; then {
    now=$(date +%s);
    file_time=$(stat -c %Y "${fl_output}");
    tupdated=$((file_time + tlength - now))
    if (( tupdated > 0 )); then
      uhours=$((tupdated/60/60 % 24))
      umints=$((tupdated/60 % 60))
      usecds=$((tupdated % 60))
      printf '### Update in %02d:%02d:%02d hours.\n' ${uhours} ${umints} ${usecds};
      rebuild=false;
    fi
  } fi

  if [ "${rebuild}" == "true" ]; then {
    echo "### Updating ...";
    mkdir --parents ${dir_data};
    ${fl_downloader} > ${fl_output};
  } fi

  # touch ${fl_output};
  # <<-'  #--variable-tracer-[*dbg*]'
  declare -p      \
  fl_downloader   \
  fl_output       \
  tlength         \
  file_time       \
  now             \
  tupdated        \
  uhours          \
  umints          \
  usecds          \
  rebuild         \
  ;
  #--variable-tracer-[*dbg*]
  
  return 0;
} > /dev/stderr

#-----------------------------------------------------------------------
function normalize_lot_inventory()
{
  local fl_output="${1:-./data/ibkr_open_lots_raw.csv}";
  local fl_script=${2:-./sh/ibkr_lots_normalize.awk};
  local tlength=${3:-$((24*60*60))}

  # check_file_age ${fl_output} ${tlength};
  # if [ ${?} == 1 ]; then {
    # echo "##  010 Normalizing: ${fl_output}" > /dev/stderr;
    # cat <<-''  #--eof'
    grep --invert-match         \
    -e '^"BOF"'                 \
    -e '^"BOA"'                 \
    -e '^"BOS"'                 \
    -e '^"EOS"'                 \
    -e '^"EOA"'                 \
    -e '^"EOF"'                 \
    "${fl_output}"              \
    | awk -f ${fl_script}       \
    ;
    #--eof
  # } fi
  # declare -p fl_script fl_output;
  return 0;
}

#-----------------------------------------------------------------------
# NOTE — GENERIC SCRIPT DISPATCH:
# run_script_on_source() is intentionally a generic service dispatcher.
# Its responsibility is to select the appropriate execution engine from
# the source script's extension (AWK, SQL, or jq).
#
# Keep this generic mechanism in the shared shell library; pipeline-specific
# processing belongs in the corresponding pipeline module.
function run_script_on_source()
{
  local fl_script=${1};
  local fl_source=${2};

  local dir_script=${fl_script%/*};
  local ext_script=${fl_script##*.};
  local prompt=$(date +'%m/%d/%H:%M:%S-%a$');

  # echo -e sqlite3 -table ${fl_source} '\\\n<' ${fl_script};
  # sqlite3 -table ${fl_source} < ${fl_script};
  if [ ${ext_script} == awk ]; then {
    echo -e "${prompt} awk -f ${fl_script} ${fl_source}";
    awk -f ${fl_script} ${fl_source};
  }
  elif [ ${ext_script} == sql ]; then {
    echo -e "sqlite3 -table ${fl_source} \n< ${fl_script}";
    sqlite3 -table ${fl_db} < ${fl_sql};
  }
  elif [ ${ext_script} == jq ]; then {
    echo -e "${prompt} jq --raw-output --slurp --from-file ${fl_script} ${fl_source}";
    jq --raw-output --slurp --from-file ${fl_script} ${fl_source};
  } else {
    echo "***EXTENSION NOT IMPLEMENTED: ${ext_script}";
  } fi

  # declare -p fl_script dir_script ext_script fl_source;

  return 0;
}

#-----------------------------------------------------------------------
function copy_view_lots()
{
  local fl_source=${1};
  local fl_copy=${2};

  local fl_copy_dt='';
  local date_time='';
  local fl_sample_data=${fl_source%\.*}_sample.${fl_source##*.};
  local dir_source='';

  # echo "## Creating stable copy for rederer application:";
  if [ -s ${fl_source} ]; then {
    dir_source=${fl_source%/*};
    fl_name=${fl_copy##*/};

    date_time=$(date +"%y%m%d_%H%M%S");       
    fl_name=${fl_name/_lots/_lots_${date_time}};
    # fl_copy_dt=${fl_copy/_lots/_lots_${date_time}};
    fl_copy_dt=${dir_source}/jsonl/${fl_name};
    cp --force ${fl_source} ${fl_copy};
    # cp --force ${fl_source} ${fl_copy_dt};
    jq . ${fl_source} > ${fl_copy_dt};
    head --lines=30 ${fl_source} > ${fl_sample_data};
    # declare -p dir_source fl_name fl_copy_dt;
  } fi
  return 0;
}

#-----------------------------------------------------------------------
function toggle_debug()
{
  local fl_csv=${1};
  local fl_pi=${2};
  local fl_view=${3};
  local fl_csv_stable="${fl_csv}.stable";
  local fl_view_stable="${fl_view}.stable";

  # Filter a stable source by exact quoted symbols from the live positions.
  # The CSV's column-header row is retained; JSONL records are independent.
  function filter_debug_file()
  {
    local fl_source=${1};
    local fl_target=${2};
    local fl_tmp="${fl_target}.tmp.$$";
    local symbol='';

    : > "${fl_tmp}" || return 1;

    if [[ "${fl_source}" == *.csv ]]; then
      grep -F '"Symbol"' "${fl_source}" > "${fl_tmp}" || true;
    fi

    while IFS= read -r symbol; do
      [[ -n "${symbol}" ]] || continue;
      grep -F -- "\"${symbol}\"" "${fl_source}" >> "${fl_tmp}" || true;
    done < <(jq -r '.symbol // empty' "${fl_pi}")

    mv --force "${fl_tmp}" "${fl_target}"
  }

  if [[ -f "${fl_csv_stable}" && -f "${fl_view_stable}" ]]; then
    # Both stable originals exist: restore both files and leave debug mode.
    mv --force "${fl_csv_stable}" "${fl_csv}" || return 1;
    mv --force "${fl_view_stable}" "${fl_view}" || return 1;
    echo "Debug mode OFF: ${fl_csv}, ${fl_view}";

  elif [[ -f "${fl_csv_stable}" && ! -f "${fl_view_stable}" ]]; then
    # Recover the legacy state where CSV debugging was already active.
    cp --preserve=mode,timestamps "${fl_view}" "${fl_view_stable}" || return 1;
    filter_debug_file "${fl_view_stable}" "${fl_view}" || return 1;
    echo "Debug mode ON (viewer added): ${fl_view}";

  elif [[ ! -f "${fl_csv_stable}" && ! -f "${fl_view_stable}" ]]; then
    # Save both originals before filtering either working file.
    cp --preserve=mode,timestamps "${fl_csv}" "${fl_csv_stable}" || return 1;
    cp --preserve=mode,timestamps "${fl_view}" "${fl_view_stable}" || return 1;
    filter_debug_file "${fl_csv_stable}" "${fl_csv}" || return 1;
    filter_debug_file "${fl_view_stable}" "${fl_view}" || return 1;
    echo "Debug mode ON: ${fl_csv}, ${fl_view}";

  else
    echo "ERROR: inconsistent debug state; refusing to overwrite stable data." >&2;
    echo "  CSV stable: ${fl_csv_stable}" >&2;
    echo "  Viewer stable: ${fl_view_stable}" >&2;
    return 1;
  fi;

  echo "Done: toggle_debug";
  return 0;
}

#-----------------------------------------------------------------------
# declare -F;
