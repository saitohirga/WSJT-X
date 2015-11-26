set (common_SRCS
  common/communication.adoc
  common/license.adoc
  common/links.adoc
  )

set (UG_SRCS
  user_guide/docinfo.html
  user_guide/docinfo.xml
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
  user_guide/cooperating-programs.adoc
  user_guide/faq.adoc
  user_guide/font-sizes.adoc
  user_guide/implementation.adoc
  user_guide/install-from-source.adoc
  user_guide/install-linux.adoc
  user_guide/install-mac.adoc
  user_guide/install-windows.adoc
  user_guide/introduction.adoc
  user_guide/protocols.adoc
  user_guide/logging.adoc
  user_guide/make-qso.adoc
  user_guide/new_features.adoc
  user_guide/platform-dependencies.adoc
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

find_program (ASCIIDOCTOR_EXECUTABLE NAMES asciidoctor)
if (NOT ASCIIDOCTOR_EXECUTABLE)
  message (FATAL_ERROR "asciidoctor is required to build the documentation

Building the documenation may optionally be turned off by setting the CMake
option WSJT_GENERATE_DOCS to OFF.")
endif (NOT ASCIIDOCTOR_EXECUTABLE)

find_program (FOPUB_EXECUTABLE NAMES fopub)

include (CMakeParseArguments)

# generate a document from asciidoc text files(s)
#
# HTML - generate an HTML document
# PDF - generate a PDF document
# SOURCE - top level asciidoc file
# ASCIIDOCTOR_OPTIONS - asciidoctor command options
# DEPENDS - dependent files
function (document)
  cmake_parse_arguments (_args "HTML" "SOURCE;OUTPUT" "ASCIIDOCTOR_OPTIONS;PDF;DEPENDS" ${ARGN})
  get_filename_component (_source_path ${_args_SOURCE} PATH)
  get_filename_component (_source_name ${_args_SOURCE} NAME)
  get_filename_component (_output_name_we ${_args_SOURCE} NAME_WE)

  # HTML
  if (${_args_HTML})
    set (_html_file ${CMAKE_CURRENT_BINARY_DIR}/${_output_name_we}.html)
    add_custom_command (
      OUTPUT ${_html_file}
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${_source_path}
      COMMAND ${ASCIIDOCTOR_EXECUTABLE} ${_args_ASCIIDOCTOR_OPTIONS}
      -b html5
      -a VERSION_MAJOR=${WSJTX_VERSION_MAJOR}
      -a VERSION_MINOR=${WSJTX_VERSION_MINOR}
      -a VERSION_PATCH=${WSJTX_VERSION_PATCH}
      -a VERSION=${wsjtx_VERSION}
      --out-file=${_html_file} ${_source_name}
      DEPENDS ${_args_DEPENDS}
      COMMENT "Generating ${_html_file}"
      )
    list (APPEND _output_files ${_html_file})
  endif (${_args_HTML})

  # PDF
  if (_args_PDF AND EXISTS ${FOPUB_EXECUTABLE})
    set (_docbook_file ${CMAKE_CURRENT_BINARY_DIR}/${_output_name_we}.xml)
    set (_pdf_file_we ${CMAKE_CURRENT_BINARY_DIR}/${_output_name_we})
    add_custom_command (
      OUTPUT ${_docbook_file} "${_pdf_file_we} (USLetter).pdf" "${_pdf_file_we} (A4).pdf"
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${_source_path}
      COMMAND ${ASCIIDOCTOR_EXECUTABLE} ARGS ${_args_ASCIIDOCTOR_OPTIONS}
      -b docbook
      -a data-uri!
      -a VERSION_MAJOR=${WSJTX_VERSION_MAJOR}
      -a VERSION_MINOR=${WSJTX_VERSION_MINOR}
      -a VERSION_PATCH=${WSJTX_VERSION_PATCH}
      -a VERSION=${wsjtx_VERSION}
      -D ${CMAKE_CURRENT_BINARY_DIR}
      -o ${_docbook_file} ${_source_name}
      COMMAND ${FOPUB_EXECUTABLE} ARGS ${_docbook_file} ${_args_PDF} -param paper.type USLetter
      COMMAND ${CMAKE_COMMAND} ARGS -E rename ${_pdf_file_we}.pdf '${_pdf_file_we} \(USLetter\).pdf'
      COMMAND ${FOPUB_EXECUTABLE} ARGS ${_docbook_file} ${_args_PDF} -param paper.type A4
      COMMAND ${CMAKE_COMMAND} ARGS -E rename ${_pdf_file_we}.pdf '${_pdf_file_we} \(A4\).pdf'
      DEPENDS ${_args_DEPENDS}
      COMMENT "Generating ${_pdf_file_we}.pdf"
      )
    list (APPEND _output_files "${_pdf_file_we} (USLetter).pdf" "${_pdf_file_we} (A4).pdf")
  endif (_args_PDF AND EXISTS ${FOPUB_EXECUTABLE})

  set (${_args_OUTPUT} ${_output_files} PARENT_SCOPE)
endfunction (document)

document(
  HTML
  SOURCE user_guide/wsjtx-main.adoc
  OUTPUT html
  ASCIIDOCTOR_OPTIONS -d book -a data-uri -a toc=left -a max-width=1024px
  DEPENDS ${common_SRCS} ${UG_SRCS} ${UG_IMGS}
  )
document(
  PDF -param body.font.master 11 -param body.font.family "'Noto Sans, Helvetica, sans-serif'" -param title.font.family "'Noto Serif, Times New Roman, serif'" -param page.margin.inner 1cm -param page.margin.outer 1cm -param page.margin.top 0.75cm -param page.margin.bottom 0.5cm -param generate.toc 0
  SOURCE user_guide/wsjtx-main.adoc
  OUTPUT pdf
  ASCIIDOCTOR_OPTIONS -d book
  DEPENDS ${common_SRCS} ${UG_SRCS} ${UG_IMGS}
  )
add_custom_target (docs ALL DEPENDS ${html} ${pdf})

install (FILES
  ${html}
  DESTINATION ${WSJT_DOC_DESTINATION}
  RENAME ${PROJECT_MANUAL}
  #COMPONENT runtime
  )
