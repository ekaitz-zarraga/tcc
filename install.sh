#! /bin/sh

if [ "$V" = 1 -o "$V" = 2 ]; then
    set -x
fi

set -e

prefix=${prefix-usr}
MES_PREFIX=${MES_PREFIX-${MESCC%/*}}

mkdir -p $prefix/bin
cp tcc $prefix/bin
tar -C $MES_PREFIX -cf- include | tar -C $prefix -xf-

mkdir -p $prefix/lib
cp crt1.o $prefix/lib/crt1.o
cp crti.o $prefix/lib/crti.o
cp crtn.o $prefix/lib/crtn.o

mkdir -p $prefix/lib/tcc
cp libc.a $prefix/lib
cp libtcc1.a $prefix/lib/tcc
cp libgetopt.a $prefix/lib

mkdir -p $prefix/share
cp crt1.c $prefix/share
cp crti.c $prefix/share
cp crtn.c $prefix/share
cp libc.c $prefix/share
cp libgetopt.c $prefix/share
