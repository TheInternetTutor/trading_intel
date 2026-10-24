
#-----------------------------------------------------------------------
define prefix_filename =
${strip $()
	${eval
		path   := ${strip $(1)}
		prefix := ${strip $(2)}
	}
	${eval
		filename  := ${notdir $(path)}
	}
	$(dir_tidata)/$(prefix)$(filename:jq=jsonl)
}
endef

#-----------------------------------------------------------------------
# NOTE — PRIVATE MACRO CONVENTION:
# A leading underscore identifies a private/internal Make macro.
# Private macros are implementation helpers and are not part of the
# module's public macro interface. They may be called by public macros
# within the module but should not be treated as externally callable
# interfaces.
#
# This convention is intentional and should be considered part of the
# project's Make macro naming standard. Future directive audits should
# preserve this convention and, if appropriate, formalize it explicitly
# in the directive.
##......................................................................
define _jq_arg_validation =
${eval 
	options  := ${strip $(1)}
	script   := ${strip $(2)}
	inputs   := ${strip $(3)}
	prefix   := ${strip $(4)}
}
${eval
	input1 := ${word 1, $(inputs)}
}
${eval
	fl_out  = ${dir $(input1)}$(prefix)${notdir $(input1)}
}
: echo -n                            \
	"${notdir $(input1)}"              \
	"--> ${notdir $(script)}"          \
	"--> ${notdir $(fl_out)}"          \
;
endef
##......................................................................
define _jq_transform =
	jq $(options) --from-file 
	$(script)
	$(inputs) 
	> 
	$(input1).tmp;
endef
##......................................................................
define _jq_publish =
	mv --force 
	$(input1).tmp 
	$(input1);
	jq .
	$(input1) 
	> 
	$(fl_out);
endef
##......................................................................
define jq_stage  =
${call _jq_arg_validation, $(1), $(2), $(3), $(4)}
${strip $()
	${call _jq_transform}
	${call _jq_publish}
	:
}
endef

#-----------------------------------------------------------------------
define execute_on_rule =
${strip 
${if ${findstring ${strip $(1)}, $(MAKECMDGOALS)}, ${strip $(2)}}
}
endef
