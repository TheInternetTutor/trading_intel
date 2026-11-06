
#!/bin/bash

# ======================================================================
# Shell Library

#-----------------------------------------------------------------------
zip_repository() {
    local project_dir archive_name tmp_root tmp_project tmp_tar
    local tmp_zip tmp_dir

    # Project name = current directory name
    project_dir="$(basename "$PWD")"
    archive_name="${project_dir}.zip"

    # Determine operating system temporary directory
    tmp_root="${TMP:-${TEMP:-${TMPDIR:-/tmp}}}"

    # Create isolated temporary workspace
    tmp_dir="$(mktemp -d "${tmp_root%/}/${project_dir}.XXXXXX")" || return 1

    tmp_project="$tmp_dir/$project_dir"
    tmp_tar="$tmp_dir/$project_dir.tar"
    tmp_zip="$PWD/.${archive_name}.tmp"

    # Always clean up temporary files
    trap 'rm -rf -- "$tmp_dir"; rm -f -- "$tmp_zip"' RETURN

    mkdir -p "$tmp_project" || return 1

    echo "# Creating file manifests..."

    git ls-files -z > "$tmp_dir/files.manifest" || return 1
    find .git \( -type f -o -type l \) -print0 \
        > "$tmp_dir/git.manifest" || return 1

    echo "# Assembling project archive..."

    tar --null -cf "$tmp_tar" \
        -C "$PWD" \
        -T "$tmp_dir/files.manifest" \
        -T "$tmp_dir/git.manifest" || return 1

    tar -xf "$tmp_tar" -C "$tmp_project" || return 1

    echo "# Creating ZIP archive..."

    (
        cd "$tmp_dir" &&
        zip -qr "$tmp_zip" "$project_dir/"
    ) || return 1

    mv -f -- "$tmp_zip" "$PWD/$archive_name" || return 1

    echo "# Archive created: $PWD/$archive_name"

    return 0;
}


