#!/bin/bash -
#===============================================================================
#
#         USAGE: ./render.sh --help
#
#   DESCRIPTION: Render quote images
#  REQUIREMENTS: ---
#        AUTHOR: Sylvain S. (ResponSyS), mail@sylsau.com
#       CREATED: 04/06/2018 09:44:31 PM
#===============================================================================

# TODO:
# 	The current --reset prompt might be problematic when handling big 'quotes' file
# 	Make --reset prompt would ask for file(s) to remove in this fashion:
# 		1: render/marx-lol_fags.png
# 		2: render/engels-mad_bra?.png
# 		Files to remove (1..2)? || 		# || is the cursor

# Set debug parameters
[[ $DEBUG ]] && set -o nounset
set -o errexit -o pipefail

LIBSYL=${LIBSYL:-$HOME/Devel/Src/radiquotes/libsyl.sh}
source "$LIBSYL"

VERSION=0.9

SITUATION="./situation.sh"
FILE_QUOTES="./quotes"
DIR_RENDER="./Renders"
# Options
OPT_RESET=0
OPT_FORCE=0
READ_SITUARGS=0
# Default arguments for situation
SITUARGS="-fontcol rgb(43,254,210) -fontq ./Fonts/Avenir_next_condensed/AvenirNextCondensed-Heavy.ttf -fonta ./Fonts/Avenir/Avenir-BookOblique.ttf"
# Temp files
FILE_QUOTES_TMP=
# Extension of rendered images
EXT="png"
# Error codes
ERR_PARSE=11
ERR_FNAME=22

