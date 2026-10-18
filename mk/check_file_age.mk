
#h,,,
#h,## check_file_age.mk:,,
#h,------------------------------,,

#=======================================================================
#h,### cfa,| check_file_age,: check resource age
.PHONY : check_file_age cfa
check_file_age cfa : $(sh__librry)
check_file_age cfa : $(sh__bquery)
check_file_age cfa : $(csv_bolots)
check_file_age cfa :
	source $(r_sh__librry);              \
	check_file_age;                      \
	echo $${?};                          \
	check_file_age $(r_csv_bolots);      \
	echo $${?};                          \
	check_file_age $(r_csv_bolots) 5;    \
	echo $${?};                          \
	:
