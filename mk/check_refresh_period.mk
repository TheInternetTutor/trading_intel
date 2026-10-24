
#h,,,
#h,## check_refresh_period.mk:,,
#h,------------------------------,,

#=======================================================================
#h,### crp,| check_refresh_period,: check refresh period
refresh_period     := 100
trigger_dependency := /tmp/crp_260706065936.tmp
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
