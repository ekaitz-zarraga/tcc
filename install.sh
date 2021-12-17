#! /bin/sh

set -e

if [ "$V" = 1 -o "$V" = 2 ]; then
    set -x
fi

arch=$(uname -m)
case $arch in
     aarch*)
         cpu=arm
         mes_cpu=arm
         tcc_cpu=arm
         triplet=arm-linux-gnueabihf
         cross_prefix=${triplet}-
         ;;
     arm*|aarch*)
         cpu=arm
         mes_cpu=arm
         tcc_cpu=arm
         triplet=arm-unknown-linux-gnueabihf
         cross_prefix=${triplet}-
         ;;
     *)
         cpu=x86
         mes_cpu=x86
         tcc_cpu=i386
         triplet=i686-unknown-linux-gnu
         cross_prefix=${triplet}-
         ;;
esac

prefix=${prefix-usr}
MES_PREFIX=${MES_PREFIX-mes}

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
if [ $mes_cpu = arm ]; then
    cp libtcc1-mes.a $prefix/lib/tcc
fi

cp libgetopt.a $prefix/lib

mkdir -p $prefix/share
cp crt1.c $prefix/share
cp crti.c $prefix/share
cp crtn.c $prefix/share
cp libc.c $prefix/share
cp libgetopt.c $prefix/share
