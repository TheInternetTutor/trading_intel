
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
  local fl_output="${1:-./data/ibkr_lot_inventory.csv}";
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
  local fl_output="${2:-./data/ibkr_lot_inventory.csv}";
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
  local fl_output="${1:-./data/ibkr_lot_inventory.csv}";
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
  local fl_target="${1:-}";
  local fl_test="${fl_target}.test";
  local fl_temp;

  if [ -z "${fl_target}" ]; then
    echo "WARNING: toggle_debug requires one file path." >&2;
    return 1;
  fi;

  if [ ! -f "${fl_target}" ]; then
    echo "WARNING: Target file does not exist: ${fl_target}" >&2;
    return 1;
  fi;

  if [ ! -f "${fl_test}" ]; then
    echo "WARNING: Test version does not exist: ${fl_test}. No files were changed." >&2;
    return 1;
  fi;

  if [ -f "./data/testing_environment" ]; then
    echo "# Switching ${fl_target} from test to production ...";
  else
    echo "# Switching ${fl_target} from production to test ...";
  fi;

  fl_temp="${fl_target}.toggle_debug_tmp.$$";
  if ! mv -- "${fl_target}" "${fl_temp}"; then
    echo "WARNING: Could not stage target file: ${fl_target}" >&2;
    return 1;
  fi;
  if ! mv -- "${fl_test}" "${fl_target}"; then
    mv -- "${fl_temp}" "${fl_target}";
    echo "WARNING: Could not install test version: ${fl_test}. Original target restored." >&2;
    return 1;
  fi;
  if ! mv -- "${fl_temp}" "${fl_test}"; then
    mv -- "${fl_target}" "${fl_test}";
    mv -- "${fl_temp}" "${fl_target}";
    echo "WARNING: Could not complete file swap. Original files restored where possible." >&2;
    return 1;
  fi;

  echo "Done: toggle_debug (${fl_target})";
  return 0;
}

#-----------------------------------------------------------------------
function toggle_debug_environment()
{
  local fl_flag="./data/testing_environment";

  if [ -f "${fl_flag}" ]; then
    rm -- "${fl_flag}" || return 1;
    echo "# Environment: production";
  else
    echo -e "Use:\n   $ make td\nto swith back to production mode."  \
    > "${fl_flag}"                                                   \
    || return 1;
    echo "# Environment: test";
  fi;

  return 0;
}

#-----------------------------------------------------------------------
# Apply the fixed incoming Git bundle to this repository's root.
# Source files are copied from the bundle commit, and its message is used
# for a local commit. The bundle's synthetic ancestry is not merged.
function apply_bundle() {
  local dir_root dir_extract fl_bundle fl_hash fl_hash_marker old_hash
  local fl_message tmp_message commit_id fl_file rel_file
  old_hash=''

  dir_root=$(git rev-parse --show-toplevel) || return 1
  fl_bundle="${dir_root}/update.bundle"
  fl_hash_marker="${dir_root}/.update.bundle.sha256"

  if [[ ! -f "${fl_bundle}" ]]; then
    echo "abtt: bundle not found: ${fl_bundle}" >&2
    return 1
  fi

  fl_hash=$(sha256sum "${fl_bundle}") || return 1
  fl_hash=${fl_hash%% *}
  if [[ -f "${fl_hash_marker}" ]]; then
    read -r old_hash < "${fl_hash_marker}"
  fi
  if [[ "${fl_hash}" == "${old_hash}" ]]; then
    echo "abtt: bundle already applied (${fl_hash:0:12}); nothing to do."
    return 0
  fi

  if ! git -C "${dir_root}" diff --cached --quiet; then
    echo "abtt: staged changes exist; commit or unstage them before applying the bundle." >&2
    return 1
  fi

  if ! git -C "${dir_root}" bundle verify "${fl_bundle}" >/dev/null; then
    echo "abtt: bundle verification failed." >&2
    return 1
  fi
  if ! git -C "${dir_root}" fetch --quiet "${fl_bundle}" HEAD; then
    echo "abtt: could not import bundle commit." >&2
    return 1
  fi
  commit_id=$(git -C "${dir_root}" rev-parse 'FETCH_HEAD^{commit}') || return 1
  fl_message=$(git -C "${dir_root}" show -s --format=%B "${commit_id}") || return 1
  if [[ -z "${fl_message//[[:space:]]/}" ]]; then
    fl_message='Apply incoming source bundle'
  fi

  dir_extract=$(mktemp -d "${dir_root}/.bundle_extract.XXXXXX") || return 1
  if ! git -C "${dir_root}" archive "${commit_id}" | tar -x -C "${dir_extract}"; then
    rm -rf -- "${dir_extract}"
    echo "abtt: could not expand bundle commit." >&2
    return 1
  fi

  # Copy the files supplied by the bundle into the project root.
  while IFS= read -r -d '' fl_file; do
    rel_file=${fl_file#"${dir_extract}/"}
    mkdir -p "${dir_root}/$(dirname -- "${rel_file}")" || {
      rm -rf -- "${dir_extract}"
      return 1
    }
    cp -p -- "${fl_file}" "${dir_root}/${rel_file}" || {
      rm -rf -- "${dir_extract}"
      return 1
    }
    git -C "${dir_root}" add -- "${rel_file}" || {
      rm -rf -- "${dir_extract}"
      return 1
    }
  done < <(find "${dir_extract}" -type f -print0)
  rm -rf -- "${dir_extract}"

  if ! git -C "${dir_root}" diff --cached --quiet; then
    tmp_message=$(mktemp) || return 1
    printf '%s\n' "${fl_message}" > "${tmp_message}"
    if ! git -C "${dir_root}" commit --file="${tmp_message}"; then
      rm -f -- "${tmp_message}"
      echo "abtt: commit failed; bundle marker was not updated." >&2
      return 1
    fi
    rm -f -- "${tmp_message}"
  else
    echo "abtt: source files already match this bundle; no new commit needed."
  fi

  printf '%s\n' "${fl_hash}" > "${fl_hash_marker}.tmp" || return 1
  mv -f -- "${fl_hash_marker}.tmp" "${fl_hash_marker}" || return 1
  echo "abtt: applied ${commit_id:0:12}; project sources updated."
}

#-----------------------------------------------------------------------
function test_pipeline()
{
  local flag=${1};
  if [ -f "${flag}" ]; then { 
    make plinu > /dev/null;
    render_lots_view | sort;
  } else {
  {
    echo "!!! Current mode: production! Execute:";
    echo "  $ make toggle_debug # td";
    echo "to switch environment to debugging mode";
  } > /dev/stderr;
  } fi
  return 0;
}

#-----------------------------------------------------------------------
function create_git_bundle()
{
  local bundle='update.bundle'
  local base='056b2aa4d60d5be5be9c5d40bc3e8da0eab83f79'

  echo "# Creating Git bundle ..."
  test -n "${base}" || {
    echo "ERROR: Bundle base commit is not set." >&2
    return 1
  }
  git cat-file -e "${base}^{commit}" || {
    echo "ERROR: Bundle base commit not found: ${base}" >&2
    return 1
  }
  git merge-base --is-ancestor "${base}" HEAD || {
    echo "ERROR: Bundle base commit is not an ancestor of HEAD." >&2
    return 1
  }
  git bundle create "${bundle}" HEAD "^${base}" || {
    echo "ERROR: Git bundle creation failed." >&2
    return 1
  }
  git bundle verify "${bundle}" || {
    echo "ERROR: Git bundle verification failed." >&2
    return 1
  }
  echo "# Bundle created and verified: ${bundle}"
}

#-----------------------------------------------------------------------
# declare -F;
