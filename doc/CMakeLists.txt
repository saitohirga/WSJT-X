set (common_SRCS
  common/communication.adoc
  common/license.adoc
  common/links.adoc
  )

set (UG_SRCS
  user_guide/acknowledgements.adoc
  user_guide/compiling.adoc
  user_guide/config-details.adoc
  user_guide/controls-functions-center.adoc
  user_guide/controls-functions-left.adoc
  user_guide/controls-functions-main-window.adoc
  user_guide/controls-functions-menus.adoc
  user_guide/controls-functions-messages.adoc
  user_guide/controls-functions-status-bar.adoc
  user_guide/controls-functions-wide-graph.adoc
  user_guide/coop-prgrms.adoc
  user_guide/cooperating-programs.adoc
  user_guide/faq.adoc
  user_guide/font-sizes.adoc
  user_guide/install-from-source.adoc
  user_guide/install-linux.adoc
  user_guide/install-mac.adoc
  user_guide/install-windows.adoc
  user_guide/introduction.adoc
  user_guide/jt65-jt9-differences.adoc
  user_guide/jt65-protocol.adoc
  user_guide/jt9-protocol.adoc
  user_guide/logging.adoc
  user_guide/make-qso.adoc
  user_guide/new_features.adoc
  user_guide/platform-dependencies.adoc
  user_guide/rig-config-adat.adoc
  user_guide/rig-config-alinco.adoc
  user_guide/rig-config-aor.adoc
  user_guide/rig-config-drake.adoc
  user_guide/rig-config-elecraft.adoc
  user_guide/rig-config-flexrad.adoc
  user_guide/rig-config-icom.adoc
  user_guide/rig-config-kenwood.adoc
  user_guide/rig-config-main.adoc
  user_guide/rig-config-softrock.adoc
  user_guide/rig-config-template.adoc
  user_guide/rig-config-tentec.adoc
  user_guide/rig-config-yaesu.adoc
  user_guide/settings-audio.adoc
  user_guide/settings-colors.adoc
  user_guide/settings-frequencies.adoc
  user_guide/settings-general.adoc
  user_guide/settings-radio.adoc
  user_guide/settings-reporting.adoc
  user_guide/settings-txmacros.adoc
  user_guide/support.adoc
  user_guide/system-requirements.adoc
  user_guide/transceiver-setup.adoc
  user_guide/tutorial-example1.adoc
  user_guide/tutorial-example2.adoc
  user_guide/tutorial-main-window.adoc
  user_guide/tutorial-wide-graph-settings.adoc
  user_guide/tx-rx.adoc
  user_guide/utilities.adoc
  user_guide/vhf-features.adoc
  user_guide/wsjtx-main.adoc
  user_guide/wspr.adoc
  )

set (UG_IMGS
  user_guide/images/130610_2343-wav-80.png
  user_guide/images/band-settings.png
  user_guide/images/colors.png
  user_guide/images/decode-menu.png
  user_guide/images/decodes.png
  user_guide/images/file-menu.png
  user_guide/images/freemsg.png
  user_guide/images/help-menu.png
  user_guide/images/jtalert.png
  user_guide/images/keyboard-shortcuts.png
  user_guide/images/log-qso.png
  user_guide/images/MacAppMenu.png
  user_guide/images/main-ui-1.5.png
  user_guide/images/main-ui-controls.png
  user_guide/images/misc-controls-center.png
  user_guide/images/misc-main-ui.png
  user_guide/images/mode-menu.png
  user_guide/images/new-msg-box.png
  user_guide/images/psk-reporter.png
  user_guide/images/r3666-config-screen-80.png
  user_guide/images/r3666-main-ui-80.png
  user_guide/images/r4148-txmac-ui.png
  user_guide/images/RadioTab.png
  user_guide/images/reporting.png
  user_guide/images/save-menu.png
  user_guide/images/settings-audio.png
  user_guide/images/settings-frequencies.png
  user_guide/images/settings-general.png
  user_guide/images/setup-menu.png
  user_guide/images/special-mouse-commands.png
  user_guide/images/status-bar-a.png
  user_guide/images/traditional-msg-box.png
  user_guide/images/tx-macros.png
  user_guide/images/view-menu.png
  user_guide/images/wide-graph-controls.png

)

find_package (PythonInterp 2.4 REQUIRED)
if (PYTHON_VERSION_STRING VERSION_GREATER 2.9.9)
  message (FATAL_ERROR "The asciidoc package requires a Python version less than 3

Use CMAKE_PREFIX_PATH to point to an earlier version or install one,
you can also skip building the documentation by switching the option
WSJT_GENERATE_DOCS to OFF.")
endif (PYTHON_VERSION_STRING VERSION_GREATER 2.9.9)

find_program (ASCIIDOC_EXECUTABLE NAMES asciidoc asciidoc.py)
if (NOT ASCIIDOC_EXECUTABLE)
  message (FATAL_ERROR "Asciidoc is required to build the documentation

Building the documenation may optionally be tured off by setting the CMake
option WSJT_GENERATE_DOCS to OFF.")
endif (NOT ASCIIDOC_EXECUTABLE)

include (CMakeParseArguments)

# generate an HTML document from asciidoc text files(s)
#
# HTML - variable for output file ${CMAKE_CURRENT_BINARY_DIR}/`$basename ${SOURCE}`.html
# SOURCE - top level asciidoc file
# ASCIIDOC_OPTIONS - asciidoc command options
# DEPENDS - dependent files
function (html_document)
  cmake_parse_arguments (args "" "SOURCE;HTML" "ASCIIDOC_OPTIONS;DEPENDS" ${ARGN})
  get_filename_component (_output_name_we ${args_SOURCE} NAME_WE)
  get_filename_component (_path ${args_SOURCE} PATH)
  set (_doc_file ${CMAKE_CURRENT_BINARY_DIR}/${_output_name_we}.html)
  add_custom_command (
    OUTPUT ${_doc_file}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${path}
    COMMAND ${PYTHON_EXECUTABLE} ARGS ${ASCIIDOC_EXECUTABLE} ${args_ASCIIDOC_OPTIONS} --out-file=${CMAKE_CURRENT_BINARY_DIR}/${_output_name_we}.html ${args_SOURCE}
    DEPENDS ${args_DEPENDS}
    COMMENT "Generating ${_doc_file}"
    )
  set (${args_HTML} ${_doc_file} PARENT_SCOPE)
endfunction (html_document)

configure_file (wsjtx.conf.in wsjtx.conf.out)
# copy the file to the final location only if the generated output
# changes reduces needless rebuilds
execute_process (
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
  COMMAND ${CMAKE_COMMAND} -E copy_if_different wsjtx.conf.out wsjtx.conf
  )

html_document(
  HTML user_guide
  SOURCE user_guide/wsjtx-main.adoc
  ASCIIDOC_OPTIONS -a data-uri -a toc2 -a max-width=1024px --conf-file=${CMAKE_CURRENT_BINARY_DIR}/wsjtx.conf --backend=xhtml11 --theme wsjt
  DEPENDS ${common_SRCS} ${UG_SRCS} ${UG_IMGS} wsjtx.conf.in theme/wsjt/wsjt.css
  )
add_custom_target (docs ALL DEPENDS ${user_guide})

install (FILES
  ${user_guide}
  DESTINATION ${WSJT_SHARE_DESTINATION}/${WSJT_DOC_DESTINATION}
  RENAME ${PROJECT_MANUAL}
  #COMPONENT runtime
  )
