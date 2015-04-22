#!/bin/bash -u

mod=mod-bundle

export MOD_BUNDLE=1

mkdir -p $mod/src/debug

s=$(date +%s)
printf "Setting up alternative compilation source files & directories for QDP/C ... "
/usr/bin/time make -f $mod/util/Makefile.qdp bundle -j >& $mod/src/debug/bundle
e=$(date +%s)
printf " [DONE] <--- %d seconds\n" $((e-s))

