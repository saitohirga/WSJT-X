#!/bin/sh
WSJTX_BUNDLE="`echo "$0" | sed -e 's/\/Contents\/MacOS\/.*//'`"
WSJTX_RESOURCES="$WSJTX_BUNDLE/Contents/Resources"
WSJTX_TEMP="/tmp/wsjtx/$UID"

echo "running $0"
echo "WSJTX_BUNDLE: $WSJTX_BUNDLE"

# Setup temporary runtime files
rm -rf "$WSJTX_TEMP"

export "DYLD_LIBRARY_PATH=$WSJTX_RESOURCES/lib"
export "PATH=$WSJTX_RESOURCES/bin:$PATH"

#export
exec "$WSJTX_RESOURCES/bin/wsjtx"