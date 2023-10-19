#! /bin/sh

set -e

export V
export MESCC
export MES_DEBUG
export MES_PREFIX
export MES_LIB
export MES_SOURCE
export ONE_SOURCE
export PREPROCESS
export REBUILD_LIBC

export cpu
export cross_prefix
export mes_cpu
export prefix
export tcc_cpu
export triplet

if test "$V" = 1 -o "$V" = 2; then
    set -x
fi

unset CPATH C_INCLUDE_PATH LIBRARY_PATH
prefix=${prefix-usr}
export prefix
MESCC=${MESCC-mes-source/pre-inst-env mescc}

CC=${CC-$MESCC}
host=${host-$($CC -dumpmachine 2>/dev/null)}
if test -z "$host$host_type"; then
    mes_cpu=${arch-$(get_machine || uname -m)}
else
    mes_cpu=${host%%-*}
fi
case "$mes_cpu" in
    # TODO: riscv64: this file is not involved in bootstrapping, so we didn't
    # add riscv64 support
    i386|i486|i586|i686|x86)
        mes_cpu=x86
        tcc_cpu=i386
        have_float=${have_float-true}
        have_long_long=${have_long_long-true}
        have_setjmp=${have_setjmp-true}
        ;;
    armv4|armv7l|arm)
        mes_cpu=arm
        tcc_cpu=arm
        have_float=${have_float-false}
        have_long_long=${have_long_long-true}
        have_setjmp=${have_setjmp-false}
        ;;
    amd64)
        tcc_cpu=x86_64
        mes_cpu=x86_64
        have_float=${have_float-true}
        have_long_long=${have_long_long-true}
        have_setjmp=${have_setjmp-true}
        ;;
esac
case "$host" in
    *linux-gnu|*linux)
        mes_kernel=linux;;
    *gnu)
        mes_kernel=gnu;;
    *)
        mes_kernel=linux;;
esac
export mes_cpu
export tcc_cpu
export have_float
export have_long_long
export have_setjmp

MES=${MES-mes-source/bin/mes}
MES_PREFIX=${MES_PREFIX-mes}
MES_SOURCE=${MES_SOURCE-mes-source}
MES_LIB=${MES_LIB-$MES_PREFIX/lib}
MES_LIB=$MES_SOURCE/gcc-lib/${mes_cpu}-mes

PREPROCESS=${PREPROCESS-true}
ONE_SOURCE=${ONE_SOURCE-false}

interpreter=/lib/mes-loader
rm -f tcc.E tcc.hex2 tcc.M1 tcc.m1 tcc-mes tcc-boot?

verbose=
if test "$V" = 1; then
    MESCCFLAGS="$MESCCFLAGS -v"
elif test "$V" = 2; then
    MESCCFLAGS="$MESCCFLAGS -v -v"
fi

mkdir -p $prefix/lib

if test "$V" = 2; then
    sh $MESCC --help
fi

if $ONE_SOURCE; then
    sh cc.sh tcc
    files="tcc.S"
else
    sh cc.sh tccpp
    sh cc.sh tccgen
    sh cc.sh tccelf
    sh cc.sh tccrun
    sh cc.sh ${tcc_cpu}-gen
    sh cc.sh ${tcc_cpu}-link
    sh cc.sh ${tcc_cpu}-asm
    sh cc.sh tccasm
    sh cc.sh libtcc
    sh cc.sh tcc
    files="
tccpp.S
tccgen.S
tccelf.S
tccrun.S
${tcc_cpu}-gen.S
${tcc_cpu}-link.S
${tcc_cpu}-asm.S
tccasm.S
libtcc.S
tcc.S
"
fi

$MESCC                                          \
    $MESCCFLAGS                                 \
    -g                                          \
    -o tcc-mes                                  \
    -L $MES_SOURCE/mescc-lib                    \
    -L $MES_SOURCE/lib                          \
    $files                                      \
    -l c+tcc

CC="./tcc-mes"
AR="./tcc-mes -ar"
CPPFLAGS="
-I $MES_PREFIX/include
-I $MES_PREFIX/lib
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

CFLAGS=

REBUILD_LIBC=${REBUILD_LIBC-true}

mkdir -p $prefix/lib/tcc
if $REBUILD_LIBC; then
    for i in 1 i n; do
        rm -f crt$i.o;
        cp -f $MES_LIB//crt$i.c .
        $CC $CPPFLAGS $CFLAGS -static -nostdlib -nostdinc -c crt$i.c
    done

    rm -f libc.a
    cp -f $MES_LIB/libc+gnu.c libc.c
    $CC -c $CPPFLAGS $CFLAGS libc.c
    $AR cr libc.a libc.o

    rm -f libtcc1.a
    cp -f $MES_LIB/libtcc1.c .
    $CC -c $CPPFLAGS $CPP_TARGET_FLAG $CFLAGS lib/libtcc1.c
    $AR cr libtcc1.a libtcc1.o

    if [ $mes_cpu = arm ]; then
        $CC -c -g $CPPFLAGS $CFLAGS $CPP_TARGET_FLAG lib/armeabi.c

        $CC -c -g $CPPFLAGS $CFLAGS $CPP_TARGET_FLAG -o libtcc1-tcc.o lib/libtcc1.c
        $AR rc libtcc1-tcc.a libtcc1-tcc.o armeabi.o

        $CC -c -g $CPPFLAGS $CFLAGS -D HAVE_FLOAT=1 -D HAVE_LONG_LONG=1 -o libtcc1-mes.o $MES_LIB/libtcc1.c
        $AR cr libtcc1-mes.a libtcc1-mes.o armeabi.o

        $CC -c -g $CPP_TARGET_FLAG $CFLAGS -o libtcc1.o lib/libtcc1.c
        # $AR cr libtcc1.a libtcc1.o armeabi.o
        $AR cr libtcc1.a libtcc1.o

        cp -f libtcc1-tcc.a $prefix/lib/tcc
        cp -f libtcc1-mes.a $prefix/lib/tcc
    fi

    rm -f libgetopt.a
    cp -f $MES_LIB/libgetopt.c .
    $CC -c $CPPFLAGS $CFLAGS libgetopt.c
    $AR cr libgetopt.a libgetopt.o
else
    cp -f $MES_LIB/crt1.o .
    cp -f $MES_LIB/crti.o .
    cp -f $MES_LIB/crtn.o .
    cp -f $MES_LIB/libc+gnu.a libc.a
    cp -f $MES_LIB/libtcc1.a .
    cp -f $MES_LIB/libgetopt.a .

    if [ $mes_cpu = arm ]; then
        $CC -c $CPPFLAGS $CFLAGS $MES_LIB/libtcc1.c
        $CC -c $CPPFLAGS $CFLAGS lib/armeabi.c
    fi
fi

cp -f libc.a $prefix/lib
cp -f libtcc1.a $prefix/lib/tcc
cp -f libgetopt.a $prefix/lib

rm -rf mes-usr
mkdir -p mes-usr
cp *.M1 mes-usr
cp *.S mes-usr
cp *.a mes-usr

REBUILD_LIBC=true
TCC=./tcc-mes sh boot.sh
TCC=./tcc-boot0 sh boot.sh
TCC=./tcc-boot1 sh boot.sh
TCC=./tcc-boot2 sh boot.sh
TCC=./tcc-boot3 sh boot.sh
TCC=./tcc-boot4 sh boot.sh
TCC=./tcc-boot5 sh boot.sh
cmp tcc-boot5 tcc-boot6
cp -f tcc-boot5 tcc

echo "build.sh: done"
