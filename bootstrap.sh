#! /bin/sh
set -e

if test "$V" = 1 -o "$V" = 2; then
    set -x
fi

MESCC=${MESCC-$(command -v mescc)}

if test "$V" = 2; then
    sh $MESCC --help
fi

host=${host-$($MESCC -dumpmachine 2>/dev/null)}
if test -z "$host$host_type"; then
    mes_cpu=${arch-$(get_machine || uname -m)}
else
    mes_cpu=${host%%-*}
fi
case "$mes_cpu" in
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
        have_float=${have_float-true}
        have_long_long=${have_long_long-true}
        have_setjmp=${have_setjmp-false}
        ;;
    riscv*)
        cpu=riscv64
        mes_cpu=riscv64
        tcc_cpu=riscv64
        triplet=riscv64-unknown-linux-gnu
        have_long_long=true
        cross_prefix=${triplet}-
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

prefix=${prefix-/usr/local}
MES_PREFIX=${MES_PREFIX-mes}
MES_STACK=${MES_STACK-10000000}
export MES_STACK
interpreter=${interpreter-/mes/loader}
MES_LIB=${MES_LIB-$MES_PREFIX/lib}
MES_SOURCE=${MES_SOURCE-mes-source}
#MES_LIB=$MES_SOURCE/gcc-lib/${mes_cpu}-mes
export MES_SOURCE
export MES_PREFIX
export MES_LIB

ONE_SOURCE=${ONE_SOURCE-false}
export ONE_SOURCE

CPPFLAGS="
-I $MES_PREFIX/lib
-I $MES_PREFIX/include
-D BOOTSTRAP=1
"

if test "$mes_cpu" = x86; then
    CPP_TARGET_FLAG=" -D TCC_TARGET_I386=1"
elif test "$mes_cpu" = arm; then
    CPP_TARGET_FLAG=" -D TCC_TARGET_ARM=1 -D TCC_ARM_VFP=1 -D CONFIG_TCC_LIBTCC1_MES=1"
elif test "$mes_cpu" = x86_64; then
    CPP_TARGET_FLAG=" -D TCC_TARGET_X86_64=1"
elif test "$mes_cpu" = riscv64; then
    CPP_TARGET_FLAG=" -D TCC_TARGET_RISCV64=1 -D HAVE_LONG_LONG=1"
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
-D CONFIG_TCCBOOT=1
-D CONFIG_TCC_STATIC=1
-D CONFIG_USE_LIBGCC=1
-D TCC_MES_LIBC=1
"

if [ "$mes_cpu" != riscv64 ]; then
    CPPFLAGS_TCC="$CPPFLAGS_TCC
    -D TCC_LIBTCC1_MES=\"libtcc1-mes.a\""
fi

if $ONE_SOURCE; then
    files="tcc.s"
    CPPFLAGS_TCC="$CPPFLAGS_TCC -D ONE_SOURCE=1"
else
    files="tccpp.s tccgen.s tccelf.s tccrun.s ${tcc_cpu}-gen.s ${tcc_cpu}-link.s ${tcc_cpu}-asm.s tccasm.s libtcc.s tcc.s"
fi

CFLAGS=
if test "$V" = 1; then
    CFLAGS="$CFLAGS -v"
elif test "$V" = 2; then
    CFLAGS="$CFLAGS -v -v"
fi

for f in $files; do
    i=$(basename $f .s)
    [ -z "$V" ] && echo "  CC         $i.c"
    sh $MESCC                                   \
       -S                                       \
       -o $f                                    \
       $CPPFLAGS_TCC                            \
       $CFLAGS                                  \
       $i.c
done

[ -z "$V" ] && echo "  CCLD       tcc-mes"
sh $MESCC $verbose -o tcc-mes -L $MES_SOURCE/mescc-lib -L $MES_SOURCE/lib $files -l c+tcc

CC="./tcc-mes"
AR="./tcc-mes -ar"
CPPFLAGS="
-I $MES_PREFIX/include
-I $MES_PREFIX/lib
-D BOOTSTRAP=1
"

CFLAGS=

REBUILD_LIBC=${REBUILD_LIBC-true}
export REBUILD_LIBC

