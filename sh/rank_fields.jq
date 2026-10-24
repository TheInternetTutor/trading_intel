
#<xdisec>
################################################################################
# SCRIPT: rank_fields.jq

#</disec>

#-------------------------------------------------------------------------------
def normalize_table:
  split("\n")
  | map(
      gsub("\\*\\*"; "")
      | if startswith("|") then .[1:] else . end
      | if endswith("|") then .[:-1] else . end
    )
  | join("\n")
  ;

#-------------------------------------------------------------------------------
def table_to_objects:
  split("\n")
  | map(select(length > 0))
  | map(split("|") | map(gsub("^ +| +$"; "")))
  | . as $rows
  | $rows[0] as $headers
  | $rows[1:]
  | map(
      . as $values
      | reduce range(0; $headers | length) as $i
          ({}; .[$headers[$i]] = $values[$i])
    )
  ;

#-------------------------------------------------------------------------------
def create_metadata:
  . as $objects
  | [
      $objects[0]
      | reduce keys_unsorted[] as $header
          ({};
            .[
              $header
              | gsub("\\*\\*"; "")
              | gsub("\\([^)]*\\)"; "")
              | gsub("^[[:space:]]+|[[:space:]]+$"; "")
              | ascii_downcase
              | gsub("[[:space:]]+"; "_")
            ]
            # = ($header | gsub("\\*\\*"; ""))
            = $header
          )
        + {
            type: "metadata"
          }
      ,
      (
        $objects[]
        | . + {type: "data"}
      )
    ]
  ;

#-------------------------------------------------------------------------------
def rename_data_keys:
  .[0] as $metadata
  | .[1:] as $data
  | [
      $metadata,
      (
        $data[]
        | . as $record
        | reduce ($metadata | keys_unsorted[] | select(. != "type")) as $key
            ({};
              .[$key] = $record[$metadata[$key]]
            )
          + {type: "data"}
      )
    ]
  ;

#-------------------------------------------------------------------------------
def rank_fields($id; $fields):
  . as $data
  | {
      data: $data,
      sorted_by: (
        reduce $fields[] as $field
          ({};
            .[$field] = (
              $data[1:]
              | sort_by(.[ $field ] | tonumber)
              | map(.[ $id ])
            )
          )
      )
    }
;
#<xdisec>

#-------------------------------------------------------------------------------
def repeat_array($temporary_key; $pairs):
  . as $result
  | $result.sorted_by as $sorted_by
  | [
      $pairs[] as $pair
      | range(0; $pair[1])
      | $sorted_by[$pair[0]]
    ] as $repeated
  | $result + {($temporary_key): $repeated}
  ;

#-------------------------------------------------------------------------------
def parse_repeat($spec):
  ($spec | split(":")) as $parts
  | $parts[0] as $key
  | ($parts[1] | split(";")) as $args
  | [
      range(0; ($args | length); 2) as $i
      | [$args[$i], ($args[$i + 1] | tonumber)]
    ] as $pairs
  | repeat_array($key; $pairs)
  ;

