#! /bin/sh

if [ -n "$BUILD_DEBUG" ]; then
    set -x
fi

set -e

PREFIX=${PREFIX-usr}
MES_PREFIX=${MES_PREFIX-${MESCC%/*}}
MES_SEED=${MES_SEED-../mes-seed}

mkdir -p $PREFIX/bin
cp tcc $PREFIX/bin
tar -C $MES_PREFIX -cf- include | tar -C $PREFIX -xf-

mkdir -p $PREFIX/lib
cp crt1.o $PREFIX/lib/crt1.o
cp crti.o $PREFIX/lib/crti.o
cp crtn.o $PREFIX/lib/crtn.o

mkdir -p $PREFIX/lib/tcc
cp libc.a $PREFIX/lib
cp libtcc1.a $PREFIX/lib/tcc

tar -C $MES_SEED -cf- . | tar -C $PREFIX/lib -xf-

rm -f $PREFIX/lib/linux/x86_64-mes/crt1
