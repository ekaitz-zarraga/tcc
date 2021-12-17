#! /bin/sh
set -ex

CC=${CC-gcc}
crt1=$($CC --print-file-name=crt1.o)
prefix=${prefix-./usr}

rm -f tcc gcc-tcc
touch config.mak
make clean
rm -f *.a *.o
unset ONE_SOURCE
unset CFLAGS LDFLAGS

CPPFLAGS_TCC="
-DHAVE_FLOAT=1
-DHAVE_BITFIELD=1
-DHAVE_LONG_LONG=1
-DHAVE_SETJMP=1
"

arch=$(uname -m)
case $arch in
     aarch*)
         cpu=arm
         mes_cpu=arm
         tcc_cpu=arm
         triplet=arm-linux-gnueabihf
         cross_prefix=${triplet}-
         CFLAGS=-marm
         CPP_TARGET_FLAG="-DTCC_CPU_VERSION=7 -DTCC_TARGET_ARM -DTCC_ARM_VFP"
         ;;
     arm*|aarch*)
         cpu=arm
         mes_cpu=arm
         tcc_cpu=arm
         triplet=arm-unknown-linux-gnueabihf
         cross_prefix=${triplet}-
         CFLAGS=-marm
         CPP_TARGET_FLAG="-DTCC_CPU_VERSION=7 -DTCC_TARGET_ARM -DTCC_ARM_VFP"
         ;;
     *x86_64*)
         cpu=x86_64
         mes_cpu=x86_64
         tcc_cpu=x86_64
         triplet=x86_64-unknown-linux-gnu
         cross_prefix=${triplet}-
         CFLAGS=
         CPP_TARGET_FLAG="-DTCC_TARGET_X86_64"
         ;;
     *)
         cpu=x86
         mes_cpu=x86
         tcc_cpu=i386
         triplet=i686-unknown-linux-gnu
         cross_prefix=${triplet}-
         CFLAGS=
         CPP_TARGET_FLAG="-DTCC_TARGET_I386"
         ;;
esac

./configure --prefix=$prefix --tccdir=$PWD --crtprefix=$crtdir --extra-cflags="$CFLAGS $CPPFLAGS_TCC" --cc=$CC
type -p etags && make ETAGS

#Try building without eabihf
#make PROGRAM_PREFIX=gcc- gcc-tcc
if [ $mes_cpu = arm ]; then
    make PROGRAM_PREFIX=gcc- gcc-tcc DEF-arm='$(DEF-arm-vfp)'
    ./gcc-tcc -c $CPP_TARGET_FLAG $CPPFLAGS_TCC $CFLAGS -c lib/libtcc1.c
    ./gcc-tcc -ar cr libtcc1.a libtcc1.o
else
    make PROGRAM_PREFIX=gcc- gcc-tcc
    rm -f libtcc1.c
    touch libtcc1.c
    ./gcc-tcc -c libtcc1.c
    ./gcc-tcc -ar cr libtcc1.a libtcc1.o
fi
make libtcc1.a
rm -rf gcc-tcc-usr
mkdir -p gcc-tcc-usr
cp *.o *.a gcc-tcc-usr
rm -rf $prefix
mkdir -p $prefix/lib/tcc
cp libtcc1.a $prefix/lib/tcc
