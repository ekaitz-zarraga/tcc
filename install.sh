#! /bin/sh
set -ex

PREFIX=${PREFIX-usr}
MES_PREFIX=${MES_PREFIX-$(dirname $MESCC)/../share/mes}
TINYCC_SEED=${TINYCC_SEED-../tinycc-seed}

mkdir -p $PREFIX/bin
cp mes-tcc $PREFIX/bin
mkdir -p $PREFIX/lib
cp $TINYCC_SEED/* $PREFIX/lib
cp crt1.o $PREFIX/lib
mkdir -p $PREFIX/lib/tcc
#TODO: cp libtcc1.a?? $PREFIX/lib/tcc
tar -C $MES_PREFIX -cf- include | tar -C $PREFIX -xf-