# Print help
fn_show_help() {
    cat << EOF
$SCRIPT_NAME $VERSION
    Radiquote renderer for Aufhebung.
    Batch-render quote images.
USAGE
    $SCRIPT_NAME [OPTIONS] [--help]
OPTIONS
    -d RENDER_DIR       set directory for rendered quote images
                        (default: "$RENDER_DIR")
    --reset             reset all image files inside render directory (prompt)
    -f                  with --reset, disable prompt
    --                  all arguments beyond '--' will be transmitted to
                        $SITUATION as is
    --dry-run           don't do anything, just 'echo' commands
EXAMPLE
    $ $SCRIPT_NAME   -d My_renders/ -- -fontcol snow3 -b /tmp/tiddies.jpg
    $ $SCRIPT_NAME   -d My_shitty_renders/ --reset -- -fontq times_new_roman.otf
AUTHOR
    Collectif Aufhebung: <http://aufhebung.fr>
    Written by Sylvain Saubier (<http://SystemicResponse.com>)
    Report bugs at: <feedback@sylsau.com>
EOF
}

fn_print_params() {
	cat 1>&2 << EOF
 DIR_RENDER     $DIR_RENDER
 OPT_FORCE      $OPT_FORCE
 OPT_RESET      $OPT_RESET
EOF
}
# Create tmp file for 'quotes'
fn_mktemp() {
	RET="$( mktemp ${TMP_DIR}/quotes.XXX )"
}
# $1: line number, $2: file
fn_get_line() {
	RET=$( sed -n "$1p" $2 )
}
# $1: line to parse
fn_parse_quote() {
	RET=$( echo $1 | cut -d '@' -f1 )
}
# $1: line to parse
fn_parse_source() {
	RET=$( echo $1 | cut -d '@' -f2 )
}
# $1: full quote, $2: full source
fn_make_filename() {
	local QUOTE_START=
	local AUTHOR=
	QUOTE_START=$( 	echo "$1" | cut -d ' ' -f1-6 )
	AUTHOR=$(	echo "$2" | cut -d ',' -f1 )
	RET="${DIR_RENDER}/$( echo "${AUTHOR}-${QUOTE_START}.${EXT}" | tr ' ' '_' )"
}
# $1: full quote, $2: full source, $3: filename
fn_render() {
	$SITUATION -q "$1" -a "$2" -o "$3" $SITUARGS
}


main() {
	fn_need_cmd "mktemp"
	fn_need_cmd "sed"
	fn_need_cmd "cut"

	cd "$( dirname "$0" )" || fn_exit_err "Can't 'cd' into '$( dirname "$0" )'" $ERR_NO_FILE
	m_say "cd '$(pwd)'"

	# PARSE ARGUMENTS
	while [[ $# -ge 1 ]]; do
		case "$1" in
			"-d")
				[[ $2 ]] || fn_exit_err "missing argument to '-d'" $ERR_WRONG_ARG
				shift
				DIR_RENDER="$1"
				;;
			"--reset")
				OPT_RESET=1
				;;
			"-f")
				OPT_FORCE=1
				;;
			"-h"|"--help")
				fn_show_help
				exit
				;;
			"--")
				READ_SITUARGS=1
				;;
			"--dry-run")
				OPT_DRYRUN=1
				;;
			*)
				[[ $READ_SITUARGS -ne 1 ]] && fn_exit_err "invalid option '$1'" $ERR_WRONG_ARG
				SITUARGS="$SITUARGS $1"
				;;
		esac	# --- end of case ---
		# Delete $1
		shift
	done

	[[ $DEBUG ]] && { fn_say_debug "Parameters:"; fn_print_params; }

	# Dry-run
	[[ "$OPT_DRYRUN" -eq 1 ]] && SITUATION="echo $SITUATION"

	# Reseting render dir
	[[ -n "$( \ls "${DIR_RENDER}" )" ]] || m_say "[Warning] Directory ${DIR_RENDER}/ is already empty." && OPT_RESET=0
	if [[ "$OPT_RESET" -eq 1 ]]; then
		local PROMPT_FLAG=
		local ECHO=

		# Just checking var to avoid 'rm -r /*'
		[[ -n "$DIR_RENDER" ]] || fn_exit_err "Please set render directory with '-d' or check script variable." $ERR_WRONG_ARG

		m_say "Cleaning directory '${DIR_RENDER}'..."
		[[ "$OPT_DRYRUN" -eq 1 ]] && ECHO="echo"
		[[ "$OPT_FORCE" -eq 0 ]] && PROMPT_FLAG="-i"
		$ECHO rm -rv ${PROMPT_FLAG} "${DIR_RENDER}"/*
	fi

	# Making temp file
	fn_mktemp
	[[ -n "$RET" ]] || fn_exit_err "Can't create temporary file in '${TMP_DIR}/'" $ERR_NO_FILE
	FILE_QUOTES_TMP=$RET
	trap 'rm -v "$FILE_QUOTES_TMP"' EXIT
	cp -v "$FILE_QUOTES" "$FILE_QUOTES_TMP"

	local LINE_NO=1

	fn_get_line "$LINE_NO" "$FILE_QUOTES_TMP"
	while [[ -n "$RET" ]]; do
		fn_say_debug "Line $LINE_NO"
		local LINE="$RET"
		local QUOTE=
		local SOURCE=
		local FNAME=

		fn_parse_quote "$LINE"
		[[ -n "$RET" ]] || fn_exit_err "Can't get quote out of line \"$LINE\"" $ERR_PARSE
		QUOTE="$RET"
		fn_parse_source "$LINE"
		[[ -n "$RET" ]] || fn_exit_err "Can't get source out of line \"$LINE\"" $ERR_PARSE
		SOURCE="$RET"

		fn_say_debug "Quote: $QUOTE"
		fn_say_debug "Source: $SOURCE"

		fn_make_filename "$QUOTE" "$SOURCE"
		[[ -n "$RET" ]] || fn_exit_err "Can't make filename from line \"$LINE\"" $ERR_FNAME
		FNAME="$RET"
		fn_say_debug "Output filename: $FNAME"

		if [[ ! -f "$FNAME" ]]; then
			m_say "Rendering '$FNAME'..."
			fn_render "$QUOTE" "$SOURCE" "$FNAME"
		else
			m_say "Not rendering '$FNAME' (already exists)"
		fi

		let "LINE_NO++"
		fn_get_line "$LINE_NO" "$FILE_QUOTES_TMP"
	done

	m_say "Reached end of '$FILE_QUOTES'"
	m_say "All done!"
}

main "$@"
