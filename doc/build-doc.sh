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
set -e

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

# declare build array's
declare -a no_toc_ary=('head_wording' 'build_no_toc')
declare -a top_toc_ary=('head_wording' 'build_toc1')
declare -a left_toc_ary=('head_wording' 'build_toc2')
declare -a all_docs_ary=('head_wording' 'build_no_toc' 'build_toc1' 'build_toc2' \
'build_quick_ref' 'build_dev_guide')
declare -a web_package_ary=('package_wording' 'build_toc2')

#######################
# clean-exit
#######################

function clean_exit() {
	clear
	echo -e ${yellow}'Signal caught, cleaning up and exiting.'${no_col}
	sleep 1
	[ -d "$base_dir/tmp" ] && rm -r $base_dir/tmp
	echo -e ${yellow}'. Done'${no_col}
	exit 0
}

# Trap Ctrl+C, Ctrl+Z and quit signals
trap clean_exit SIGINT SIGQUIT SIGTSTP

#######################
# general functions
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

function head_wording() {
clear
echo -e ${yellow}"Building WSJT-X Documentation "${cyan}'v'$doc_version"\n" ${no_col}
}

function quick_ref_wording() {
clear
echo -e ${yellow}"Building Quick Reference Documentation\n"${no_col}
}

function dev_guide_wording() {
clear
echo -e ${yellow}"Building Quick Reference Documentation\n"${no_col}
}

function package_wording() {
clear
echo -e ${yellow}"Building Transfer Package\n"${no_col}
}

# help menu options
function help_menu() {
	clear
    echo -e ${green}"BUILD SCRIPT HELP MENU\n"${no_col}
    echo 'USAGE: build-doc.sh [ option ]'
	echo
	echo 'OPTIONS: toc1 toc2 all dev-guide quick-ref help web'
	echo
    echo -e ${yellow}'WSJT-X User Guide Options:'${no_col}
    echo ' [1] No Table of Contents'
    echo ' [2] Top Table of Contents '
    echo ' [3] Left Table of Contents'
    echo ' [4] All Guide Versions'
	echo -e ${yellow}"\nSingle Guide Builds"${no_col}
	echo ' [5] Development Guide'
	echo ' [6] Quick Reference Guide'
    echo ' [0] Exit'
	echo
}

# WSJT-X User Guide transfer for Joe
function build_index_html(){

# create re-direct index.html
cat << EOF > ./index.html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" 
"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">

  <head>
    <title>WSJT-X User Guide</title>
    <meta name="description" content="Software for Amateur Radio 
	Weak-Signal Communication" />
    <meta name="keywords" content="amateur radio weak signal communication K1JT 
	WSJT FSK441 JT65 JT6M" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <meta content="Joe Taylor, K1JT" name="author" />
	<meta http-equiv="refresh" content="0; 
	url=http://www.physics.princeton.edu/pulsar/K1JT/wsjtx-doc/wsjtx-main-toc2.html" />
  </head>
EOF
}

function build_transfer_package() {

[ -d ./tmp ] && rm -r ./tmp

# check if wsjtx-main-toc2.html exists
build_file="wsjtx-main-toc2.html"

if [[ $(ls -1 ./*.html 2>/dev/null | wc -l) > 0 ]]
then 
	echo "The docs's directory has previous build files"
	echo
	read -p "Would you like a clean User Guide build before packaging? [ Y/N ]: " yn
	case $yn in
	[Yy]* )
		clear
		echo "Removing old html files, and rebuilding"
		sleep 1
		rm ./*.html
		package_wording
		build_index_html
		mkdir -p ./tmp
		cp -r $base_dir/images/ $base_dir/tmp/			
		for f in "${web_package_ary[@]}"; do $f; done
		mv ./*.html $base_dir/tmp
		echo
		echo -e ${yellow}"Preparing Archive File"${no_col}
		sleep 1
		cd $base_dir/tmp && tar -czf ../wsjtx-doc.tar.gz .
		cd .. && rm -r $base_dir/tmp/
		break;;
	[Nn]* )
		clear
		echo "Ok, will package without rebuilding."
		sleep 1
		break;;
	* )
		clear
		echo "Please answer with "Y" yes or "N" No.";;
	esac
else
	# continue packaging
	package_wording
	mkdir -p ./tmp
	cp -r $base_dir/images/ $base_dir/tmp/			
	build_index_html
	for f in "${web_package_ary[@]}"; do $f; done
	cp ./*.html $base_dir/tmp
	echo
	echo -e ${yellow}"Preparing Archive File"${no_col}
	sleep 1
	cd $base_dir/tmp && tar -czf ../wsjtx-doc.tar.gz .
	cd .. && rm -r $base_dir/tmp/
fi

# check that a file was actually created
web_file="wsjtx-doc.tar.gz"
if [ -e "$web_file" ]
then
	clear
	echo
	echo -e ${green}"$PWD/$web_file is ready for transfer"
	echo
	exit 0
else
	clear
	echo
	echo -e ${red}'Whoopsie!!'
	echo -e "$web_file was not found, check for script errors."${no_col}
	echo
	exit 1
fi
}

#######################
# start the main script
#######################

# COMMAND LINE OPTIONS
if [[ $1 = "" ]]
	then
	head_wording
	for f in "${no_toc_ary[@]}"; do $f; done

# build top table of contents
elif [[ $1 = "toc1" ]]
	then
		head_wording
		for f in "${top_toc_ary[@]}"; do $f; done

# build left table of contents
elif [[ $1 = "toc2" ]]
	then
		head_wording
 		for f in "${left_toc_ary[@]}"; do $f; done

# build all table of content versions
elif [[ $1 = "all" ]]
	then
		head_wording
 		for f in "${all_docs_ary[@]}"; do $f; done

# build quick-reference only
elif [[ $1 = "quick-ref" ]]
	then
	clear
	build_quick_ref

# build dev-guide only
elif [[ $1 = "dev-guide" ]]
	then
	clear
	build_dev_guide

# bundle web_package
elif [[ $1 = "web" ]]
	then
		package_wording
		build_transfer_package

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
				exit 0
				;;
		esac
	done
fi
  echo
  echo -e ${yellow}'HTML files saved to:'${no_col}${cyan} "$base_dir" ${no_col}
  echo
  exit 0
