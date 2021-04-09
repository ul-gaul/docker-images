#!/bin/sh

################### FUNCTIONS ####################

# Source: https://stackoverflow.com/a/52872489/5647659
goto() {
  label=$(shift)
  cmd=$(sed -En "/^[[:space:]]*#[[:space:]]*$label:[[:space:]]*#/{:a;n;p;ba};" "$0")
  eval "$cmd"
  exit
}

# Returns true or false depending on the value of $1 (transforms $1 into a boolean)
isTrue() {
  # true if $1 is not empty and $1 != 0 and $1 != false
  [ -n "$1" ] && [ "$1" != "0" ] && [ "$1" != "false" ]
}

# Returns true if ANSI is enabled
useAnsi() {
  isTrue "$USE_ANSI"
}

# Prints an error message
logE() {
  useAnsi && echo -n '\e[91m' >&2
  echo -n "ERROR: " >&2
  echo -n "$@" >&2
  useAnsi && echo -n '\e[m' >&2
  echo >&2 # never fails / always returns true
}

# Prints a warning message
logW() {
  useAnsi && echo -n '\e[93m' >&2
  echo -n "WARN: " >&2
  echo -n "$@" >&2
  useAnsi && echo -n '\e[m' >&2
  echo >&2 # never fails / always returns true
}

# Prints a message
log() {
  useAnsi && echo -n '\e[96m' >&2
  echo -n "$@" >&2
  useAnsi && echo -n '\e[m' >&2
  echo >&2 # never fails / always returns true
}

################## VALIDATIONS ###################

if [ "$#" = "0" ]; then
  logE 'no build target specified!'
  exit 1
fi

if [ -z "$APP_NAME" ]; then
  logE 'required variable "APP_NAME" is not set!'
  exit 1
fi

if [ -z "$FRONTEND_DIR" ]; then
  logE 'required variable "FRONTEND_DIR" is not set!'
  exit 1
fi

################### FRONTEND #####################
if [ -d "$FRONTEND_DIR/dist" ] && isTrue "$SKIP_FRONTEND"; then
  goto backend "$@"
fi

log 'Installing frontend dependencies...'
wd="$(pwd)"

if ! cd "$FRONTEND_DIR"; then
  logE 'invalid frontend directory!'
  exit 1
fi

if ! npm ci --also=dev ; then
  logE 'could not install frontend dependencies!'
  # shellcheck disable=SC2164
  cd "$wd" &>/dev/null
  exit 1
fi

log 'Building frontend...'
if ! npm run build ; then
  logE 'could not build frontend!'
  # shellcheck disable=SC2164
  cd "$wd" &>/dev/null
  exit 1
fi

cd "$wd" || exit 1 # Should never fail

################### BACKEND ######################
#backend:#

log 'Downloading Go dependencies...'
export CGO_ENABLED=1
if ! go mod download ; then
  logE 'could not download Go dependencies!'
  exit 1
fi

OUTPUT_DIR="${OUTPUT_DIR:-/out}"

for target in "$@"; do
  target="$(echo "$target" | tr '[:upper:]' '[:lower:]')"

  unset PKG_CONFIG_PATH
  unset CXX CC GOARM
  unset ldflags

  GOOS="$(echo "$target" | cut -d/ -f1)"
  GOARCH="$(echo "$target" | cut -d/ -f2)"
  output="$OUTPUT_DIR/$GOOS/$GOARCH/$APP_NAME-$GOOS-$GOARCH"

  # Verify if the target is supported by Go
  if ! go tool dist list | grep -x "$GOOS/$GOARCH" >/dev/null 2>&1 ; then
    logW "unsupported target '$GOOS/$GOARCH' (skipped)"
    continue
  fi

  case "$GOOS/$GOARCH" in
  windows/amd64)
    CXX='x86_64-w64-mingw32-g++'
    CC='x86_64-w64-mingw32-gcc'
    ldflags='-H windowsgui'
    output="${output}.exe"
    ;;
  windows/386)
    CXX='i686-w64-mingw32-g++'
    CC='i686-w64-mingw32-gcc'
    ldflags='-H windowsgui'
    output="${output}.exe"
    ;;
  linux/arm64)
    PKG_CONFIG_PATH='/usr/lib/aarch64-linux-gnu/pkgconfig'
    CXX='aarch64-linux-gnu-g++'
    CC='aarch64-linux-gnu-gcc'
    ;;
  linux/arm)
    PKG_CONFIG_PATH='/usr/lib/arm-linux-gnueabihf/pkgconfig'
    CXX='arm-linux-gnueabihf-g++'
    CC='arm-linux-gnueabihf-gcc'
    GOARM="$(echo "$target" | cut -d/ -f3)"
    GOARM="${GOARM:-7}" # Use ARMv7 by default
    ;;
  linux/amd64) ;; # Use system defaults
  linux/386)
    PKG_CONFIG_PATH='/usr/lib/i386-linux-gnu/pkgconfig'
    CXX='i686-linux-gnu-g++'
    CC='i686-linux-gnu-gcc'
    ;;
  darwin/*)
    logW 'darwin not compatible (skipped)'
    continue
    ;;
  *)
    # Not implemented but will try anyway
    ;;
  esac

  export GOOS GOARCH GOARM
  export PKG_CONFIG_PATH
  export CXX CC

  log "Building binary for $GOOS/$GOARCH..."
  if ! go build "-ldflags=$ldflags" -o "$output" . ; then
    logE 'build failed!'
    exit 1
  fi

  if [ "$GOOS" = "windows" ]; then
    log "Downloading required DLLs..."
    arch='x86'
    if [ "$GOARCH" = "amd64" ]; then
      arch='x64'
    fi

    curl -sSLo "$(dirname "$output")/webview.dll" \
      "https://raw.githubusercontent.com/webview/webview/master/dll/$arch/webview.dll" \
      && curl -sSLo "$(dirname "$output")/WebView2Loader.dll" \
        "https://raw.githubusercontent.com/webview/webview/master/dll/$arch/WebView2Loader.dll"

    if [ "$?" != "0" ]; then
      logW "could not download all required DLLs.
      Download them manually from https://github.com/webview/webview/tree/master/dll/$arch"
    fi
  fi

done
