#
# CMake script to fetch kvasd binary for the current platform
#
set (kvasd_NAME ${URL}/${SYSTEM_NAME}/kvasd${EXECUTABLE_SUFFIX})
message (STATUS "file: ${kvasd_NAME}")

file (
  DOWNLOAD ${kvasd_NAME}.md5 contrib/kvasd${EXECUTABLE_SUFFIX}.md5
  TIMEOUT 120
  STATUS status
  LOG log
  SHOW_PROGRESS
  )
list (GET staus 0 rc)
if (rc)
  message (WARNING "${status}")
  message (FATAL_ERROR "${log}")
endif (rc)
file (READ contrib/kvasd${EXECUTABLE_SUFFIX}.md5 md5sum)
string (REGEX MATCH "[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]" md5sum "${md5sum}")

file (
  DOWNLOAD ${kvasd_NAME} contrib/kvasd${EXECUTABLE_SUFFIX}
  TIMEOUT 120
  STATUS status
  LOG log
  SHOW_PROGRESS
  EXPECTED_MD5 "${md5sum}"
  )
list (GET status 0 rc)
if (rc)
  message (WARNING "${status}")
  message (FATAL_ERROR "${log}")
endif (rc)
