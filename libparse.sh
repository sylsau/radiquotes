#!/bin/bash -
#===============================================================================
#   DESCRIPTION: Functions are self-contained and **exit on error**.
#    DEPENDS ON: libsyl.sh
#        AUTHOR: Sylvain S. (ResponSyS), mail@sylsau.com
#       CREATED: 04/09/2018 11:05:19 PM
#===============================================================================

readonly ERR_PARSE=111

# $1: full string to parse
fn_parse_quote() {
	RET="$( echo "$1" | cut -d '@' -f1 )"
	[[ $? -eq 0 ]] || fn_exit_err "Can't get quote out of string \"$1\"" $ERR_PARSE
}
# $1: full string to parse
fn_parse_source() {
	RET="$( echo "$1" | cut -d '@' -f2 )"
	[[ $? -eq 0 ]] || fn_exit_err "Can't get source out of string \"$1\"" $ERR_PARSE
}
# $1: full string to parse
fn_parse_author() {
	fn_parse_source "$1"
	RET="$( echo "$RET" | cut -d ',' -f1 )"
	[[ $? -eq 0 ]] || fn_exit_err "Can't get author out of string \"$1\"" $ERR_PARSE
}
