#!/usr/bin/env bash
# Title           : build-doc.sh
# Description     : WSJT-X Documentation build script
# Author          : KI7MT
# Email           : ki7mt@yahoo.com
# Date            : FEB-02-2014
# Version         : 0.5
# Usage           : ./build-doc.sh [ option ]
# Notes           : requires asciidoc, source-highlight
#==============================================================================

# exit on error
# AsciiDoc "not found warnings" will not force the script to exit
set -e

# Trap Ctril+C, Ctrl+Z and quit signals
# TO-DO: Add additional clean-exit function
trap '' SIGINT SIGQUIT SIGTSTP

#add some color
red='\033[01;31m'
green='\033[01;32m'
yellow='\033[01;33m'
cyan='\033[01;36m'
no_col='\033[01;37m'

# misc var's
base_dir=$(pwd)
src_dir="$base_dir/source"
c_asciidoc="asciidoc -b xhtml11 -a max-width=1024px"    
script_name=$(basename $0)
doc_version="1.3"

#######################
# set-up functions
#######################

# build with no table of contents
function build_no_toc() { # no toc
    echo -e ${yellow}'Building Main With No TOC'${no_col}
    $c_asciidoc -o wsjtx-main.html $src_dir/wsjtx-main.adoc
    echo -e ${green}'.. wsjtx-main.html'${no_col}
}

# build with top table of contents
function build_toc1() {
    echo -e ${yellow}'Building Main with Top TOC'${no_col}
    $c_asciidoc -a toc -o wsjtx-main-toc1.html $src_dir/wsjtx-main.adoc
    echo -e ${green}'.. wsjtx-main-toc1.html'${no_col}
}

# build with left table of contents
function build_toc2() {
    echo -e ${yellow}'Building Main with Left TOC'${no_col}
    $c_asciidoc -a toc2 -o wsjtx-main-toc2.html $src_dir/wsjtx-main.adoc
    echo -e ${green}'.. wsjtx-main-toc2.html'${no_col}
} # end left toc

# build all table of content versions
function build_support_pages() {
	echo
	echo -e ${yellow}'Building Rig Pages'${no_col}
	$c_asciidoc -o rig-config-main.html $src_dir/rig-config-main.adoc
	echo -e ${green}'.. rig-config-main.html'${no_col}

# setup rig file array
	declare -a rig_page_ary=('adat' 'alinco' 'aor' 'drake' 'elecraft' 'flexrad' 'icom' \
'kenwood' 'softrock' 'tentec' 'yaesu')
  
# loop through rig-config pages
	for rig in "${rig_page_ary[@]}"
	do
		$c_asciidoc -a toc2 -o rig-config-$rig.html $src_dir/rig-config-$rig.adoc
		echo -e ${green}".. rig-config-$rig.html"${no_col}
	done

	$c_asciidoc -o rig-config-template.html $src_dir/rig-config-template.adoc
	echo -e ${green}'.. rig-config-template.html'${no_col}
} # end all toc version

# build quick-reference guide
function build_quick_ref() {
  echo -e ${yellow}'Building Quick Reference Guide'${no_col}
  $c_asciidoc -a toc2 -o quick-reference.html $src_dir/quick-reference.adoc
  echo -e ${green}'.. quick-reference.html'${no_col}
} # end quick-ref

# build dev-guide
function build_dev_guide() {
  echo -e ${yellow}'Building Development Guide'${no_col}
  $c_asciidoc -a toc2 -o dev-guide.html $src_dir/dev-guide.adoc
  echo -e ${green}'.. dev-guide.html'${no_col}
} # end dev-guide

# help menu options
function help_menu() {
	clear
    echo -e ${green}"BUILD SCRIPT HELP NMENU\n"${no_col}
    echo 'USAGE: build-doc.sh [ option ]'
	echo
	echo 'OPTIONS: toc1 toc2 all dev-guide quick-ref help'
	echo
    echo -e ${yellow}'WSJT-X User Guide Options:'${no_col}
    echo ' [1] No Table of Contents'
    echo ' [2] Top Table of Contents '
    echo ' [3] Left Table of Contents'
    echo ' [4] Build All Guide Versions'
	echo -e ${yellow}"\nSingle Guide Builds"${no_col}
	echo ' [5] Development Guide'
	echo ' [6] Quick Reference Guide'
    echo ' [0] Exit'
	echo
}
function custom_wording() {
clear
echo -e ${yellow}"WSJT-X Documentation "${cyan}'v'$doc_version"\n" ${no_col}
}

#######################
# start the main script
#######################

# declare build array's
declare -a no_toc_ary=('custom_wording' 'build_no_toc' 'build_support_pages')
declare -a top_toc_ary=('custom_wording' 'build_toc1' 'build_support_pages')
declare -a left_toc_ary=('custom_wording' 'build_toc2' 'build_support_pages')
declare -a all_docs_ary=('custom_wording' 'build_no_toc' 'build_toc1' 'build_toc2' \
'build_quick_ref' 'build_dev_guide' 'build_support_pages')

# start builds
clear
echo -e ${yellow}"WSJT-X Documentation "${cyan}'v'$doc_version"\n"${no_col}

# build options for direct command line entry: ./build-doc.sh [ option ]
# build without table of contents
if [[ $1 = "" ]]
	then
		for f in "${no_toc_ary[@]}"; do $f; done

# build top table of contents
elif [[ $1 = "toc1" ]]
	then
		for f in "${top_toc_ary[@]}"; do $f; done

# build left table of contents
elif [[ $1 = "toc2" ]]
	then
 		for f in "${left_toc_ary[@]}"; do $f; done

# build all table of content versions
elif [[ $1 = "all" ]]
	then
 		for f in "${all_docs_ary[@]}"; do $f; done

# build quick-reference only
elif [[ $1 = "quick-ref" ]]
	then
	build_quick_ref

# build dev-guide only
elif [[ $1 = "dev-guide" ]]
	then
	build_dev_guide

# For HELP and undefined option entries
# NOTE: The case $SELECTIOIN should mirror the if [ .. ] statements
# to allow for menu and direct call builds
else
	while [ 1 ]
	do
		help_menu
		read -p "Enter Selection [ 1-6 or 0 to Exit ]: " SELECTION
		case "$SELECTION" in
			"1") # no table of contents build
				clear
				for f in "${no_toc_ary[@]}"; do $f; done
				exit 0
				;;
			"2") # top table of contents build
				for f in "${top_toc_ary[@]}"; do $f; done
				exit 0
				;;
			"3")
				for f in "${left_toc_ary[@]}"; do $f; done
				exit 0
				;;
			"4")
				for f in "${all_docs_ary[@]}"; do $f; done
				exit 0
				;;
			"5")
				build_dev_guide
				exit 0
				;;
			"6")
				build_quick_ref
				exit 0
				;;
			"0")
				trap - SIGINT SIGQUIT SIGTSTP
				exit 0
				;;
		esac
	done
fi
  echo
  echo -e ${yellow}'All HTML files saved to:'${no_col}${cyan} "$base_dir" ${no_col}
  echo
exit 0
