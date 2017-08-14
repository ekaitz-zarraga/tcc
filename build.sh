#! /bin/sh
set -ex
rm -f tcc.E tcc.hex2 tcc.M1 tcc.m1 mes-tcc

CC=${MESCC-mescc}
MESCC=${MESCC-mescc}
HEX2=${HEX2-hex2}
M1=${M1-M1}
CFLAGS=${CFLAGS-}

MES_PREFIX=${MES_PREFIX-$(dirname $MESCC)/../share/mes}
TINYCC_SEED=${TINYCC_SEED-../tinycc-seed}
cp $TINYCC_SEED/crt1.mlibc-o crt1.o

if [ -z "$interpreter" ] && guix --help; then
    interpreter=$(guix environment --ad-hoc patchelf -- patchelf --print-interpreter $(guix build --system=i686-linux hello)/bin/hello)
elif [ -x /lib/ld-linux.so.2 ]; then
    # legacy non-GuixSD support
    interpreter=/lib/ld-linux.so.2
fi
interpreter=${interpreter-interpreter}

mkdir -p $PREFIX/lib
ABSPREFIX=$(cd $PREFIX && pwd)
cp $TINYCC_SEED/libc-gcc+tcc.mlibc-o $ABSPREFIX/lib

sh $MESCC -E -o tcc.E\
 $CFLAGS\
 -I .\
 -I $MES_PREFIX/lib\
 -I $MES_PREFIX/include\
 -D 'CONFIG_TCCDIR="'$PREFIX'/lib/tcc"'\
 -D 'CONFIG_TCC_CRTPREFIX="'$PREFIX'/lib:{B}/lib:."'\
 -D 'CONFIG_TCC_ELFINTERP="'$interpreter'"'\
 -D 'CONFIG_TCC_LIBPATHS="'$ABSPREFIX'/lib:{B}/lib:."'\
 -D 'CONFIG_TCC_SYSINCLUDEPATHS="'$MES_PREFIX'/include:'$PREFIX'/include:{B}/include"'\
 -D CONFIG_USE_LIBGCC=1\
 -D 'TCC_LIBGCC="'$ABSPREFIX'/lib/libc-gcc+tcc.mlibc-o"'\
 -D CONFIG_TCC_STATIC=1\
 -D ONE_SOURCE=yes\
 -D TCC_TARGET_I386=1\
 -D BOOTSTRAP=1\
  tcc.c

sh $MESCC -c -o tcc.M1 tcc.E
tr -d '\r' < tcc.M1 > tcc.m1

$M1 --LittleEndian --Architecture=1\
 -f $MES_PREFIX/stage0/x86.M1\
 -f $MES_PREFIX/lib/libc-mes+tcc.M1\
 -f tcc.m1\
  > tcc.hex2

$HEX2 --LittleEndian --Architecture=1 --BaseAddress=0x1000000\
 -f $MES_PREFIX/stage0/elf32-header.hex2\
 -f $MES_PREFIX/lib/crt1.hex2\
 -f tcc.hex2\
 -f $MES_PREFIX/stage0/elf32-footer-single-main.hex2\
 > mes-tcc

chmod +x mes-tcc