mkdir -p $prefix/lib/tcc
if $REBUILD_LIBC; then
    for i in 1 i n; do
        rm -f crt$i.o;
        cp -f $MES_LIB/crt$i.c .
        $CC $CPPFLAGS $CFLAGS -static -nostdlib -nostdinc -c crt$i.c
    done

    rm -f libc.a
    cp -f $MES_LIB/libc+gnu.c libc.c
    $CC -c $CPPFLAGS $CFLAGS libc.c
    $AR cr libc.a libc.o

    rm -f libtcc1.a
    cp -f $MES_LIB/libtcc1.c .
    $CC -c $CPPFLAGS $CFLAGS libtcc1.c
    $AR cr libtcc1.a libtcc1.o

    if [ $mes_cpu = arm ]; then
        $CC -c $CPPFLAGS $CFLAGS $CPP_TARGET_FLAG lib/armeabi.c
        $CC -c $CPPFLAGS $CFLAGS $CPP_TARGET_FLAG lib/libtcc1.c
        $AR cr libtcc1.a libtcc1.o armeabi.o

        $CC -c $CPPFLAGS $CFLAGS $CPP_TARGET_FLAG -o libtcc1-mes.o $MES_LIB/libtcc1.c
        # $AR cr libtcc1-mes.a libtcc1-mes.o armeabi.o
        $AR cr libtcc1-mes.a libtcc1-mes.o

        cp -f libtcc1-mes.a $prefix/lib/tcc
    fi
    if [ $mes_cpu = riscv64 ]; then
        rm libtcc1.a libtcc1.o
        $CC -c -D HAVE_CONFIG_H=1 -I ${MES_PREFIX}/include -I ${MES_PREFIX}/include/linux/${MES_ARCH} -o libtcc1.o ${MES_PREFIX}/lib/libtcc1.c
        $CC -c -D HAVE_CONFIG_H=1 -I ${MES_PREFIX}/include -I ${MES_PREFIX}/include/linux/${MES_ARCH} -o lib-arm64.o lib/lib-arm64.c
        $AR cr libtcc1.a libtcc1.o lib-arm64.o
    fi

    rm -f libgetopt.a
    cp -f $MES_LIB/libgetopt.c .
    $CC -c $CPPFLAGS $CFLAGS libgetopt.c
    $AR cr libgetopt.a libgetopt.o
else
    cp -f $MES_LIB/crt1.o .
    cp -f $MES_LIB/crti.o .
    cp -f $MES_LIB/crtn.o .
    cp -f $MES_LIB/libc+gnu.a .
    cp -f $MES_LIB/libtcc1.a .
    cp -f $MES_LIB/libgetopt.a .

    if [ $mes_cpu = arm ]; then
        $CC -c $CPPFLAGS $CFLAGS $MES_LIB/libtcc1.c
        $CC -c $CPPFLAGS $CFLAGS lib/armeabi.c
        $AR cr libtcc1.a libtcc1.o armeabi.o
    fi
fi

cp -f libc.a $prefix/lib
cp -f libtcc1.a $prefix/lib/tcc
cp -f libgetopt.a $prefix/lib

export mes_cpu
export prefix
export CPPFLAGS

TCC=./tcc-mes sh boot.sh
TCC=./tcc-boot0 sh boot.sh
TCC=./tcc-boot1 sh boot.sh
TCC=./tcc-boot2 sh boot.sh
TCC=./tcc-boot3 sh boot.sh
TCC=./tcc-boot4 sh boot.sh
TCC=./tcc-boot5 sh boot.sh
if cmp --help; then
    cmp tcc-boot5 tcc-boot6
fi
cp -f tcc-boot5 tcc

CC=./tcc
AR='./tcc -ar'
if true; then
    for i in 1 i n; do
        rm -f crt$i.o;
        cp -f $MES_LIB/crt$i.c .
        $CC -c -g $CPPFLAGS $CFLAGS -static -nostdlib -nostdinc crt$i.c
    done

    rm -f libc.a
    $CC -c -g $CPPFLAGS $CFLAGS libc.c
    $AR cr libc.a libc.o

    if [ $mes_cpu != riscv64 ]; then
        rm -f libtcc1.a
        $CC -c -g $CPPFLAGS $CPP_TARGET_FLAG $CFLAGS lib/libtcc1.c
        $AR cr libtcc1.a libtcc1.o
    fi

    if [ $mes_cpu = arm ]; then
        $CC -c -g $CPPFLAGS $CFLAGS $CPP_TARGET_FLAG lib/armeabi.c

        $CC -c -g $CPPFLAGS $CFLAGS $CPP_TARGET_FLAG -o libtcc1-tcc.o lib/libtcc1.c
        $AR rc libtcc1-tcc.a libtcc1-tcc.o armeabi.o

        $CC -c -g $CPPFLAGS $CFLAGS -D HAVE_FLOAT=1 -D HAVE_LONG_LONG=1 libtcc1-mes.o $MES_LIB/libtcc1.c
        $AR cr libtcc1-mes.a libtcc1-mes.o armeabi.o

        $CC -c -g $CPP_TARGET_FLAG $CFLAGS -o libtcc1.o lib/libtcc1.c
        $AR cr libtcc1.a libtcc1.o armeabi.o

        cp -f libtcc1-tcc.a $prefix/lib/tcc
        cp -f libtcc1-mes.a $prefix/lib/tcc
    fi
    if [ $mes_cpu = riscv64 ]; then
        $CC -c -g $CPPFLAGS $CFLAGS $CPP_TARGET_FLAG lib/lib-arm64.c
        $CC -c -g $CPPFLAGS $CFLAGS $CPP_TARGET_FLAG libtcc1.o $MES_LIB/libtcc1.c
        $AR cr libtcc1.a libtcc1.o lib-arm64.o
    fi

    rm -f libgetopt.a
    $CC -c -g $CPPFLAGS $CFLAGS libgetopt.c
    $AR cr libgetopt.a libgetopt.o

    cp -f libc.a $prefix/lib
    cp -f libtcc1.a $prefix/lib/tcc
    cp -f libgetopt.a $prefix/lib
fi

echo "bootstrap.sh: done"
