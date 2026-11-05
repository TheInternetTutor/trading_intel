
VPATH += :$(dir_jq)/pipeline_make

#=======================================================================
#x,### nli,| normalize_lot_inventory,: normalize open lots
# c_jsn_blivep := $(dir_tidata)/$(jsn_blivep) # .../ibkr_position_inventory.jsonl
c_jsn_rawlot := ${subst _raw,,$(c_csv_rawlot:csv=jsonl)} # .../ibkr_open_lots.jsonl
r_csv_bolots  = ${filter %/$(csv_bolots), $(^)}
r_awk_normlz  = ${filter %/$(awk_normlz), $(^)}
r_jsn_blot10  = ${dir $(@)}010_${notdir $(@)}
#.......................................................................
.PHONY : normalize_lot_inventory nli
normalize_lot_inventory nli : $(c_jsn_rawlot)
$(c_jsn_rawlot) ::                                         \
	$(sh__librry)                                            \
	$(awk_normlz)                                            \
  $(c_jsn_blivep)                                          \
	$(csv_bolots)                                            \
;
	echo "# 010 Normalizing: ${r_csv_bolots}";               \
	source $(r_sh__librry);                                  \
	normalize_lot_inventory $(r_csv_bolots) $(r_awk_normlz)  \
	> $(@);                                                  \
	jq . $(@) > $(r_jsn_blot10);                             \
:

#=======================================================================
r_jq__disply = ${filter %/display_lots_canonically.jq, $(^)}
#.......................................................................
$(c_jsn_rawlot) ::                               \
  $(c_jsn_blivep)                                \
	$(csv_bolots)                                  \
	display_lots_canonically.jq                    \
;
	echo "# 020 display_lots_canonically:";        \
	${call jq_stage                                \
	, --compact-output --slurp                     \
	, $(r_jq__disply)                              \
	, $(@)                                         \
	, 020_                                         \
	};                                             \
:

#=======================================================================
r_jq__upmark = ${filter %/update_mark_prices.jq, $(^)}
#.......................................................................
$(c_jsn_rawlot) ::                     \
  $(c_jsn_blivep)                      \
	$(csv_bolots)                        \
	update_mark_prices.jq                \
;
	echo "# 030 update_mark_prices:";    \
	${call jq_stage                      \
	, --null-input --compact-output      \
	, $(r_jq__upmark)                    \
	, $(@) $(c_jsn_snap02)               \
	, 030_                               \
	};                                   \
:
# ibkr_position_inventory_static.jsonl  \
# 	, $(c_jsn_rawlot)                   \

#=======================================================================
r_jq__consld = ${filter %/consolidate_lots.jq, $(^)}
#.......................................................................
$(c_jsn_rawlot) ::                     \
  $(c_jsn_blivep)                      \
	$(csv_bolots)                        \
  consolidate_lots.jq                  \
;
	echo "# 040 consolidate_lots:";      \
	${call jq_stage                      \
	, --compact-output --slurp           \
	, $(r_jq__consld)                    \
	, $(@)                               \
	, 040_                               \
	};                                   \
:

#=======================================================================
r_jq__clsbke = ${filter %/classify_bke.jq, $(^)}
#.......................................................................
$(c_jsn_rawlot) ::                     \
  $(c_jsn_blivep)                      \
	$(csv_bolots)                        \
  classify_bke.jq                      \
;
	echo "# 050 classify_bke:";          \
	${call jq_stage                      \
	, --compact-output                   \
	, $(r_jq__clsbke)                    \
	, $(@)                               \
	, 050_                               \
	};                                   \
:

#=======================================================================
r_jq__clslos = ${filter %/classify_los.jq, $(^)}
#.......................................................................
$(c_jsn_rawlot) ::                     \
  $(c_jsn_blivep)                      \
	$(csv_bolots)                        \
  classify_los.jq                      \
;
	echo "# 060 classify_los:";          \
	${call jq_stage                      \
	, --compact-output                   \
	, $(r_jq__clslos)                    \
	, $(@)                               \
	, 060_                               \
	};                                   \
:

