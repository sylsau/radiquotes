#!/bin/bash -
#===============================================================================
#
#         USAGE: ./situation.sh --help
#
#   DESCRIPTION: 
#  REQUIREMENTS: ---
#        AUTHOR: Sylvain S. (ResponSyS), mail@sylsau.com
#  ORGANIZATION: 
#       CREATED: 04/09/2018 07:55:01 PM
#===============================================================================

# Enable strict mode in debug mode
[[ $DEBUG ]] && set -o nounset
set -o errexit -o pipefail

LIBSYL=${LIBSYL:-$HOME/Devel/Src/radiquotes/libsyl.sh}
source "$LIBSYL"
LIBPARSE=${LIBPARSE:-$HOME/Devel/Src/radiquotes/libparse.sh}
source "$LIBPARSE"

VERSION=0.9

QUOTE_STRING=
FONT_QUOTE="Linux-Biolinum-O"
FONT_SOURCE="Linux-Biolinum-O-Italic"
FONT_COLOR="snow3"
BG_FILE=
BG_COLOR="black"
SIZE="1000x750"
EXT="png"
OUTFILE="${TMP_DIR}/situation.${EXT}"
QUOTE_STRING_SET=

DIR_RENDER_TMP=
F_BG_TMP_0=
F_BG_TMP=
F_QUOTE_TMP=
F_SOURCE_TMP=
F_TEXT_TMP=
F_RENDER_TMP=
# Options
OPT_FORCE=
OPT_OPEN=
# Error codes
ERR_IM_QUOTE=11
ERR_IM_SOURCE=22
ERR_IM_TEXT=33

