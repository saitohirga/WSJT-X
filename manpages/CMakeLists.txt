set (ASCIIDOC_MANS
  man1/wsjtx.1.txt
  )

find_program (A2X_EXECUTABLE NAMES a2x a2x.py)
if (NOT A2X_EXECUTABLE)
  message (SEND_ERROR "Failed to find a2x.")
endif ()
find_program (GZIP_EXECUTABLE NAMES gzip)
if (NOT GZIP_EXECUTABLE)
  message (SEND_ERROR "Failed to find gzip.")
endif ()
find_program (SED_EXECUTABLE NAMES sed)
if (NOT SED_EXECUTABLE)
  message (SEND_ERROR "Failed to find sed.")
endif ()

set (XSLTPROC_OPTS 
  "-param man.endnotes.list.enabled 0 -param man.endnotes.are.numbered 0"
  )
set (A2X_OPTS
  --format=manpage
  --xsltproc-opts=${XSLTPROC_OPTS}
  --doctype=manpage
  --no-xmllint
  )

set (MANPAGES)
if (A2X_EXECUTABLE AND GZIP_EXECUTABLE)
  file (MAKE_DIRECTORY man)
  foreach (f IN LISTS ASCIIDOC_MANS)
    get_filename_component (d "${f}" PATH)
    string (SUBSTRING "${d}" 3 -1 section)
    if (NOT section MATCHES "[1-9]")
      message (SEND_ERROR "Invalid man section ${section} in ${f}")
    endif (NOT section MATCHES "[1-9]")
    get_filename_component (filename "${f}" NAME_WE)
    set (f "${CMAKE_CURRENT_SOURCE_DIR}/${f}")
    set (d "man/${d}")
    set (o "${d}/${filename}.${section}")
    add_custom_command (OUTPUT "${o}.gz"
      COMMAND ${CMAKE_COMMAND} ARGS -E make_directory "${d}"
      COMMAND ${A2X_EXECUTABLE} ARGS ${A2X_OPTS} -D "${d}" "${f}"
      COMMAND ${GZIP_EXECUTABLE} ARGS -r --force --best "${o}"
      COMMAND ${SED_EXECUTABLE} ARGS --in-place "s@.so @.so man${section}/@" "${d}/*.${section}"
      COMMAND ${GZIP_EXECUTABLE} ARGS -r --force --best "${d}/*.${section}"
      DEPENDS "${f}"
      COMMENT "Generating ${o}.gz"
      )
    list (APPEND MANPAGES "${o}.gz")
  endforeach ()

  install (
    DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/man
    DESTINATION ${WSJT_MANPAGE_DESTINATION}
    )
endif (A2X_EXECUTABLE AND GZIP_EXECUTABLE)

add_custom_target (manpages DEPENDS ${MANPAGES})
