#!/usr/bin/env bash
# Title           : build-doc.sh
# Description     : WSJT-X Documentation build script
# Author          : KI7MT
# Email           : ki7mt@yahoo.com
# Date            : JAN-24-2014
# Version         : 0.3
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
doc_version="1.2.2"

# build functions
function build_no_toc() { # no toc
    echo -e ${yellow}'Building Main With No TOC'${no_col}
    $c_asciidoc -o wsjtx-main.html $src_dir/wsjtx-main.adoc
    echo -e ${green}'.. wsjtx-main.html'${no_col}
}

function build_toc1() { # top toc
    echo -e ${yellow}'Building Main with Top TOC'${no_col}
    $c_asciidoc -a toc -o wsjtx-main-toc1.html $src_dir/wsjtx-main.adoc
    echo -e ${green}'.. wsjtx-main-toc1.html'${no_col}
}

function build_toc2() { # left toc
    echo -e ${yellow}'Building Main with Left TOC'${no_col}
    $c_asciidoc -a toc2 -o wsjtx-main-toc2.html $src_dir/wsjtx-main.adoc
    echo -e ${green}'.. wsjtx-main-toc2.html'${no_col}
}

function build_support_pages() { # build all remaining pages
  echo
  echo -e ${yellow}'Building Support Pages'${no_col}
  $c_asciidoc -o rig-config-main.html $src_dir/rig-config-main.adoc
  echo -e ${green}'.. rig-config-main.html'${no_col}

  # setup rig file array
  declare -a subpage=('adat' 'alinco' 'aor' 'drake' 'electro' 'flexrad' 'icom' \
'kenwood' 'softrock' 'tentec' 'yaesu')
  
  # loop through rig-config pages
  for rig in "${subpage[@]}"
  do
    $c_asciidoc -a toc2 -o rig-config-$rig.html $src_dir/rig-config-$rig.adoc
    echo -e ${green}".. rig-config-$rig.html"${no_col}
  done

  $c_asciidoc -o rig-config-template.html $src_dir/rig-config-template.adoc
  echo -e ${green}'.. rig-config-template.html'${no_col}

  $c_asciidoc -a toc2 -o quick-reference.html $src_dir/quick-reference.adoc
  echo -e ${green}'.. quick-reference.html'${no_col}
}

# start the main script
clear
echo -e ${yellow}"*** Building WSJT-X User Guide for:" ${cyan}$doc_version\
${no_col}${yellow}" ***\n" ${no_col}

# without TOC
if [[ $1 = "" ]]
  then
    build_no_toc
    build_support_pages

# top TOC
elif [[ $1 = "toc1" ]]
  then
    build_toc1
    build_support_pages

# left TOC
elif [[ $1 = "toc2" ]]
  then
  build_toc2
  build_support_pages

# all toc versions
elif [[ $1 = "all" ]]
  then
    build_no_toc
    build_toc1
    build_toc2
    build_support_pages

# Usage: if something other than "", toc1, toc2 or all is entered as $1 display usage
# message and exit.
#
# To-Do: this should be re-written to redirect the user to select
# 1 of 4 proper options v.s. exiting. Future version should provide
# a terminal GUI, Whiptail, Dialog, Zenity etc.
else
    clear
    echo -e ${red}" * INPUT ERROR *\n"${no_col}
    echo 'Script Usage: build-doc.sh [ option ]'
    echo
    echo 'For with No TOC: ' ./$script_name
    echo 'For with Top TOC: './$script_name 'toc1'
    echo 'For with Left TOC: './$script_name 'toc2'
    echo 'For All Versions: ' ./$script_name 'all'
    echo
    echo Please re-enter using the examples above.
    echo
    exit 1
fi
  echo
  echo -e ${yellow}'All HTML files have been saved to:'${no_col}${cyan} "$base_dir" ${no_col}
  echo

exit 0