#-----------------------------------------------------------------------
# Normalize tracked files with the requested extension to Unix LF endings.
# Usage: normalize_line_endings <extension>
normalize_line_endings() {
    local extension file file_list processed=0 failures=0

    if (( $# != 1 )); then
        printf 'Usage: normalize_line_endings <extension>\n' >&2
        return 2
    fi

    extension=${1#.}
    if [[ -z "$extension" || "$extension" == */* || "$extension" == *[![:alnum:]_-]* ]]; then
        printf 'Invalid file extension: %s\n' "$1" >&2
        return 2
    fi

    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
        printf 'Error: current directory is not inside a Git working tree.\n' >&2
        return 1
    }

    file_list=$(mktemp) || return 1
    if ! git ls-files -z > "$file_list"; then
        rm -f -- "$file_list"
        printf 'Error: unable to enumerate tracked files.\n' >&2
        return 1
    fi

    while IFS= read -r -d '' file; do
        [[ "$file" == *."$extension" ]] || continue

        if [[ ! -f "$file" || -L "$file" ]]; then
            printf 'Skipping unavailable or symbolic-link file: %q\n' "$file" >&2
            failures=1
            continue
        fi

        if perl -pi -e 's/\r\n/\n/g' -- "$file"; then
            printf 'Processed: %q\n' "$file"
            ((processed += 1))
        else
            printf 'Error normalizing: %q\n' "$file" >&2
            failures=1
        fi
    done < "$file_list"

    rm -f -- "$file_list"
    printf 'Processed %d tracked .%s file(s).\n' "$processed" "$extension"
    return "$failures"
}

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
function toggle_debug_v01()
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
function toggle_debug()
{
  local fl_target="${1:-}";
  local fl_test="${fl_target}.test";
  local fl_production="${fl_target}.production";

  if [ -z "${fl_target}" ]; then
    echo "WARNING: toggle_debug requires one file path." >&2;
    return 1;
  fi;

  # The backup extension, not the testing_environment flag, determines
  # which direction this file transitions.
  if [ -f "${fl_production}" ]; then
    echo "# Restoring production data: ${fl_target}";
    if ! mv -f -- "${fl_production}" "${fl_target}"; then
      echo "WARNING: Could not restore production file: ${fl_production}" >&2;
      return 1;
    fi;
  else
    if [ ! -f "${fl_target}" ]; then
      echo "WARNING: Production source file does not exist: ${fl_target}" >&2;
      return 1;
    fi;

    if [ ! -f "${fl_test}" ]; then
      echo "WARNING: Test source file does not exist: ${fl_test}. No files were changed." >&2;
      return 1;
    fi;

    echo "# Installing test data: ${fl_target}";
    if ! mv -- "${fl_target}" "${fl_production}"; then
      echo "WARNING: Could not preserve production file: ${fl_target}" >&2;
      return 1;
    fi;

    if ! cp -- "${fl_test}" "${fl_target}"; then
      rm -f -- "${fl_target}";
      if ! mv -- "${fl_production}" "${fl_target}"; then
        echo "ERROR: Test installation failed and production restoration also failed: ${fl_production}" >&2;
      else
        echo "WARNING: Test installation failed. Production data was restored." >&2;
      fi
      return 1;
    fi;
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
# Apply only the incoming bundle's changes since the common Git ancestor.
# Preserve local-only paths and incoming rename sources; never apply deletions.
# The incoming message/author metadata is retained without merging its ancestry.
function apply_bundle_v01() {
  local dir_root fl_bundle fl_hash fl_hash_marker old_hash
  local fl_message commit_id base_commit tmp_root tmp_payload tmp_changes tmp_message marker_tmp
  local author_name author_email author_date
  local change_status old_path rel_file source_file target_file
  local tracked_status
  local -a apply_paths=()
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
  base_commit=$(git -C "${dir_root}" merge-base HEAD "${commit_id}") || {
    echo "abtt: incoming bundle has no common ancestor with this repository." >&2
    return 1
  }

  fl_message=$(git -C "${dir_root}" show -s --format=%B "${commit_id}") || return 1
  author_name=$(git -C "${dir_root}" show -s --format=%an "${commit_id}") || return 1
  author_email=$(git -C "${dir_root}" show -s --format=%ae "${commit_id}") || return 1
  author_date=$(git -C "${dir_root}" show -s --format=%aI "${commit_id}") || return 1
  if [[ -z "${author_name}" || -z "${author_email}" || -z "${author_date}" ]]; then
    echo "abtt: incoming commit is missing author metadata." >&2
    return 1
  fi
  if [[ -z "${fl_message//[[:space:]]/}" ]]; then
    fl_message='Apply incoming source bundle'
  fi

  tmp_root=$(mktemp -d) || return 1
  tmp_payload="${tmp_root}/payload"
  tmp_changes="${tmp_root}/changes"
  tmp_message="${tmp_root}/message"
  mkdir -p -- "${tmp_payload}" || {
    rm -rf -- "${tmp_root}"
    return 1
  }

  # The merge base defines the bundle's incremental scope. Only incoming
  # additions, modifications, and rename destinations are candidates for copy.
  if ! git -C "${dir_root}" diff --name-status -z --find-renames \
       "${base_commit}" "${commit_id}" > "${tmp_changes}"; then
    rm -rf -- "${tmp_root}"
    echo "abtt: could not determine incoming bundle changes." >&2
    return 1
  fi

  while IFS= read -r -d '' change_status; do
    case "${change_status}" in
      R*|C*)
        IFS= read -r -d '' old_path || {
          rm -rf -- "${tmp_root}"
          echo "abtt: malformed rename/copy entry in incoming diff." >&2
          return 1
        }
        IFS= read -r -d '' rel_file || {
          rm -rf -- "${tmp_root}"
          echo "abtt: malformed rename/copy destination in incoming diff." >&2
          return 1
        }
        ;;
      D*)
        # Incoming deletions are intentionally non-destructive. Keep the
        # receiving repository's existing path until removal is authorized.
        IFS= read -r -d '' old_path || {
          rm -rf -- "${tmp_root}"
          echo "abtt: malformed deletion entry in incoming diff." >&2
          return 1
        }
        continue
        ;;
      A*|M*|T*)
        IFS= read -r -d '' rel_file || {
          rm -rf -- "${tmp_root}"
          echo "abtt: malformed file entry in incoming diff." >&2
          return 1
        }
        ;;
      *)
        rm -rf -- "${tmp_root}"
        echo "abtt: unsupported change type in incoming diff: ${change_status}" >&2
        return 1
        ;;
    esac

    # This marker describes the receiving repository's own bundle history;
    # it must never be copied from the sending repository.
    [[ "${rel_file}" == '.update.bundle.sha256' ]] && continue
    apply_paths+=("${rel_file}")
  done < "${tmp_changes}"

  # Preflight every destination before changing any source file.
  for rel_file in "${apply_paths[@]}"; do
    target_file="${dir_root}/${rel_file}"
    if git -C "${dir_root}" ls-files --error-unmatch -- "${rel_file}" >/dev/null 2>&1; then
      tracked_status=$(git -C "${dir_root}" status --porcelain=v1 --untracked-files=all -- "${rel_file}") || {
        rm -rf -- "${tmp_root}"
        return 1
      }
      if [[ -n "${tracked_status}" ]]; then
        rm -rf -- "${tmp_root}"
        printf 'abtt: local changes conflict with incoming file; leaving repository untouched: %s\n' "${rel_file}" >&2
        return 1
      fi
    elif [[ -e "${target_file}" || -L "${target_file}" ]]; then
      rm -rf -- "${tmp_root}"
      printf 'abtt: incoming file would overwrite an untracked local file; leaving repository untouched: %s\n' "${rel_file}" >&2
      return 1
    fi
  done

  if ((${#apply_paths[@]})); then
    if ! (set -o pipefail; git -C "${dir_root}" archive --format=tar "${commit_id}" -- "${apply_paths[@]}" \
         | tar -xf - -C "${tmp_payload}"); then
      rm -rf -- "${tmp_root}"
      echo "abtt: could not extract incoming changed files." >&2
      return 1
    fi

    for rel_file in "${apply_paths[@]}"; do
      source_file="${tmp_payload}/${rel_file}"
      target_file="${dir_root}/${rel_file}"
      if [[ ! -e "${source_file}" && ! -L "${source_file}" ]]; then
        rm -rf -- "${tmp_root}"
        printf 'abtt: incoming file is missing from its commit: %s\n' "${rel_file}" >&2
        return 1
      fi
      mkdir -p -- "${dir_root}/$(dirname -- "${rel_file}")" || {
        rm -rf -- "${tmp_root}"
        return 1
      }
      cp -pP -- "${source_file}" "${target_file}" || {
        rm -rf -- "${tmp_root}"
        printf 'abtt: could not install incoming file: %s\n' "${rel_file}" >&2
        return 1
      }
      git -C "${dir_root}" add -f -- "${rel_file}" || {
        rm -rf -- "${tmp_root}"
        printf 'abtt: could not stage incoming file: %s\n' "${rel_file}" >&2
        return 1
      }
    done
  fi

  if ! git -C "${dir_root}" diff --cached --quiet; then
    printf '%s\n' "${fl_message}" > "${tmp_message}" || {
      rm -rf -- "${tmp_root}"
      return 1
    }
    # Preserve incoming author identity/date; the receiving repository's
    # configured identity remains the committer.
    if ! GIT_AUTHOR_NAME="${author_name}" \
         GIT_AUTHOR_EMAIL="${author_email}" \
         GIT_AUTHOR_DATE="${author_date}" \
         git -C "${dir_root}" commit --file="${tmp_message}"; then
      rm -rf -- "${tmp_root}"
      echo "abtt: commit failed; bundle marker was not updated." >&2
      return 1
    fi
  else
    echo "abtt: no applicable source changes; no new commit needed."
  fi

  rm -rf -- "${tmp_root}"
  marker_tmp=$(mktemp "${fl_hash_marker}.tmp.XXXXXX") || return 1
  if ! printf '%s\n' "${fl_hash}" > "${marker_tmp}"; then
    rm -f -- "${marker_tmp}"
    return 1
  fi
  mv -f -- "${marker_tmp}" "${fl_hash_marker}" || {
    rm -f -- "${marker_tmp}"
    return 1
  }
  echo "abtt: applied ${commit_id:0:12}; incoming changes synchronized without deleting local-only files."
}

#-----------------------------------------------------------------------
# Apply only the incoming bundle's changes since the common Git ancestor.
# Default behavior applies deletions and completes renames/moves by removing
# their old paths. To restore the former preservation behavior, comment out
# the two remove_paths+=(...) statements in the diff parser and the git rm
# loop marked below; this leaves old rename/move paths behind and skips deletes.
# The incoming message/author metadata is retained without merging its ancestry.
function apply_bundle() {
  local dir_root fl_bundle fl_hash fl_hash_marker old_hash
  local fl_message commit_id base_commit tmp_root tmp_payload tmp_changes tmp_message marker_tmp
  local author_name author_email author_date
  local change_status old_path rel_file source_file target_file
  local tracked_status
  local -a apply_paths=() remove_paths=()
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
  base_commit=$(git -C "${dir_root}" merge-base HEAD "${commit_id}") || {
    echo "abtt: incoming bundle has no common ancestor with this repository." >&2
    return 1
  }

  fl_message=$(git -C "${dir_root}" show -s --format=%B "${commit_id}") || return 1
  author_name=$(git -C "${dir_root}" show -s --format=%an "${commit_id}") || return 1
  author_email=$(git -C "${dir_root}" show -s --format=%ae "${commit_id}") || return 1
  author_date=$(git -C "${dir_root}" show -s --format=%aI "${commit_id}") || return 1
  if [[ -z "${author_name}" || -z "${author_email}" || -z "${author_date}" ]]; then
    echo "abtt: incoming commit is missing author metadata." >&2
    return 1
  fi
  if [[ -z "${fl_message//[[:space:]]/}" ]]; then
    fl_message='Apply incoming source bundle'
  fi

  tmp_root=$(mktemp -d) || return 1
  tmp_payload="${tmp_root}/payload"
  tmp_changes="${tmp_root}/changes"
  tmp_message="${tmp_root}/message"
  mkdir -p -- "${tmp_payload}" || {
    rm -rf -- "${tmp_root}"
    return 1
  }

  # The merge base defines the bundle's incremental scope. Only incoming
  # additions, modifications, and rename destinations are candidates for copy.
  if ! git -C "${dir_root}" diff --name-status -z --find-renames \
       "${base_commit}" "${commit_id}" > "${tmp_changes}"; then
    rm -rf -- "${tmp_root}"
    echo "abtt: could not determine incoming bundle changes." >&2
    return 1
  fi

  while IFS= read -r -d '' change_status; do
    case "${change_status}" in
      R*|C*)
        IFS= read -r -d '' old_path || {
          rm -rf -- "${tmp_root}"
          echo "abtt: malformed rename/copy entry in incoming diff." >&2
          return 1
        }
        IFS= read -r -d '' rel_file || {
          rm -rf -- "${tmp_root}"
          echo "abtt: malformed rename/copy destination in incoming diff." >&2
          return 1
        }
        # A rename/move consumes its old path. A copy does not.
        if [[ "${change_status}" == R* ]]; then
          remove_paths+=("${old_path}")
        fi
        ;;
      D*)
        IFS= read -r -d '' old_path || {
          rm -rf -- "${tmp_root}"
          echo "abtt: malformed deletion entry in incoming diff." >&2
          return 1
        }
        remove_paths+=("${old_path}")
        continue
        ;;
      A*|M*|T*)
        IFS= read -r -d '' rel_file || {
          rm -rf -- "${tmp_root}"
          echo "abtt: malformed file entry in incoming diff." >&2
          return 1
        }
        ;;
      *)
        rm -rf -- "${tmp_root}"
        echo "abtt: unsupported change type in incoming diff: ${change_status}" >&2
        return 1
        ;;
    esac

    # This marker describes the receiving repository's own bundle history;
    # it must never be copied from the sending repository.
    [[ "${rel_file}" == '.update.bundle.sha256' ]] && continue
    apply_paths+=("${rel_file}")
  done < "${tmp_changes}"

  # Preflight every destination and every path that must be removed before
  # changing the receiving repository.
  for rel_file in "${remove_paths[@]}"; do
    if ! git -C "${dir_root}" ls-files --error-unmatch -- "${rel_file}" >/dev/null 2>&1; then
      rm -rf -- "${tmp_root}"
      printf 'abtt: incoming deletion/rename source is not tracked locally: %s\n' "${rel_file}" >&2
      return 1
    fi
    tracked_status=$(git -C "${dir_root}" status --porcelain=v1 --untracked-files=all -- "${rel_file}") || {
      rm -rf -- "${tmp_root}"
      return 1
    }
    if [[ -n "${tracked_status}" ]]; then
      rm -rf -- "${tmp_root}"
      printf 'abtt: local changes conflict with incoming deletion/rename; leaving repository untouched: %s\n' "${rel_file}" >&2
      return 1
    fi
  done

  for rel_file in "${apply_paths[@]}"; do
    target_file="${dir_root}/${rel_file}"
    if git -C "${dir_root}" ls-files --error-unmatch -- "${rel_file}" >/dev/null 2>&1; then
      tracked_status=$(git -C "${dir_root}" status --porcelain=v1 --untracked-files=all -- "${rel_file}") || {
        rm -rf -- "${tmp_root}"
        return 1
      }
      if [[ -n "${tracked_status}" ]]; then
        rm -rf -- "${tmp_root}"
        printf 'abtt: local changes conflict with incoming file; leaving repository untouched: %s\n' "${rel_file}" >&2
        return 1
      fi
    elif [[ -e "${target_file}" || -L "${target_file}" ]]; then
      rm -rf -- "${tmp_root}"
      printf 'abtt: incoming file would overwrite an untracked local file; leaving repository untouched: %s\n' "${rel_file}" >&2
      return 1
    fi
  done

  if ((${#apply_paths[@]})); then
    if ! (set -o pipefail; git -C "${dir_root}" archive --format=tar "${commit_id}" -- "${apply_paths[@]}" \
         | tar -xf - -C "${tmp_payload}"); then
      rm -rf -- "${tmp_root}"
      echo "abtt: could not extract incoming changed files." >&2
      return 1
    fi

    for rel_file in "${apply_paths[@]}"; do
      source_file="${tmp_payload}/${rel_file}"
      target_file="${dir_root}/${rel_file}"
      if [[ ! -e "${source_file}" && ! -L "${source_file}" ]]; then
        rm -rf -- "${tmp_root}"
        printf 'abtt: incoming file is missing from its commit: %s\n' "${rel_file}" >&2
        return 1
      fi
      mkdir -p -- "${dir_root}/$(dirname -- "${rel_file}")" || {
        rm -rf -- "${tmp_root}"
        return 1
      }
      cp -pP -- "${source_file}" "${target_file}" || {
        rm -rf -- "${tmp_root}"
        printf 'abtt: could not install incoming file: %s\n' "${rel_file}" >&2
        return 1
      }
      git -C "${dir_root}" add -f -- "${rel_file}" || {
        rm -rf -- "${tmp_root}"
        printf 'abtt: could not stage incoming file: %s\n' "${rel_file}" >&2
        return 1
      }
    done
  fi

  # Removal loop: comment this out together with the two remove_paths+=(...)
  # statements above to restore legacy behavior (retain old paths, skip deletes).
  for rel_file in "${remove_paths[@]}"; do
    if ! git -C "${dir_root}" rm -- "${rel_file}"; then
      rm -rf -- "${tmp_root}"
      printf 'abtt: could not remove incoming deletion/rename source: %s\n' "${rel_file}" >&2
      return 1
    fi
  done

  if ! git -C "${dir_root}" diff --cached --quiet; then
    printf '%s\n' "${fl_message}" > "${tmp_message}" || {
      rm -rf -- "${tmp_root}"
      return 1
    }
    # Preserve incoming author identity/date; the receiving repository's
    # configured identity remains the committer.
    if ! GIT_AUTHOR_NAME="${author_name}" \
         GIT_AUTHOR_EMAIL="${author_email}" \
         GIT_AUTHOR_DATE="${author_date}" \
         git -C "${dir_root}" commit --file="${tmp_message}"; then
      rm -rf -- "${tmp_root}"
      echo "abtt: commit failed; bundle marker was not updated." >&2
      return 1
    fi
  else
    echo "abtt: no applicable source changes; no new commit needed."
  fi

  rm -rf -- "${tmp_root}"
  marker_tmp=$(mktemp "${fl_hash_marker}.tmp.XXXXXX") || return 1
  if ! printf '%s\n' "${fl_hash}" > "${marker_tmp}"; then
    rm -f -- "${marker_tmp}"
    return 1
  fi
  mv -f -- "${marker_tmp}" "${fl_hash_marker}" || {
    rm -f -- "${marker_tmp}"
    return 1
  }
  echo "abtt: applied ${commit_id:0:12}; additions, modifications, renames, moves, and deletions synchronized."
}

#-----------------------------------------------------------------------
function test_pipeline()
{
  local flag=${1};
  if [ -f "${flag}" ]; then {
    make plinu > /dev/null || return $?;
  } else {
    echo "!!! Current mode: production! Execute:";
    echo "  $ make toggle_debug # td";
    echo "to switch environment to debugging mode";
  } > /dev/stderr;
  return 1;
  fi
  return 0;
}

#-----------------------------------------------------------------------
function create_git_bundle()
{
  local bundle='update.bundle'
  local base='056b2aa4d60d5be5be9c5d40bc3e8da0eab83f79'
  local tmp_bundle status_output

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

  # A bundle contains committed history, not working-tree edits. Ignore only
  # the receiver-local checksum marker; all other local changes must be dealt
  # with explicitly so the generated artifact cannot silently omit work.
  status_output=$(git status --porcelain=v1 --untracked-files=all -- . ':!.update.bundle' ':!.update.bundle.sha256') || return 1
  if [[ -n "${status_output}" ]]; then
    echo "ERROR: Uncommitted source changes exist; commit or preserve them before creating the bundle." >&2
    printf '%s\n' "${status_output}" >&2
    return 1
  fi

  tmp_bundle=$(mktemp "${bundle}.tmp.XXXXXX") || return 1
  if ! git bundle create "${tmp_bundle}" HEAD "^${base}"; then
    rm -f -- "${tmp_bundle}"
    echo "ERROR: Git bundle creation failed." >&2
    return 1
  fi
  if ! git bundle verify "${tmp_bundle}"; then
    rm -f -- "${tmp_bundle}"
    echo "ERROR: Git bundle verification failed." >&2
    return 1
  fi
  if ! mv -f -- "${tmp_bundle}" "${bundle}"; then
    rm -f -- "${tmp_bundle}"
    echo "ERROR: Could not publish the verified bundle as ${bundle}." >&2
    return 1
  fi
  echo "# Bundle created and verified: ${bundle}"
}

#-----------------------------------------------------------------------
# Generate the AI-oriented root README from its maintained source under README/.
function generate_root_readme() {
  local dir_root source_file target_file tmp_file

  dir_root=$(git rev-parse --show-toplevel) || return 1
  source_file="${dir_root}/README/000_ai_entry_point.md"
  target_file="${dir_root}/README.md"

  if [[ ! -f "${source_file}" ]]; then
    printf 'grr: README source not found: %s\n' "${source_file}" >&2
    return 1
  fi

  tmp_file=$(mktemp "${target_file}.tmp.XXXXXX") || return 1
  if ! cat -- "${source_file}" > "${tmp_file}"; then
    rm -f -- "${tmp_file}"
    return 1
  fi

  if cmp -s -- "${tmp_file}" "${target_file}"; then
    rm -f -- "${tmp_file}"
    echo "grr: root README is already current."
    return 0
  fi

  if ! mv -f -- "${tmp_file}" "${target_file}"; then
    rm -f -- "${tmp_file}"
    return 1
  fi
  echo "grr: generated ${target_file} from ${source_file}."
}

#-----------------------------------------------------------------------
# declare -F;


#-----------------------------------------------------------------------
# Extract the source tree carried by the root-level incremental Git bundle.
# The temporary repository keeps all fetch/archive operations away from the
# receiving repository's .git database and working tree.
function extract_git_bundle()
{
  local repo_root bundle_file destination tmp_repo

  repo_root=$(git rev-parse --show-toplevel) || {
    echo "ERROR: Current directory is not inside a Git repository." >&2
    return 1
  }
  bundle_file="${repo_root}/update.bundle"
  destination="${1:-z_update_bundle}"

  [[ -f "${bundle_file}" ]] || {
    echo "ERROR: Bundle not found: ${bundle_file}" >&2
    return 1
  }
  [[ -n "${destination}" ]] || {
    echo "ERROR: Extraction destination cannot be empty." >&2
    return 1
  }
  mkdir -p -- "${destination}" || return 1

  tmp_repo=$(mktemp -d) || return 1
  if ! git -C "${tmp_repo}" init -q; then
    rm -rf -- "${tmp_repo}"
    return 1
  fi
  if ! git -C "${tmp_repo}" fetch -q "${repo_root}" HEAD; then
    rm -rf -- "${tmp_repo}"
    echo "ERROR: Could not fetch the receiving repository's HEAD." >&2
    return 1
  fi
  if ! git -C "${tmp_repo}" fetch -q "${bundle_file}"; then
    rm -rf -- "${tmp_repo}"
    echo "ERROR: Could not fetch the incremental bundle: ${bundle_file}" >&2
    return 1
  fi
  if ! (set -o pipefail; git -C "${tmp_repo}" archive FETCH_HEAD | tar -xf - -C "${destination}"); then
    rm -rf -- "${tmp_repo}"
    echo "ERROR: Could not extract the bundle source tree into ${destination}." >&2
    return 1
  fi

  rm -rf -- "${tmp_repo}"
  echo "extract_git_bundle: extracted ${bundle_file} into ${destination}"
}
