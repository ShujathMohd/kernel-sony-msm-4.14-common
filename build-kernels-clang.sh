#!/bin/sh

. "${0%/*}/build_shared_vars.sh"


export CLANG=$ANDROID_ROOT/prebuilts/clang/host/linux-x86/clang-r487747c/bin/

# Build command
BUILD_ARGS="LLVM=1 LLVM_IAS=1"

PATH=$CLANG:$PATH
# source shared parts
. "${0%/*}/build_shared.sh"
