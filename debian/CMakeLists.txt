find_program (GZIP_EXECUTABLE NAMES gzip)

string (TIMESTAMP ts "%w, %d [%m] %Y %H:%M:%S +0000" UTC)

set (__days Sun Mon Tue Wed Thu Fri Sat)
string (SUBSTRING ${ts} 0 1 __index)
list (GET __days ${__index} __day)
string (REPLACE "${__index}," "${__day}," ts ${ts})

set (__months Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)
string (SUBSTRING ${ts} 9 2 __month_index)
math (EXPR __index "${__month_index} - 1")
list (GET __months "${__index}" __month)
string (REPLACE "[${__month_index}]" "${__month}" ts ${ts})

configure_file (
  "${CMAKE_CURRENT_SOURCE_DIR}/changelog.in"
  "${CMAKE_CURRENT_BINARY_DIR}/changelog"
  @ONLY)

add_custom_target (debian
  COMMAND ${GZIP_EXECUTABLE} -cf9 changelog > changelog.gz
  DEPENDS changelog.in
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
  COMMENT "Compressing Debian changelog"
  )

configure_file (
  "${CMAKE_CURRENT_SOURCE_DIR}/copyright.in"
  "${CMAKE_CURRENT_BINARY_DIR}/copyright"
  @ONLY)

install (FILES
  ${CMAKE_CURRENT_BINARY_DIR}/changelog.gz
  ${CMAKE_CURRENT_BINARY_DIR}/copyright
  DESTINATION ${WSJT_DOC_DESTINATION}
  COMPONENT Debian
  )
