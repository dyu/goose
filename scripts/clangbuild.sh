##!/bin/sh

set -eo pipefail

CURRENT_DIR=$PWD
# locate
if [ -z "$BASH_SOURCE" ]; then
    SCRIPT_DIR=`dirname "$(readlink -f $0)"`
elif [ -e '/bin/zsh' ]; then
    F=`/bin/zsh -c "print -lr -- $BASH_SOURCE(:A)"`
    SCRIPT_DIR=`dirname $F`
elif [ -e '/usr/bin/realpath' ]; then
    F=`/usr/bin/realpath $BASH_SOURCE`
    SCRIPT_DIR=`dirname $F`
else
    F=$BASH_SOURCE
    while [ -h "$F" ]; do F="$(readlink $F)"; done
    SCRIPT_DIR=`dirname $F`
fi

OUT_DIR_SUFFIX='cb'
UNAME=`uname`
case "$UNAME" in
    Darwin)
    SUFFIX=''
    ;;
    Linux)
    SUFFIX=''
    ;;
    *)
    SUFFIX='.exe'
    if [ "$CLANG_CL" = '1' ]; then
        SUFFIX='-cl.exe'
        OUT_DIR_SUFFIX='cl'
    fi
    ;;
esac

mkdir -p build-$OUT_DIR_SUFFIX

SRC_FILE=`basename $1`
SRC_NAME="${SRC_FILE%.*}"

goose build $@ --cc "$(which clang)$SUFFIX" -o build-$OUT_DIR_SUFFIX/$SRC_NAME --standalone
