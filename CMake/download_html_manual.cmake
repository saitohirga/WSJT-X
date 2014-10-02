#
# CMake script to fetch the current HTML manual
#
message (STATUS "file: ${URL}/${NAME}")
file (
  DOWNLOAD ${URL}/${NAME} contrib/${NAME}
  TIMEOUT 120
  STATUS manual_STATUS
  LOG manual_LOG
  SHOW_PROGRESS
  )
list (GET manual_STATUS 0 manual_RC)
if (manual_RC)
  message (WARNING "${manual_STATUS}")
  message (FATAL_ERROR "${manual_LOG}")
endif (manual_RC)
