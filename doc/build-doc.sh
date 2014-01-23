#!/usr/bin/env bash
# Title           : build-doc.sh
# Description     : WSJT-X Documentation build script
# Author          : KI7MT
# Email           : ki7mt@yahoo.com
# Date            : JAN-21-2014
# Version         : 0.2
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
    echo -e ${yellow}'Building Without TOC'${no_col}
    $c_asciidoc -o wsjtx-main.html $src_dir/wsjtx-main.txt
    echo -e ${green}'. Finished wsjtx-main.html'${no_col}
}

function build_toc1() { # top toc
    echo -e ${yellow}'Building with Top TOC'${no_col}
    $c_asciidoc -a toc -o wsjtx-main-toc1.html $src_dir/wsjtx-main.txt
    echo -e ${green}'. Finished wsjtx-main-toc1.html'${no_col}
}

function build_toc2() { # left toc
    echo -e ${yellow}'Building with Left TOC'${no_col}
    $c_asciidoc -a toc2 -o wsjtx-main-toc2.html $src_dir/wsjtx-main.txt
    echo -e ${green}'. Finished wsjtx-main-toc2.html'${no_col}
}

# start the main script
clear
# Hard coded version info to build outside of source tree.
echo -e ${yellow}"*** Building WSJT-X User Guide for:" ${cyan}$doc_version${no_col}${yellow}" ***\n" ${no_col}

# without TOC
if [[ $1 = "" ]]
  then
    build_no_toc

# top TOC
elif [[ $1 = "toc1" ]]
  then
    build_toc1

# left TOC
elif [[ $1 = "toc2" ]]
  then
  build_toc2

# all toc versions
elif [[ $1 = "all" ]]
  then
    echo -e ${yellow}'Building all TOC versions'${no_col}
    echo
    build_no_toc
    echo
    build_toc1
    echo
    build_toc2

# if something other than "", toc1, toc2 or all is entered as $1 display usage
# message and exit. this should be re-written to redirect the user to select
# 1 of 4 proper options v.s. exiting.
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

# build the rig template page
  echo
  echo -e ${yellow}'Building Rig Template'${no_col}
  $c_asciidoc -o rigtemplate.html $src_dir/rigtemplate.txt
  echo -e ${green}'. Finished'${no_col}
 
# build the rig sheets
# this section will should be modified to loop through rig template(s) either by
# name or directory ./rig/rig_* could be used.
  echo
  echo -e ${yellow}'Building Rig Configuration Sheets'${no_col}
  $c_asciidoc -o yaesu.html $src_dir/yaesu.txt
  echo -e ${green}'. Finished'${no_col}
  echo
  echo -e ${yellow}'All HTML files have been saved to:'${no_col}${cyan} "$base_dir" ${no_col}
  echo
exit 0

