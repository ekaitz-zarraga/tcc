#! /bin/sh
set -ex
rm -f i686-unknown-linux-gnu-tcc

# crt1=$(i686-unknown-linux-gnu-gcc --print-file-name=crt1.o)
# crtdir=$(dirname $crt1)

MES_PREFIX=${MES_PREFIX-../mes}
TINYCC_SEED=${TINYCC_SEED-../tinycc-seed}
cp $TINYCC_SEED/crt1.mlibc-o crt1.o

CC=${CC-i686-unknown-linux-gnu-gcc}
CFLAGS="
-nostdinc
-nostdlib
-fno-builtin
--include=$MES_PREFIX/lib/crt1.c
--include=$MES_PREFIX/lib/libc-gcc+tcc.c
-Wl,-Ttext-segment=0x1000000
"

if [ -z "$interpreter" ] && guix --help &>/dev/null; then
    interpreter=$(guix environment --ad-hoc patchelf -- patchelf --print-interpreter $(guix build --system=i686-linux hello)/bin/hello)
elif [ -x /lib/ld-linux.so.2 ]; then
    # legacy non-GuixSD support
    interpreter=/lib/ld-linux.so.2
fi
interpreter=${interpreter-interpreter}

mkdir -p $PREFIX/lib
ABSPREFIX=$(cd $PREFIX && pwd)
cp $TINYCC_SEED/libc-gcc+tcc.mlibc-o $ABSPREFIX/lib
$CC -g -o i686-unknown-linux-gnu-tcc\
   $CFLAGS\
   -I.\
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