#=======================================================================
r_jq__clshvt = ${filter %/classify_hvt.jq, $(^)}
#.......................................................................
$(c_jsn_rawlot) ::                     \
  $(c_jsn_blivep)                      \
	$(csv_bolots)                        \
  classify_hvt.jq                      \
;
	echo "# 070 classify_hvt:";          \
	${call jq_stage                      \
	, --compact-output                   \
	, $(r_jq__clshvt)                    \
	, $(@)                               \
	, 070_                               \
	};                                   \
:

#=======================================================================
r_jq__clslkd = ${filter %/classify_lkd.jq, $(^)}
#.......................................................................
$(c_jsn_rawlot) ::                     \
  $(c_jsn_blivep)                      \
	$(csv_bolots)                        \
  classify_lkd.jq                      \
;
	echo "# 080 classify_lkd:";          \
	${call jq_stage                      \
	, --compact-output --slurp           \
	, $(r_jq__clslkd)                    \
	, $(@)                               \
	, 080_                               \
	};                                   \
:

#=======================================================================
r_jq__clslck = ${filter %/classify_locking.jq, $(^)}
r_jq__lckamt = ${filter %/locking_amount.jq, $(^)}
#.......................................................................
$(c_jsn_rawlot) ::                     \
  $(c_jsn_blivep)                      \
	$(csv_bolots)                        \
  classify_locking.jq                  \
  locking_amount.jq                    \
;
	echo "# 090 classify_locking:";      \
	${call jq_stage                      \
	, --compact-output --slurp           \
	, -f $(r_jq__clslck)                 \
	, $(@)                               \
	, 090_                               \
	};                                   \
:

#=======================================================================
r_jq__clspba = ${filter %/classify_pba.jq, $(^)}
#.......................................................................
$(c_jsn_rawlot) ::                     \
  $(c_jsn_blivep)                      \
	$(csv_bolots)                        \
  classify_pba.jq                      \
;
	echo "# 100 classify_pba:";          \
	${call jq_stage                      \
	, --compact-output --slurp           \
	, $(r_jq__clspba)                    \
	, $(@)                               \
	, 100_                               \
	};                                   \
:

#=======================================================================
r_jq__agghvt = ${filter %/aggregate_hvt.jq, $(^)}
#.......................................................................
$(c_jsn_rawlot) ::                     \
  $(c_jsn_blivep)                      \
  $(csv_bolots)                        \
  aggregate_hvt.jq                     \
;
	echo "# 110 aggregate_hvt:";         \
	${call jq_stage                      \
	, --compact-output --slurp           \
	, $(r_jq__agghvt)                    \
	, $(@)                               \
	, 110_                               \
	};                                   \
:

# Note:
# At the moment, runtime ouput provide discription:
# #  010 Normalizing: /finanzas/ibkr/trading_intel/data/ibkr_lot_inventory.csv
# ## 020 display_lots_canonically:
# ## 030 update_mark_prices:
# ## 040 consolidate_lots:
# ## 050 classify_bke:
# ## 060 classify_los:
# ## 070 classify_hvt:
# ## 080 classify_lkd:
# ## 090 classify_locking:
# ## 100 classify_pba:
# ## 110 View Lots copies:
# Eventually, files generated should be prefixes as follows:
# 010_csvnormalize_
# 020_canon_sorted_
# 030_mark_updated_
# 040_consolidated_
# 050_bke_assigned_
# 060_los_assigned_
# 070_hvt_assigned_
# 080_lkd_assigned_
# 090_lock_assignd_
# 100_pba_assigned_
# ...

#=======================================================================
c_jsn_viewlt := $(dir_tidata)/view_lots.jsonl
c_jsn_nlines  = ${dir $(@)}lines_n.jsonl # **debugging**
#.......................................................................
$(c_jsn_rawlot) ::                               \
	$(sh__librry)                                  \
  $(c_jsn_blivep)                                \
	$(csv_bolots)                                  \
;
	echo "# Creating stable copy for rederer application:";  \
	source $(r_sh__librry);                                  \
	copy_view_lots $(@) $(c_jsn_viewlt);                     \
:
