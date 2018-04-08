SCRIPT_NAME="${0##*/}"

# Format characters
FMT_BOLD='\e[1m'
FMT_UNDERL='\e[4m'
FMT_OFF='\e[0m'
# Error codes
ERR_WRONG_ARG=2
ERR_NO_FILE=127
# Return value
RET=
# Temporary dir
TMP_DIR="/tmp"

# Test if a file exists (dir or not)
# $1: path to file
fn_need_file() {
	[[ -e "$1" ]] || fn_exit_err "need '$1' (file not found)" $ERR_NO_FILE
}
# Test if a dir exists
# $1: path to dir
fn_need_dir() {
	[[ -d "$1" ]] || fn_exit_err "need '$1' (directory not found)" $ERR_NO_FILE
}
# Test if a command exists
# $1: command
fn_need_cmd() {
	command -v "$1" >/dev/null 2>&1
	[[ $? -eq 0 ]] || fn_exit_err "need '$1' (command not found)" $ERR_NO_FILE
}
# $1: message
m_say() {
	#echo -e "$SCRIPT_NAME: $1"
	echo -e "$1"
}
# $1: debug message
fn_say_debug() {
	[[ ! "$DEBUG" ]] || echo -e "[DEBUG] $1"
}
# Exit with message and provided error code
# $1: error message, $2: return code
fn_exit_err() {
	m_say "${FMT_BOLD}ERROR${FMT_OFF}: $1" >&2
	exit $2
}
