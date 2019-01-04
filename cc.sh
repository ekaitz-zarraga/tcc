#! /bin/sh
set -e

if [ -n "$BUILD_DEBUG" ]; then
    set -x
    MESCCFLAGS="$MESCCFLAGS -v"
fi

t=$1

rm -f  $t.E $t.M1 $t.m1

GUIX=${GUIX-$(command -v guix||:)}
CC=${MESCC-mescc}
MES=${MES-../mes/src/mes}
MESCC=${MESCC-mescc}
CFLAGS=${CFLAGS-}
MES_PREFIX=${MES_PREFIX-${MESCC%/*}}
absprefix=$(cd $prefix && pwd)

if [ -z "$interpreter" -a -n "$GUIX" ]; then
    interpreter=$($GUIX environment --ad-hoc patchelf -- patchelf --print-interpreter $(guix build --system=i686-linux hello)/bin/hello)
elif [ -x /lib/ld-linux.so.2 ]; then
    # legacy non-GuixSD support
    interpreter=/lib/ld-linux.so.2
fi

ulimit -s 17030

if [ -n "$ONE_SOURCE" ]; then
    CFLAGS="$CFLAGS -D ONE_SOURCE=$ONE_SOURCE"
fi

if [ -n "$PREPROCESS" ]; then
    time sh $MESCC $MESCCFLAGS -E -o $t.E\
 $CFLAGS\
 -I .\
 -I $MES_PREFIX/lib\
 -I $MES_PREFIX/include\
 -D inline=\
 -D 'CONFIG_TCCDIR="'$prefix'/lib/tcc"'\
 -D 'CONFIG_TCC_CRTPREFIX="'$prefix'/lib:{B}/lib:."'\
 -D 'CONFIG_TCC_ELFINTERP="'$interpreter'"'\
 -D 'CONFIG_TCC_LIBPATHS="'$absprefix'/lib:{B}/lib:."'\
 -D 'CONFIG_TCC_SYSINCLUDEPATHS="'$MES_PREFIX'/include:'$prefix'/include:{B}/include"'\
 -D 'TCC_LIBGCC="'$absprefix'/lib/libc.a"'\
 -D BOOTSTRAP=1\
 -D CONFIG_TCCBOOT=1\
 -D CONFIG_TCC_STATIC=1\
 -D CONFIG_USE_LIBGCC=1\
 -D TCC_MES_LIBC=1\
 -D TCC_TARGET_I386=1\
  $t.c
    time sh $MESCC $MESCCFLAGS -S -o $t.M1 $t.E
else
    time sh $MESCC $MESCCFLAGS -S -o $t.M1\
 $CFLAGS\
 -I .\
 -I $MES_PREFIX/lib\
 -I $MES_PREFIX/include\
 -D inline=\
 -D 'CONFIG_TCCDIR="'$prefix'/lib/tcc"'\
 -D 'CONFIG_TCC_CRTPREFIX="'$prefix'/lib:{B}/lib:."'\
 -D 'CONFIG_TCC_ELFINTERP="'$interpreter'"'\
 -D 'CONFIG_TCC_LIBPATHS="'$absprefix'/lib:{B}/lib:."'\
 -D 'CONFIG_TCC_SYSINCLUDEPATHS="'$MES_PREFIX'/include:'$prefix'/include:{B}/include"'\
 -D CONFIG_USE_LIBGCC=1\
 -D 'TCC_LIBGCC="'$absprefix'/lib/libc.a"'\
 -D BOOTSTRAP=1\
 -D CONFIG_TCCBOOT=1\
 -D CONFIG_TCC_STATIC=1\
 -D CONFIG_USE_LIBGCC=1\
 -D TCC_MES_LIBC=1\
 -D TCC_TARGET_I386=1\
  $t.c
fi

tr -d '\r' < $t.M1 > $t.S
