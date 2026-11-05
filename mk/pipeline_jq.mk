
#=======================================================================
#h,### nli,| normalize_lot_inventory,: normalize open lots
define jq_pipeline_stage_1 =
${strip {
	echo "# Normalizing: $(@)";                        
	mkdir --parent ${dir $(@)}stage/;
	source $(r_sh__librry);                            
	normalize_lot_inventory $(r_csv_bolots) $(r_awk_normlz)
	> $(@);
}}
endef
#.......................................................................
define jq_pipeline_stage_1_debugging =
${strip {
	date_time=$$(date +"%y%m%d_%H%M%S");
	${call jq_pipeline_stage_1}
	&& jq -s 'sort_by(.symbol)[]' $(@) \
	> ${dir $(@)}/view_lots_yymmdd_hhmmss.jsonl;
}}
endef
#.......................................................................
c_jsn_rawlot := ${subst _raw,,$(c_csv_rawlot:csv=jsonl)} # .../ibkr_open_lots.jsonl
r_csv_bolots  = ${filter %/$(csv_bolots), $(^)}
r_awk_normlz  = ${filter %/$(awk_normlz), $(^)}
#.......................................................................
.PHONY : normalize_lot_inventory nli
normalize_lot_inventory nli : $(c_jsn_rawlot)
$(c_jsn_rawlot) ::                     \
	$(sh__librry)                        \
	$(awk_normlz)                        \
	$(c_jsn_blivep)                      \
	$(csv_bolots)                        \
;
	${call jq_pipeline_stage_1};

# 	${call execute_on_rule                               \
# 	, nldf                                               \
# 	,	| ${call jq_pipeline_stage_1, 010.jsonl}           \
# 	}                                                    \

#=======================================================================
# compatible with jq >= v.1.8+
# ...
# jq
# 	--library-path ${dir $(r_jq__librry)}pipeline_jq
# 	--library-path ${dir $(r_jq__librry)}
# 	--compact-output
# ...
# compatible with jq < v.1.8
define jq_pipeline_stages =
${strip $()
	echo "# JQ pipeline:";               
	echo "--- ${c_jsn_blivep}";               
	echo "--- $(@)";               
	echo "--- ${dir $(r_jq__librry)}pipeline_jq";               
	mkdir --parent ${dir $(@)}stage/;
	jq
		-L ${dir $(r_jq__librry)}pipeline_jq
		-L ${dir $(r_jq__librry)}
	  --compact-output
	  --slurp
	  --slurpfile live $(c_jsn_blivep)
	  --from-file $(r_jq__librry)
	  $(@)
	> $(@).tmp
	&& {
		mv --force $(@).tmp $(@);
	}
}
endef
#.......................................................................
define jq_pipeline_stages_debugging =
${strip $()
	date_time=$$(date +"%y%m%d_%H%M%S");
	${call jq_pipeline_stages}
	&& { jq . $(@) > ./data/stage/stage_$${date_time}.jsonl;}
}
endef
#.......................................................................
r_jq__librry  = ${filter %/lib.jq, $(^)}
#.......................................................................
$(c_jsn_rawlot) ::                     \
  lib.jq                               \
  $(c_jsn_blivep)                      \
	$(csv_bolots)                        \
;
	${call jq_pipeline_stages}

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
