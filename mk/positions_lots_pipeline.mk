
#h,,,
#h,## positions_live_pipeline.mk:,,
#h,------------------------------,,

#=======================================================================
# NOTE — PIPELINE MODULE BOUNDARY:
#
# This module intentionally contains all stages of the Lots Data
# pipeline (010 through 100). The stages are sequential transformations
# of the same evolving Resource and therefore constitute one coherent
# pipeline responsibility.
#
# Do not split individual stages into separate Make modules merely
# because the module contains many rules. The module boundary represents
# the pipeline/domain, not the number of stages or rules it contains.
#
# Generic/reusable rules belong in utilities.mk; shared shell services
# belong in lib.mk. This module should contain the orchestration specific
# to the Lots Data pipeline.
#
# Future architectural reviews should preserve this boundary unless
# the pipeline develops genuinely independent responsibilities that
# justify separate modules.
#=======================================================================

#=======================================================================
#h,### fli,| fetch_lot_inventory,: download open lots
c_csv_rawlot := $(dir_tidata)/$(csv_bolots) # .../ibkr_open_lots_raw.csv
c_jsn_snap02 := $(dir_tidata)/ibkr_live_positions_static.jsonl
r_sh__bquery = ${filter %/$(sh__bquery), $(^)} # .../ibkr_download_flex_query.sh
trigger_dependency := /tmp/dlp_260706211737.tmp
#.......................................................................
.PHONY : build_lots_data
build_lots_data : $(c_csv_rawlot)
$(c_csv_rawlot) : $(sh__librry)
$(c_csv_rawlot) : $(sh__bquery)
$(c_csv_rawlot) : $(trigger_dependency)
$(c_csv_rawlot) :
	echo "# Fetching: $(@)";                       \
	source $(r_sh__librry);                        \
	build_lots_data $(@) $(r_sh__bquery);          \
	# touch $(c_jsn_snap02); # Was this command necessary? For what?
#.......................................................................
.PHONY : fetch_lot_inventory fli
fetch_lot_inventory fli : refresh_period := 2592000 #  30 days (test)
fetch_lot_inventory fli : refresh_period := 86400 # 24 hours
fetch_lot_inventory fli : refresh_period := 43200 # 12 hours
fetch_lot_inventory fli : refresh_period := 32400 #  9 hours
fetch_lot_inventory fli : refresh_period := 5 # seconds
fetch_lot_inventory fli : refresh_period := 25200 #  7 hours
fetch_lot_inventory fli : trigger_dependency := $(trigger_dependency)
fetch_lot_inventory fli : check_refresh_period
fetch_lot_inventory fli : build_lots_data

# literal assignments (86400) **must** be commented since they are 
# **not** overwritten by assignment performing variable expansion!

# NOTE:
# The separation between fetch_lot_inventory and build_lots_data is intentional.
# check_refresh_period must execute first so that its external refresh logic
# can update trigger_dependency before Make evaluates build_lots_data.
# build_lots_data therefore remains a distinct dependency-controlled target;
# consolidating it with fetch_lot_inventory would bypass this mechanism and could
# cause the acquisition operation to execute unnecessarily.
# The arrangement is algorithmically and mechanically sound and preserves the
# intended separation between refresh-state determination and Resource
# acquisition.

#=======================================================================
# **commented while testing and implementing jq_pipeline.** This avoids
# the error due to a target having a single **and** doulbe colons rules.
# include pipeline_mk.mk
include pipeline_jq.mk

#=======================================================================
#h,### pli,| process_lot_inventory,: process lots data
.PHONY : process_lot_inventory pli
process_lot_inventory pli :            \
fetch_lot_inventory                    \
normalize_lot_inventory                \
;

#=======================================================================
#h,### ald,| age_lots_data,: make **lots** data old
.PHONY : age_lots_data ald t1
age_lots_data ald t1 :
	echo "# TOUCHING: $(c_csv_bolots)";            \
	touch -d "50 years ago" $(c_csv_bolots);       \
:
