
#h,,,
#h,## position_inventory_pipeline.mk:,,
#h,----------------------------------,,

#=======================================================================
#h,### fpi,| fetch_position_inventory,: download live positions
c_jsn_blivep       := $(dir_tidata)/$(jsn_blivep) # .../ibkr_position_inventory.jsonl
r_py__blivep        = ${filter %/$(py__blivep), $(^)}
trigger_dependency := /tmp/dlp_260706211938.tmp
TRIGGER_DEPENDENCIES += $(trigger_dependency)
#.......................................................................
.PHONY : download_live_positions
download_live_positions : $(c_jsn_blivep)
$(c_jsn_blivep) ::                               \
	$(py__blivep)                                  \
	$(trigger_dependency)                          \
;
	time python3 $(r_py__blivep) jsonl             \
	| grep 'U8546916'                              \
	| sed 's/268A/268A.T/g'                        \
	> $(@);                                        \
:
# 	| grep --invert-match 'U20784496'              \
# Note to AI: transformations of the Python data (grep, sed, etc.)
# should be delegated to a Make rule of its owns or move to {jq}
# processing down the pipeline.
#.......................................................................
.PHONY : fetch_position_inventory fpi
fetch_position_inventory fpi : refresh_period := 2592000 #  30 days (test)
fetch_position_inventory fpi : refresh_period := 300 # 5 minutes
fetch_position_inventory fpi : refresh_period := 10
fetch_position_inventory fpi : refresh_period := 420 # 7 minutes
fetch_position_inventory fpi : trigger_dependency := $(trigger_dependency)
fetch_position_inventory fpi : check_refresh_period
fetch_position_inventory fpi : download_live_positions

# NOTE:
# The separation between fetch_position_inventory and
# download_live_positions is intentional.  check_refresh_period
# must execute first so that its external refresh logic
# can update trigger_dependency before Make evaluates
# download_live_positions.  download_live_positions therefore remains
# a distinct dependency-controlled target;  consolidating it with
# fetch_position_inventory would bypass this mechanism and could  cause the
# acquisition operation to execute unnecessarily.  The arrangement is
# algorithmically and mechanically sound and preserves the  intended
# separation between refresh-state determination and Resource
# acquisition.

#=======================================================================
r_jq__normlz = ${filter %/normalize_live_positions.jq, $(^)}
#.......................................................................
$(c_jsn_blivep) ::                               \
	normalize_live_positions.jq                    \
	$(trigger_dependency)                          \
;
	echo "## 010 normalize_live_positions 020";    \
	jq . $(@) > ${dir $(@)}010_${notdir $(@)};     \
	${call jq_stage                                \
	, --compact-output                             \
	, $(r_jq__normlz)                              \
	, $(@)                                         \
	, 020_                                         \
	};                                             \
:

#=======================================================================
# Additional normalization/processing rules ...
# $(c_jsn_blivep) ::

# Note:
# At the moment, runtime output provide description.
# Eventually, files generated should be prefixes as follows:
# 010_norm_livepos_
# 020_canon_sorted_

#=======================================================================
r_jsn_snap01 = $(@:.jsonl=_static.jsonl) # .../ibkr_position_inventory_static.jsonl
c_jsn_blives=${subst .jsonl,_sample.jsonl,$(@)};
#.......................................................................
$(c_jsn_blivep) ::                               \
	$(trigger_dependency)                          \
;
	echo "## Creating: ${notdir $(r_jsn_snap01)}"; \
	cp --force $(@) $(r_jsn_snap01);               \
	head --lines=10 $(@) > ${c_jsn_blives}         \
:

#=======================================================================
#h,### alp,| age_live_positions,: make **live** positions old
.PHONY : age_live_positions alp t2
age_live_positions alp t2 :
	echo "# TOUCHING: $(c_jsn_blivep)";            \
	touch -d "50 years ago" $(c_jsn_blivep);       \
:

