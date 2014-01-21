#!/usr/bin/env bash
#
# Part of the wsjtx-doc project
# Builds all *.txt files found in $(PWD)/source

# exit on any error
set -e

# set script path's
base_dir=$(pwd)
src_dir="$base_dir/source"
style_dir="$base_dir/style"
log_dir="$base_dir/logs"

# style sheet selection
main_style=asciidoc.css
toc2_style=toc2.css

# This is temporary. Final version will loop through a directory of files
c_asciidoc="asciidoc -b xhtml11 -a max-width=1024px"
clear
#echo Building Main Page HTML
#echo .. Main Page Without TOC
#$c_asciidoc -o wsjtx-main.html ${src_dir}/wsjtx-main.txt
#echo .. Done

echo .. Main Page With TOC
$c_asciidoc -a toc -o wsjtx-main-toc.html ${src_dir}/wsjtx-main.txt
echo .. Done

#echo .. Main Page With TOC2
#$c_asciidoc -a toc2 -o wsjtx-main-toc2.html ${src_dir}/wsjtx-main.txt
#echo .. Done

echo Building Rig Configuration Sheets
echo Building Yaesu
$c_asciidoc -o yaesu.html ${src_dir}/yaesu.txt
echo .. Done
echo Building regtemplate
$c_asciidoc -o rigtemplate.html ${src_dir}/rigtemplate.txt
echo Done
echo
echo All HTML docs have been saved to "$base_dir"

exit 0


