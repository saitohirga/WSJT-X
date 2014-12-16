#
# CMake script to fetch kvasd binary for the current platform
#
set (kvasd_NAME "${URL}/${SYSTEM_NAME}/kvasd${EXECUTABLE_SUFFIX}")
set (kvasd_target "contrib/kvasd${EXECUTABLE_SUFFIX}")

message (STATUS "downloading file: ${kvasd_NAME}.md5")
file (
  DOWNLOAD "${kvasd_NAME}.md5" "${kvasd_target}.md5"
  TIMEOUT 120
  STATUS status
  LOG log
  SHOW_PROGRESS
  )
list (GET status 0 rc)
if (rc)
  message (WARNING "${status}")
  message (FATAL_ERROR "${log}")
endif (rc)
file (READ "${kvasd_target}.md5" md5sum)
string (REGEX MATCH "[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]" md5sum "${md5sum}")

file (MD5 "${kvasd_target}" current_md5sum)
if (NOT "${md5sum}" STREQUAL "${current_md5sum}")
  message (STATUS "downloading file: ${kvasd_NAME}")
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
else (NOT "${md5sum}" STREQUAL "${current_md5sum}")
  message (STATUS "file: ${kvasd_NAME} up to date")
endif (NOT "${md5sum}" STREQUAL "${current_md5sum}")
