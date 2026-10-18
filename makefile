#!/bin/env make

#h,# Trading Intelligence,,
#h,## Trading Lots Reconstruction (Flex Query redesign),,

#h,,,
#h,## makefile:,,
#h,------------------------------,,

export

# SHELL := /bin/bash

# declare -- MAKEFLAGS="-I /finanzas/ibkr/trading_intel/mk"
# ${shell MAKEFLAGS="-I /finanzas/ibkr/trading_intel/mk"}
# ${shell MAKEFLAGS="-I $$(PWD)/mk"}
MAKEFLAGS := -I /finanzas/ibkr/trading_intel/mk

VPATH := .

#=======================================================================
# Directories

dir_root     := /finanzas/ibkr
VPATH        += :$(dir_root)

dir_ibdata   := $(dir_root)/data
VPATH        += :$(dir_ibdata)

dir_tidata   := $(dir_root)/trading_intel/data
VPATH        += :$(dir_tidata)

dir_sh       := $(dir_root)/trading_intel/sh
VPATH        += :$(dir_sh)

dir_py       := $(dir_root)/trading_intel/py
VPATH        += :$(dir_py)

dir_jq       := $(dir_root)/trading_intel/jq
VPATH        += :$(dir_jq)

#=======================================================================
# Resources

sh__librry   := lib.sh
sh__bquery   := ibkr_download_flex_query.sh

awk_normlz   := ibkr_lots_normalize.awk

csv_bolots   := ibkr_open_lots_raw.csv
c_jsn_bolots := $(csv_bolots:csv=jsonl)

py__blivep   := ibkr_live_positions.py
jsn_blivep   := $(py__blivep:py=jsonl)

#=======================================================================
c_csv_bolots := $(dir_tidata)/$(csv_bolots)
r_csv_bolots := ${filter %/$(csv_bolots), $(^)}
r_sh__librry  = ${filter %/$(sh__librry), $(^)}

.DEFAULT_GOAL := help
VPATH         := ${subst $(space),,$(VPATH)}
.SILENT       :

########################################################################
#::Targets:

include lib.mk
include check_file_age.mk
include check_refresh_period.mk
include positions_live_pipeline.mk
include positions_lots_pipeline.mk
include utilities.mk

#=======================================================================
#h,## flpp,| update,: fetch lots, positions, and then process them
.PHONY : fetch_lots_position_process flpp update
fetch_lots_position_process flpp update : fetch_lot_inventory
fetch_lots_position_process flpp update : fetch_position_inventory
fetch_lots_position_process flpp update : process_lot_inventory
fetch_lots_position_process flpp update :
	echo DONE;

#=======================================================================
#h,## tt,| touch,: age live positions and lots
.PHONY : touch tt
touch tt : age_live_positions age_lots_data

#=======================================================================
.PHONY : infol
infol : $(csv_bolots)
# infol : $(c_jsn_bolots)
infol :
	echo "\$$(^):";                      \
	printf '  %s\n' $(^);                \
	z1=2; echo "[${z1}] [$${z1}]";       \
	:

#=======================================================================
#h,## dfm,| display_file_manifest,: display project file manifest
.DEFAULT : diplay_file_manifest dfm dfmf
diplay_file_manifest dfm dfmf :
	{                                                    \
		find . -type f                                     \
		| grep --invert-match                              \
		--regexp=/@/                                       \
		--regexp=ver                                       \
		--regexp=/data/                                    \
		--regexp=/repo/                                    \
		--regexp=/notes/                                   \
		--regexp=/pipeline_mk/                             \
		--regexp=/sh/clean_output.sh                       \
		--regexp=/sh/refactor_identifiers.*                \
		--regexp=/pipeline_mk.mk                           \
		;                                                  \
		find . -type f                                     \
		| grep                                             \
		--regexp=/data/.*_sample.*                         \
		--regexp=/notes/errors.txt                         \
		;                                                  \
	}                                                    \
	${call execute_on_rule, dfmf, > files.manifest}      \
# 		--regexp=files.manifest                           \
# 	| sort                                              \

# Consider:
# $ make dlp pld -pn | fmt -w 1 | tr -d ':;' | grep '/trading_intel/' | sort | uniq | grep -v '/data' | grep -e '\.mk' -e '\.py' -e '\.sh' -e '\.jq' | nl
# $ make dlp pld -n | fmt -w 1 | sort | uniq | grep '/finanz' | grep -v '/data/' | nl

#=======================================================================
.DEFAULT :
	echo "*** ERROR: Unknown target '$(@)'."; \
	echo "*** Try: make help"; \
	:

#=======================================================================
#h,## xyz,| xxx_yyy_zzz,: simple generic **template** rule
#.......................................................................
ext_xxyyzz := xxx_yyy_zzz.ext
ext_xxyy_p  = ${filter %/$(ext_xxyyzz), $(^)}
#.......................................................................
.PHONY : xxx_yyy_zzz xyz
xxx_yyy_zzz xyz : $(ext_xxyyzz)
xxx_yyy_zzz xyz :
	echo $(ext_xxyy_p); \
	:

#=======================================================================
#h,## td,| toggle_debug,: toggle debug mode **on/off**
# Note to AI: I think this rule should touch the lot and position 
# inventories into the future to avoid updating them
r_jsn_blivep = ${filter %/$(jsn_blivep), $(^)}
r_jsn_viewlt = ${filter %/view_lots.jsonl, $(^)}
#.......................................................................
.PHONY : toggle_debug td
toggle_debug td : $(sh__librry)
toggle_debug td : $(csv_bolots)
toggle_debug td : $(jsn_blivep)
toggle_debug td : $(c_jsn_viewlt)
toggle_debug td :
	source $(r_sh__librry); \
	toggle_debug $(r_csv_bolots) $(r_jsn_blivep); \
	toggle_debug $(r_jsn_viewlt) $(r_jsn_blivep); \
	:
