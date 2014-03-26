# Load version number components.
include (${wsjtx_SOURCE_DIR}/Versions.cmake)

# Compute the full version string.
set (wsjtx_VERSION ${WSJTX_VERSION_MAJOR}.${WSJTX_VERSION_MINOR}.${WSJTX_VERSION_PATCH})
if (WSJTX_RC)
  set (wsjtx_VERSION ${wsjtx_VERSION}-rc${WSJTX_RC})
endif ()
