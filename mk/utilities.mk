
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
	printf \"%-12s%-25s%-s\n\"  \
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
	echo "PWD:"; \
	printf '  %s\n' $(PWD) ${subst /_,,${dir $(PWD)}_}; \
	echo "VPATH:"; \
	printf '  %s\n' $(VPATH); \
	: declare -p;
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
ln72 := ----------
ln72 := $(ln72)$(ln72)$(ln72)$(ln72)$(ln72)$(ln72)$(ln72)--
ln72 := ${subst -,\#,$(ln72)}
#.......................................................................
define publish_repo_dt =
${strip $()
{
	date_time=$$(date +"%y%m%d_%H%M%S");
	cat - > ./repo/repo_$${date_time}.md;
}
}
endef
#.......................................................................
define concatenate_file_list =
${strip $()
for fl in $$(cat -); do {              \
  echo $(ln72);                        \
  echo "# FILE: $${fl##*/} ::";        \
  echo $(ln72);                        \
  cat $${fl};                          \
} done                                 
}
endef
#.......................................................................
#h,### cf[f],| concatenate_files,: concatenate files in "files.manifest"
#h,  $ make dfm > files.manifest --> make dfmf                 # 1),,
#h,  $ dt.now.v; make cf > repo/repo_${dtnowv}.md --> make cff # 2),,
# This should be a separate common modular rule to include on each
# makefile using the MAKEFLAGS mechanism
.DEFAULT : concatenate_files cf cff
concatenate_files cf cff : files.manifest
	cat $(<)                                                 \
	| ${call concatenate_file_list}                          \
	${call execute_on_rule, cff, | ${call publish_repo_dt}}; \
	:
#.......................................................................
#h,### gcf[f],| git_concatenate_files,: concatenate files from git ls-files
#h,  $ dt.now.v; make gcf > repo/repo_${dtnowv}.md --> make gcff,,
.DEFAULT : git_concatenate_files gcf gcff
git_concatenate_files gcf gcff : 
	git ls-files                                                   \
	| ${call concatenate_file_list}                                \
	${call execute_on_rule, gcff, | ${call publish_repo_dt}};      \
	:
#.......................................................................
.DEFAULT : diplay_file_manifest dfm dfmf # to avoid warning/error
# diplay_file_manifest shold be implemented in the project's makefile

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

#=======================================================================
#h,### sgu,| show_git_user,: Show git's local user config entries
.PHONY : show_git_user sgu
show_git_user sgu :
	echo "# Current git config ...";               \
	git var GIT_AUTHOR_IDENT;                      \
	git var GIT_COMMITTER_IDENT;                   \
	git config --local --list --show-origin;       \
	:
	# git config --local --get user.name;            \
	# git config --local --get user.email;           \

#=======================================================================
#h,### ugu,| unset_git_user,: Unset git's local user config entries
.PHONY : unset_git_user ugu
unset_git_user ugu : show_git_user
unset_git_user ugu :
	git config --local --unset-all user.name;      \
	git config --local --unset-all user.email;     \
	echo "# New git config ...";                   \
	git config --local --list --show-origin;       \
	:

#=======================================================================
#h,### ab,| apply_bundle,: apply bundle to curren repo
.PHONY : apply_bundle ab
apply_bundle ab : $(sh__librry)
apply_bundle ab :
	echo "# Applying bundle to test project ...";  \
	source $(r_sh__librry);                        \
	apply_bundle;                          				 \
	:

#=======================================================================
#h,### cgb,| create_git_bundle,: Create incremental Git bundle
.PHONY : create_git_bundle cgb
create_git_bundle cgb : $(sh__librry)
create_git_bundle cgb :
	source $(r_sh__librry);              \
	create_git_bundle;                   \
	:

#=======================================================================
#h,### zr,| zip_repository,: create a zip with code-base + git-database
.PHONY : zip_repository zr
zip_repository zr :
	{ git ls-files; find .git/;} > file.manifest; \
	zip -@ trading_intel.zip < file.manifest; \
	:
