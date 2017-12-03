#! /bin/sh
set -ex
rm -f tcc

touch config.mak
make clean
crt1=$(gcc --print-file-name=crt1.o)
crtdir=$(dirname $crt1)

./configure --tccdir=$PWD --crtprefix=$crtdir
make ETAGS
make

interpreter=$(guix environment --ad-hoc patchelf -- patchelf --print-interpreter $(type -p gcc))
gcc -o tcc tcc.c\
    --include=$MES_PREFIX/lib/libc-gcc.c\
    -DPOSIX=1\
    -I.\
    -I $MES_PREFIX/include\
    -I $MES_PREFIX/lib\
    -D CONFIG_TCCDIR="\"$PWD\""\
    -D CONFIG_TCC_CRTPREFIX="\"$crtdir\""\
    -D CONFIG_TCC_ELFINTERP="\"$interpreter\""\
    -D TCC_TARGET_X86_64=1\
    -D ONE_SOURCE=yes\
    -ldl