#-------------------------------------------------------------------------------
def flatten_sorted_by:
  . as $result
  | $result.sorted_by as $sorted_by
  | ($sorted_by | keys_unsorted) as $fields
  | ($sorted_by[$fields[0]] | length) as $rows
  | ($fields | map($sorted_by[.]))
    + ($result.flatten_append // [])
  | [
      range(0; $rows) as $row
      | .[]
      | .[$row]
    ]
  ;

#-------------------------------------------------------------------------------
def aggregate_ranks:
  reduce .[] as $sym
      ({scores: {}, count: 0};
       .count += 1
       | .scores[$sym] = ((.scores[$sym] // 0) + .count)
      )
  | .scores
  | to_entries
  | sort_by(.key)
  | from_entries
  ;

#<xdisec>------------------------------------------------------------------------
#-------------------------------------------------------------------------------
def add_rank($spec; $store_key; $variable_name):
  . as $result
  | parse_repeat("flatten_append:" + $spec)
  # | display_result("sorted_by")
  | flatten_sorted_by
  | aggregate_ranks
  | {
      name: $variable_name,
      scores: .
    } as $rank
  | $result + {
      ($store_key): $rank
    }
  ;

#</disec>------------------------------------------------------------------------
################################################################################
# UTILITIES

#-------------------------------------------------------------------------------
def rpad($text; $width):
  ($text | tostring) as $s
  | if ($s | length) < $width
    then $s + (" " * ($width - ($s | length)))
    else $s
    end
  ;

#-------------------------------------------------------------------------------
def lpad($text; $width):
  ($text | tostring) as $s
  | if ($s | length) < $width
    then (" " * ($width - ($s | length))) + $s
    else $s
    end
  ;

#-------------------------------------------------------------------------------
def display_result($result_key):
  . as $result
  | $result.data[0] as $metadata
  | $result[$result_key] as $derived
  | ($derived | keys_unsorted) as $fields
  | ($result.flatten_append // []) as $append
  | (
      $fields
      + [ range(0; ($append | length)) | "repeat_\(. + 1)" ]
    ) as $display_fields
  | (
      $derived
      + (
          reduce range(0; ($append | length)) as $i
            ({};
             .["repeat_\($i + 1)"] = $append[$i]
            )
        )
    ) as $display_derived
  | ($display_derived[$display_fields[0]] | length) as $rows_count
  | reduce range(0; $rows_count) as $i
      ([$display_fields | map(
        if . as $field | ($fields | index($field)) != null
        then $metadata[.]
        else .
        end
      )];
       . + [
         $display_fields
         | map($display_derived[.][$i])
       ]
      ) as $rows
  | [
      range(0; ($rows[0] | length)) as $i
      | $rows
      | map(.[ $i ] | tostring | length)
      | max
    ] as $widths
  | [
      $rows[]
      | [
          range(0; length) as $i
          | rpad(.[ $i ]; $widths[$i])
        ]
      | join(" | ")
    ]
  | join("\n")
  | "\n" + . + "\n\n"
  | stderr
  | $result
  ;

#-------------------------------------------------------------------------------
def display_ranks($rank_keys):
  . as $result
  | ($rank_keys | map($result[.])) as $ranks
  | ($ranks[0].scores | keys | sort) as $symbols
  | (["SYM"] + ($ranks | map(.name))) as $headers
  | (
      [$headers]
      + (
          $symbols
          | map(
              . as $sym
              | [$sym]
                + ($rank_keys | map($result[.].scores[$sym]))
            )
        )
    ) as $rows
  | [
      range(0; ($rows[0] | length)) as $i
      | $rows
      | map(.[ $i ] | tostring | length)
      | max
    ] as $widths
  | (
      $widths
      | map("-" * .)
      | join("-+-")
    ) as $separator
  | [
      $rows[0],
      $separator,
      $rows[1:][] 
    ] as $display_rows
  | [
      $display_rows[]
      | if type == "string"
        then .
        else [
          range(0; length) as $i
          | if $i == 0
            then rpad(.[ $i ]; $widths[$i])
            else lpad(.[ $i ]; $widths[$i])
            end
        ]
        | join(" | ")
        end
    ]
  | join("\n")
  | "\n" + . + "\n\n"
  | stderr
  | empty
  ;

#-------------------------------------------------------------------------------
normalize_table
| table_to_objects
| create_metadata
| rename_data_keys

| rank_fields("sym"; ["ctp", "pv", "roi"])

| add_rank("ctp;0;pv;0;roi;0"; "keq"; "EQ")
| add_rank("ctp;1;pv;0;roi;0"; "kctp2"; "CTP2")
| add_rank("ctp;0;pv;1;roi;0"; "kpv2"; "PV2")
| add_rank("ctp;0;pv;0;roi;1"; "kroi2"; "ROI2")
| add_rank("ctp;1;pv;1;roi;0"; "k221"; "2-2-1")

| display_ranks(["keq", "kctp2", "kpv2", "kroi2", "k221"])

#<xdisec>------------------------------------------------------------------------
################################################################################
# OUTPUT:

#</disec>-----------------------------------------------------------------------
 
