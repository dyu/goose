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

OUT_DIR_SUFFIX='xb'
mkdir -p build-$OUT_DIR_SUFFIX

SRC_FILE=`basename $1`
SRC_NAME="${SRC_FILE%.*}"

# xclang installed via:
# pixi global install xclang -c conda-forge -c https://conda.clice.io
# ~/.pixi/envs/xclang/opt/xclang sdk fetch macos --accept-license
# ~/.pixi/envs/xclang/opt/xclang sdk fetch windows --accept-license
XCLANG_HOME=~/.pixi/envs/xclang/opt/xclang

SUFFIX=''

link_msvc_dirs() {
    #WIN_SDK_DIR=`xclang sdk path windows`
    WIN_SDK_DIR="$XCLANG_HOME/sdk/windows"
    if [ ! -e "$WIN_SDK_DIR/Lib" ]; then
        cd $WIN_SDK_DIR
        INCLUDE_DIR="$(find . -name Include)"
        LIB_DIR="$(find . -name Lib)"
        ln -sf "$INCLUDE_DIR/$(ls "$INCLUDE_DIR")" Include
        ln -sf "$LIB_DIR/$(ls "$LIB_DIR")" Lib
        cd - > /dev/null
    fi
}

goose_build() {
    goose build $@ --cc ~/.pixi/envs/xclang/opt/xclang/bin/clang$SUFFIX --standalone  
}

build_target() {
    TARGET="$1"
    shift
    mkdir -p $TARGET && cd $TARGET && $XCLANG_HOME/bin/clang --target=$TARGET $@ && cd ..
}

build_darwin() {
    shift
    cd build-$OUT_DIR_SUFFIX
    $XCLANG_HOME/bin/clang $@ && \
    build_target x86_64-unknown-linux-gnu -I$XCLANG_HOME/x86_64-unknown-linux-gnu/usr/include $@ && \
    echo build_target x86_64-pc-windows-msvc -I$XCLANG_HOME/sdk/windows/Include/ucrt $@ && \
    du -sh $SRC_NAME x86_64-unknown-linux-gnu/$SRC_NAME x86_64-pc-windows-msvc/$SRC_NAME
}

build_linux() {
    shift
    cd build-$OUT_DIR_SUFFIX
    $XCLANG_HOME/bin/clang $@ && \
    build_target aarch64-apple-darwin -I$XCLANG_HOME/sdk/macos/usr/include $@ && \
    echo build_target x86_64-pc-windows-msvc -I$XCLANG_HOME/sdk/windows/Include/ucrt $@ && \
    du -sh $SRC_NAME aarch64-apple-darwin/$SRC_NAME x86_64-pc-windows-msvc/$SRC_NAME
}

build_windows() {
    shift
    cd build-$OUT_DIR_SUFFIX
    $XCLANG_HOME/bin/clang $@ && \
    build_target x86_64-unknown-linux-gnu -I$XCLANG_HOME/x86_64-unknown-linux-gnu/usr/include $@ && \
    build_target aarch64-apple-darwin -I$XCLANG_HOME/sdk/macos/usr/include $@ && \
    du -sh $SRC_NAME x86_64-unknown-linux-gnu/$SRC_NAME aarch64-apple-darwin/$SRC_NAME
}

link_msvc_dirs
UNAME=`uname`
case "$UNAME" in
    Darwin)
    [ "$XC" != '1' ] || { build_darwin `goose_build $@ --dry-run -o $SRC_NAME`; exit 0; }
    ;;
    Linux)
    [ "$XC" != '1' ] || { build_linux `goose_build $@ --dry-run -o $SRC_NAME`; exit 0; }
    ;;
    *)
    SUFFIX='.exe'
    [ "$XC" != '1' ] || { build_windows `goose_build $@ --dry-run -o $SRC_NAME`; exit 0; }
    ;;
esac

goose_build $@ -o build-$OUT_DIR_SUFFIX/$SRC_NAME && \
du -sh build-$OUT_DIR_SUFFIX/$SRC_NAME