# Print help
fn_show_help() {
    cat <<EOF
$SCRIPT_NAME $VERSION
   Render a text into a pretty image.
USAGE
    $SCRIPT_NAME "{QUOTE STRING}" [OPTION]
OPTIONS
    QUOTE STRING    set text (see QUOTE STRING FORMAT) (mandatory)
    -o FILE         set output file (default: '$OUTFILE')
    -b NAME         set background color (default: '$BG_COLOR')
    -bf FILE        set background image
    -s {X}x{Y}      set size of rendered image in pixels with a 4:3 aspect ratio 
                     (e.g. 2000x1500) (default: '$SIZE')
                    NOTE: a size larger than 3000x2250 is not recommended
    -fontq {PATH|NAME} 
    -fonts {PATH|NAME}
                    set font for quote and source with path to font file or name
                     (default: '$FONT_QUOTE', '$FONT_SOURCE')
    -c COLOR
                    set font color with hexadecimal code (e.g. "#FF00FF"), RGB
                     values (e.g. "rgb(255,0,123)") or ImageMagick color
                     (default: '$FONT_COLOR')
                    NOTE: always put quotes around this argument
    -f              force overwrite of output file (default: no)
    -h, --help      display this help
    --open          open rendered image file via \`xdg-open\`
    --list-fonts    show list of available fonts via \`convert -list font\`
    --list-colors   show list of available colors via \`convert -list color\`
QUOTE STRING FORMAT
    The text of a quote is parsed from a string formatted as follows:
        {quote}@{source}
    Examples:
        "Désormais, la fête à proportion de l'ennui spectaculaire qui suinte de tous les pores des espaces du fétichisme de la marchandise est partout puisque la vraie joie y est absolument et universellement déficiente à mesure que progresse la crise permanente de la jouissance véridique.@Francis Cousin, L'Être contre l’Avoir"
	"La domination consciente de l’histoire par les hommes qui la font, voilà tout le projet révolutionnaire.@Internationale Situationniste, De la Misère en Milieu Étudiant (1966)"
EXAMPLE
    $SCRIPT_NAME "The Capital is really like, shit bruh, I swear!@Karlos Marakas to Fredo Engeles, in a bar"\\
        -bf my_bg.png -c pink2 -fontq Gentium -fonts my_font.otf -s 2000x1500 \\
        -o quote.png -f
EOF
}

fn_print_params() {
	cat 1>&2 << EOF
 QUOTE_STRING_SET $QUOTE_STRING_SET
 QUOTE_STRING     $QUOTE_STRING
 BG               $BG
 FONT_QUOTE       $FONT_QUOTE
 FONT_SOURCE      $FONT_SOURCE
 FONT_COLOR       $FONT_COLOR

 OPT_FORCE        $OPT_FORCE
 OPT_OPEN         $OPT_RESET

 OUTFILE          $OUTFILE
 SIZE             $SIZE

 DIR_RENDER_TMP   $DIR_RENDER_TMP
 F_BG_TMP_0       $F_BG_TMP_0
 F_BG_TMP         $F_BG_TMP
 F_ QUOTE_TMP     $F_QUOTE_TMP
 F_ SOURCE_TMP    $F_SOURCE_TMP
 F_ TEXT_TMP      $F_TEXT_TMP
 F_ RENDER_TMP    $F_RENDER_TMP
EOF
}
# Check full quote string was set
fn_check_quote_string_set() {
	[[ $QUOTE_STRING_SET ]] || return
}
# Check full quote string format
fn_check_quote_string() {
	[[ "$QUOTE_STRING" =~ .+@.+ ]] || return
}
# Check bg file
fn_check_bg_file() {
	if [[ ! -f "$BG_FILE" ]]; then
		return 1
	else
		identify "$BG_FILE" 2>/dev/null 1>/dev/null || return
	fi
}
# Check font color
fn_check_font_color() {
	## Font color: is ! hex?
	if [[ ! "$FONT_COLOR" =~ ^\#[A-Fa-f0-9]{6}$ ]]; then
		## Font color: is ! rgb(...)?
		if [[ ! "$FONT_COLOR" =~ ^rgb\([0-9]{1,3},[0-9]{1,3},[0-9]{1,3}\)$ ]]; then
			## Font color: is ! IM color?
			convert -list color | fgrep -w "$FONT_COLOR" || return
		fi
	fi
}
# Check font files/names 
fn_check_fonts() {
	for F in "$FONT_QUOTE" "$FONT_SOURCE"; do
		if [[ ! -f "$F" ]]; then
			# not perfect as it matches "(Font: Unna)" in "Font: Unna-Bold"
			convert -list font | fgrep -w "Font: $F" || return 1
		fi
	done
}
# Check arguments (self-contained)
fn_check_args() {
	fn_check_quote_string_set
	[[ $? -eq 0 ]] || syl_exit_err "please specify quote string (format: \"{quote}@{source}\")" $ERR_WRONG_ARG
	fn_check_quote_string
	[[ $? -eq 0 ]] || syl_exit_err "invalid quote string '$QUOTE_STRING'\n\tformat: \"{quote}@{source}\"" $ERR_WRONG_ARG
	[[ $BG_FILE ]] && {
		fn_check_bg_file
		[[ $? -eq 0 ]] || syl_exit_err "invalid background image '$BG_FILE'" $ERR_WRONG_ARG
	}
	fn_check_font_color
	[[ $? -eq 0 ]] || syl_exit_err "invalid font color '$FONT_COLOR'" $ERR_WRONG_ARG
	fn_check_fonts
	[[ $? -eq 0 ]] || syl_exit_err "invalid font '$FONT_QUOTE' or '$FONT_SOURCE'" $ERR_WRONG_ARG
}
# Make bg canvas
fn_make_bg() {
	# Make bg with provided img
	[[ $BG_FILE ]] && {
		cp $V -f "$BG_FILE" "$F_BG_TMP_0" || syl_exit_err "can't copy '$BG_FILE' to '$F_BG_TMP_0'" $ERR_NO_FILE
		convert $V_IM "$F_BG_TMP_0" -resize "$SIZE^" -gravity "center" -crop "$SIZE+0+0" +repage "$F_BG_TMP"
		return
	}
	# Make bg with IM
	convert $V_IM xc:${BG_COLOR} -geometry $SIZE "$F_BG_TMP"
	return
}
# Make quote canvas
# $1: quote string, $2: enables guillemets (opt)
fn_make_text_quote() {
	local QUOTE="$1"
	[[ $2 ]] && QUOTE="«\ $1\ »"
	convert $V_IM -background none -fill "$FONT_COLOR" -size 3000x1800 -font "$FONT_QUOTE"  -gravity west -bordercolor none -border 5%   caption:"$QUOTE" "$F_QUOTE_TMP"
	return
}
# Make source canvas
# $1: source string
fn_make_text_source() {
	convert $V_IM -background none -fill "$FONT_COLOR" -size 2000x450  -font "$FONT_SOURCE" -gravity east -bordercolor none -border 25%  caption:"$1"      "$F_SOURCE_TMP"
	return
}
# Make full text canvas
fn_make_text() {
	local QUOTE=
	local SOURCE=
	fn_parse_quote "$QUOTE_STRING"
	QUOTE="$RET"
	fn_parse_source "$QUOTE_STRING"
	SOURCE="$RET"

	fn_make_text_quote "$QUOTE" 1
	[[ $? -eq 0 ]] || syl_exit_err "can't make quote text out of \"$QUOTE\"" $ERR_IM_QUOTE
	fn_make_text_source "$SOURCE"
	[[ $? -eq 0 ]] || syl_exit_err "can't make source text out of \"$SOURCE\"" $ERR_IM_SOURCE
	convert $V_IM -background none -fill none -gravity east "$F_QUOTE_TMP" "$F_SOURCE_TMP" -append -resize "$SIZE" "$F_TEXT_TMP"
	return
}
# Merge text canvas and background canvas
fn_compose() {
	composite "$F_TEXT_TMP" "$F_BG_TMP" "$F_RENDER_TMP"
	return
}


main() {
	syl_need_cmd "montage"
	syl_need_cmd "composite"
	syl_need_cmd "convert"

	# PARSE ARGUMENTS
	[[ $# -eq 0 ]] && 	{ fn_show_help ; exit ; }
	while [[ $# -ge 1 ]]; do
		case "$1" in
			"-h"|"--help")
				fn_show_help
				exit
				;;
			"-o")
				[[ $2 ]] || syl_exit_err "missing argument to '-o'" $ERR_WRONG_ARG
				shift
				OUTFILE="$1"
				;;
			"-b")
				[[ $2 ]] || syl_exit_err "missing argument to '-b'" $ERR_WRONG_ARG
				shift
				BG_COLOR="$1"
				;;
			"-bf")
				[[ $2 ]] || syl_exit_err "missing argument to '-bf'" $ERR_WRONG_ARG
				shift
				BG_FILE="$1"
				;;
			"-s")
				[[ $2 ]] || syl_exit_err "missing argument to '-s'" $ERR_WRONG_ARG
				shift
				SIZE="$1"
				;;
			"-fontq")
				[[ $2 ]] || syl_exit_err "missing argument to '-fontq'" $ERR_WRONG_ARG
				shift
				FONT_QUOTE="$1"
				;;
			"-fonts")
				[[ $2 ]] || syl_exit_err "missing argument to '-fonts'" $ERR_WRONG_ARG
				shift
				FONT_SOURCE="$1"
				;;
			"-c")
				[[ $2 ]] || syl_exit_err "missing argument to '-c'" $ERR_WRONG_ARG
				shift
				FONT_COLOR="$1"
				;;
			"-f")
				OPT_FORCE=1
				;;
			"--open")
				OPT_OPEN=1
				;;
			"--list-fonts")
				convert -list font
				;;
			"--list-colors")
				convert -list color
				;;
			*)
				[[ $QUOTE_STRING_SET ]] && msyl_say "[Warning] Quote string was reset."
				QUOTE_STRING_SET=1
				QUOTE_STRING="$1"
				;;
		esac	# --- end of case ---
		# Delete $1
		shift
	done

	# CHECKING ARGS VALIDITY
	fn_check_args
	exit

	[[ $DEBUG ]] && {
		V="-v"
		V_IM="-verbose"
		fn_print_params
	}

	syl_mktemp_dir "situation"
	DIR_RENDER_TMP="$RET"
	trap 'rm -rfv $DIR_RENDER_TMP' EXIT

	msyl_say "Making background..."
	fn_make_bg
	msyl_say "Making text..."
	fn_make_text
	[[ $? -eq 0 ]] || syl_exit_err "can't make text out of '$F_QUOTE_TMP' and '$F_SOURCE_TMP'" $ERR_IM_TEXT
	msyl_say "Merging to $OUTFILE..."
	fn_compose
	mv $V -f "$F_RENDER_TMP" "$OUTFILE" || syl_exit_err "can't 'mv' '$F_RENDER_TMP' to '$OUTFILE'" $ERR_NO_FILE

	[[ $OPT_OPEN ]] && xdg-open "$OUTFILE"
	msyl_say "All done!"
}

main "$@"
