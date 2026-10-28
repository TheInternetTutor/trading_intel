
#h,,,
#h,## check_refresh_period.mk:,,
#h,------------------------------,,

#=======================================================================
#h,### itd,| initialize_trigger_dependencies,: initialize trigger dependencies
#h,  called at least once/periodically in any new environment ,,
#h,  before calling any rule depending on initialize_trigger_dependencies,,
TRIGGER_DEPENDENCIES :=
#.......................................................................
.PHONY: initialize_trigger_dependencies itd
initialize_trigger_dependencies itd :
	touch $(TRIGGER_DEPENDENCIES)

#=======================================================================
#h,### crp,| check_refresh_period,: check refresh period
refresh_period     := 100
trigger_dependency := /tmp/crp_260706065936.tmp
TRIGGER_DEPENDENCIES += $(trigger_dependency)
#.......................................................................
.PHONY : check_refresh_period crp
# check_refresh_period crp : refresh_period := $(refresh_period)
# check_refresh_period crp : trigger_dependency := $(trigger_dependency)
check_refresh_period crp : $(sh__librry)
check_refresh_period crp :
	echo "# refresh_period     := $(refresh_period)";        \
	echo "# trigger_dependency := $(trigger_dependency)";    \
	source $(r_sh__librry);                                  \
	check_refresh_period                                     \
		$(trigger_dependency)                                  \
		$(refresh_period)                                      \
		$(MAKECMDGOALS)                                        \
	;                                                        \
	[ $(refresh_period) -ge 604800 ] && echo "*** 7 days";   \
	echo;                                                    \
	:
