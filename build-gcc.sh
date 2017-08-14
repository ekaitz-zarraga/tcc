#! /bin/sh
set -ex
rm -f tcc

GUIX=${GUIX-$(command -v guix||:)}
MES_PREFIX=${MES_PREFIX-../mes}

touch config.mak
make clean
rm -f crt*.o
crt1=$(gcc --print-file-name=crt1.o)
#crtdir=$(dirname $crt1)
#crti=$(gcc --print-file-name=crti.o)
#crtn=$(gcc --print-file-name=crtn.o)

unset ONE_SOURCE
./configure --tccdir=$PWD --crtprefix=$crtdir --extra-cflags="-DHAVE_FLOAT=1 -DHAVE_BITFIELD=1"
make ETAGS
make PROGRAM_PREFIX=gcc- gcc-tcc
make libtcc1.a
