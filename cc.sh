#! /bin/sh
set -e

if [ "$V" = 1 -o "$V" = 2 ]; then
    set -x
    MESCCFLAGS="$MESCCFLAGS -v"
fi

t=$1

rm -f  $t.E $t.M1 $t.m1

MES=${MES-mes-source/bin/mes}
MESCC=${MESCC-mes-source/pre-inst-env mescc}
CFLAGS=${CFLAGS-}
MES_PREFIX=${MES_PREFIX-mes-source}
absprefix=$(cd $prefix && pwd)
interpreter=/lib/mes-loader

ulimit -s 17030

CPPFLAGS="
-I $MES_PREFIX/lib
-I $MES_PREFIX/include
-D BOOTSTRAP=1
"

if test "$mes_cpu" = x86; then
    CPP_TARGET_FLAG="-D TCC_TARGET_I386=1"
elif test "$mes_cpu" = arm; then
    CPP_TARGET_FLAG="-D TCC_TARGET_ARM=1 -D TCC_ARM_VFP=1 -D CONFIG_TCC_LIBTCC1_MES=1"
elif test "$mes_cpu" = x86_64; then
    CPP_TARGET_FLAG="-D TCC_TARGET_X86_64=1"
else
    echo "cpu not supported: $mes_cpu"
fi

CPPFLAGS_TCC="$CPPFLAGS
-I .
$CPP_TARGET_FLAG
-D inline=
-D CONFIG_TCCDIR=\"$prefix/lib/tcc\"
-D CONFIG_TCC_CRTPREFIX=\"$prefix/lib:"{B}"/lib:.\"
-D CONFIG_TCC_ELFINTERP=\"$interpreter\"
-D CONFIG_TCC_LIBPATHS=\"$prefix/lib:"{B}"/lib:.\"
-D CONFIG_TCC_SYSINCLUDEPATHS=\"$MES_PREFIX/include:$prefix/include:"{B}"/include\"
-D TCC_LIBGCC=\"$prefix/lib/libc.a\"
-D TCC_LIBTCC1_MES=\"libtcc1-mes.a\"
-D CONFIG_TCCBOOT=1
-D CONFIG_TCC_STATIC=1
-D CONFIG_USE_LIBGCC=1
-D TCC_MES_LIBC=1
"

if $ONE_SOURCE; then
    CPPFLAGS_TCC="$CPPFLAGS_TCC -D ONE_SOURCE=$ONE_SOURCE"
fi

if $PREPROCESS; then
    time sh $MESCC $MESCCFLAGS -E -o $t.E       \
 $CFLAGS                                        \
 $CPPFLAGS_TCC                                  \
 $t.c
    time sh $MESCC $MESCCFLAGS -S -o $t.M1 $t.E
else
    time sh $MESCC $MESCCFLAGS -S -o $t.M1      \
 $CFLAGS                                        \
 $CPPFLAGS_TCC                                  \
  $t.c
fi

tr -d '\r' < $t.M1 > $t.S
