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
# 	* Use default arg (*) for input 'quotes'-like file

# Set debug parameters
[[ $DEBUG ]] && set -o nounset
set -o errexit -o pipefail

LIBSYL=${LIBSYL:-$HOME/Devel/Src/radiquotes/libsyl.sh}
source "$LIBSYL"
LIBPARSE=${LIBPARSE:-$HOME/Devel/Src/radiquotes/libparse.sh}
source "$LIBPARSE"

VERSION=0.9

SITUATION="./situation.sh"
FILE_QUOTES="./quotes"
DIR_RENDER="./Renders"
# Options
OPT_RESET=
OPT_FORCE=
OPT_DRYRUN=
READ_SITUARGS=0
# Default arguments for situation
SITUARGS="-c rgb(43,254,210) -fontq ./Fonts/Avenir_next_condensed/AvenirNextCondensed-Heavy.ttf -fonts ./Fonts/Avenir/Avenir-BookOblique.ttf"
# Temp files
FILE_QUOTES_TMP=
# Extension of rendered images
EXT="png"
# Error codes
ERR_FNAME=22

# Print help
fn_show_help() {
    cat << EOF
$SCRIPT_NAME $VERSION
    Radiquote renderer for Aufhebung.
    Batch-render quote images from '$FILE_QUOTES'.
USAGE
    $SCRIPT_NAME [OPTIONS] [--help]
OPTIONS
    -d RENDER_DIR       set directory for rendered quote images
                        (default: "$DIR_RENDER")
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
# $1: line number, $2: file
fn_get_line() {
	RET=$( sed -n "$1p" $2 )
}
# $1: full quote, $2: full source
fn_make_filename() {
	local QUOTE_START=
	local AUTHOR=
	# easier use of non-breakable space UTF-8 char
	# NOTE: must use printf to handle UTF-8 char
	local NBSP="$( printf "\u00A0" )"
	QUOTE_START=$( 	printf "$1" | sed 's/'$NBSP'/ /g' | cut -d ' ' -f1-6 )
	AUTHOR=$(	printf "$2" | sed 's/'$NBSP'/ /g' | cut -d ',' -f1 )
	RET="${DIR_RENDER}/$( echo "${AUTHOR}-${QUOTE_START}.${EXT}" | tr ' ' '_' )"
}
# $1: full quote string, $3: filename
fn_render() {
	$SITUATION "$1" -o "$2" $SITUARGS
}


main() {
	syl_need_cmd "mktemp"
	syl_need_cmd "sed"
	syl_need_cmd "cut"

	# PARSE ARGUMENTS
	while [[ $# -ge 1 ]]; do
		case "$1" in
			"-d")
				[[ $2 ]] || syl_exit_err "missing argument to '-d'" $ERR_WRONG_ARG
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
				[[ $READ_SITUARGS -ne 1 ]] && syl_exit_err "invalid option '$1'" $ERR_WRONG_ARG
				SITUARGS="$SITUARGS $1"
				;;
		esac	# --- end of case ---
		# Delete $1
		shift
	done

	syl_cd_workdir

	[[ $DEBUG ]] && { syl_say_debug "Parameters:"; fn_print_params; }

	# Dry-run
	[[ $OPT_DRYRUN ]] && SITUATION="echo $SITUATION"

	# Reseting render dir
	[[ -n "$( \ls "${DIR_RENDER}" )" ]] || {
		msyl_say "[Warning] Directory ${DIR_RENDER}/ is already empty."
		OPT_RESET=
	}
	if [[ $OPT_RESET ]]; then
		local ECHO=
		local DO_IT=

		# Just checking var to avoid 'rm -r /*'
		[[ -n "$DIR_RENDER" ]] || syl_exit_err "Please set render directory with '-d' or check script variable." $ERR_WRONG_ARG

		msyl_say "Cleaning directory '${DIR_RENDER}'..."
		[[ $OPT_DRYRUN ]] && ECHO="echo"
		if [[ $OPT_FORCE ]]; then
			DO_IT=1
		else
			local RESP="n"
			echo -n "All files inside '${DIR_RENDER}/' will be deleted. Proceed? (y/n): " && read RESP
			[[ "$RESP" = "y" ]] && DO_IT=1
		fi
		[[ $DO_IT ]] && $ECHO rm -rv "${DIR_RENDER}"/*
	fi

	# Making temp file
	syl_mktemp "radiquotes-render" ".list"
	FILE_QUOTES_TMP="$RET"
	trap 'rm -v "$FILE_QUOTES_TMP"' EXIT
	cp -v "$FILE_QUOTES" "$FILE_QUOTES_TMP"

	local LINE_NO=1

	fn_get_line "$LINE_NO" "$FILE_QUOTES_TMP"
	while [[ -n "$RET" ]]; do
		syl_say_debug "Line $LINE_NO"
		local LINE="$RET"
		local QUOTE=
		local SOURCE=
		local FNAME=

		fn_parse_quote "$LINE"
		QUOTE="$RET"
		fn_parse_source "$LINE"
		SOURCE="$RET"

		syl_say_debug "Quote: $QUOTE"
		syl_say_debug "Source: $SOURCE"

		fn_make_filename "$QUOTE" "$SOURCE" || 
			syl_exit_err "Can't make filename from line \"$LINE\"" $ERR_FNAME
		FNAME="$RET"
		syl_say_debug "Output filename: $FNAME"

		if [[ ! -f "$FNAME" ]]; then
			msyl_say "Rendering '$FNAME'..."
			fn_render "$LINE" "$FNAME"
		else
			msyl_say "Not rendering '$FNAME' (already exists)"
		fi

		let "LINE_NO++"
		fn_get_line "$LINE_NO" "$FILE_QUOTES_TMP"
	done

	msyl_say "Reached end of '$FILE_QUOTES'"
	msyl_say "All done!"
}

main "$@"
