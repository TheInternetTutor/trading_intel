
#h,,,
#h,## utilities.mk:,,
#h,------------------------------,,

#=======================================================================
#h,### h,| help,: display self-documenting help
#h,#### Alternatives to consider:,,
#h,- 1. keeping this rule entirely in a make module to avoid decoupling,,
#h,- 2. Consider Moving this rule's body to the Bash-library module for simplicity,,
define awk_pgm :=
${strip 
BEGIN {
	FS = \",\";
}
{
	short_command = \$$2;
	long_command  = \$$3;
	description   = \$$4;
	printf \"%-8s%-25s%-s\n\"   \
	, short_command             \
	, long_command              \
	, description               \
	;
}
}
endef
#.......................................................................
.PHONY : help h
help h : makefile mk/*.mk
	cat $(^) \
	| grep '#h,' \
	| grep -v "grep '#h,'" \
	| awk "$(awk_pgm)" \
	;

#=======================================================================
#:: infog | global_info                : global information
.PHONY : infog
infog :
	echo "VPATH:"; \
	printf '  %s\n' $(VPATH); \
	declare -p;
	:

#=======================================================================
#:: infol | lobal_info                 : local information
#:: -- implemented in the current project "makefile"
.PHONY : infol

#=======================================================================
#h,### i,| info,: display project information
.PHONY : info
info : infog infol

#=======================================================================
#h,### cf,| concatenate_files,: concatenate files in "files.manifest"
#h,  $ make dfmf or $ make dfm > files.manifest,,
#h,  $ dt.now.v; echo; make cf > repo/repo_${dtnowv}.md,,
# This should be a separate modular rule common to include on each
# makefile using the MAKEFLAGS mechanism
define publish_repo_dt =
${strip $()
{
	date_time=$$(date +"%y%m%d_%H%M%S");
	cat - > ./repo/repo_$${date_time}.md;
}
}
endef
#.......................................................................
ln72 := ----------
ln72 := $(ln72)$(ln72)$(ln72)$(ln72)$(ln72)$(ln72)$(ln72)--
ln72 := ${subst -,\#,$(ln72)}
#.......................................................................
.DEFAULT : diplay_file_manifest dfm dfmf
.DEFAULT : concatenate_files cf cff
concatenate_files cf cff : files.manifest
	date_time=$(date +"%y%m%d_%H%M%S");                      \
	cat $(<)                                                 \
	| for fl in $$(cat -); do {                              \
		echo $(ln72);                                          \
		# echo "# FILE: $${fl} ::";                            \
		echo "# FILE: $${fl##*/} ::";                          \
		echo $(ln72);                                          \
		cat $${fl};                                            \
	} done                                                   \
	${call execute_on_rule, cff, | ${call publish_repo_dt}}  \
	;

#=======================================================================
#h,### rsos,| run_scripts_on_source,: run scripts on source
define list_of_run_scripts =
${filter-out ${lastword $(^)}, ${wordlist 2, 100, $(^)}}
endef
.PHONY : run_scripts_on_source rsos
run_scripts_on_source rsos : $(sh__librry)
#--------------------------
run_scripts_on_source rsos : display_all_records.jq
# run_scripts_on_source rsos : find_duplicates.jq 
# run_scripts_on_source rsos : duplicate_lots_concise.jq
# run_scripts_on_source rsos : duplicate_lots_records_tab.jq
# run_scripts_on_source rsos : duplicate_lots_records_pipe.jq
run_scripts_on_source rsos : $(c_jsn_bolots)
#--------------------------
run_scripts_on_source rsos : 
	source $(<); \
	for fl_script in ${call list_of_run_scripts}; do { \
		run_scripts_on_source $${fl_script} ${lastword $(^)}; \
	} done;\
	:

#=======================================================================
#h,### ds,| display_sections,: display source ranges between <disec> tags
#h,  $ make cf | make ds,,
.PHONY : display_sections ds
display_sections ds :
	awk '                                          \
	  BEGIN {                                      \
	    tag = "disec";                             \
	    re_open  = "^.{1,3} *<" tag ">";           \
	    re_close = "^.{1,3} *</" tag ">";          \
	  }                                            \
	  $$0 ~ re_open  { printing = 1; next }        \
	  $$0 ~ re_close { printing = 0; next }        \
	  printing      { print }                      \
	';                                             \
