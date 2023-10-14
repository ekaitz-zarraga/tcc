#! /bin/sh

set -e

if test "$V" = 1 -o "$V" = 2; then
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
         have_float=${have_float-false}
         have_long_long=${have_long_long-true}
         have_setjmp=${have_setjmp-false}
         ;;
     arm*|aarch)
         cpu=arm
         mes_cpu=arm
         tcc_cpu=arm
         triplet=arm-unknown-linux-gnueabihf
         cross_prefix=${triplet}-
         have_float=${have_float-false}
         have_long_long=${have_long_long-true}
         have_setjmp=${have_setjmp-false}
         ;;
     *)
         cpu=x86
         mes_cpu=x86
         tcc_cpu=i386
         triplet=i686-unknown-linux-gnu
         cross_prefix=${triplet}-
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
export cpu
export cross_prefix
export mes_cpu
export tcc_cpu
export triplet
export have_float
export have_long_long
export have_setjmp

prefix=${prefix-usr}
export prefix
MES_PREFIX=${MES_PREFIX-mes-source}
MES_SOURCE=${MES_SOURCE-mes-source}
MES_LIB=${MES_LIB-$MES_PREFIX/lib}
MES_LIB=$MES_SOURCE/gcc-lib/${mes_cpu}-mes

ONE_SOURCE=${ONE_SOURCE-false}

export V
export MESCC
export MES_DEBUG
export MES_PREFIX
export MES_LIB
export MES_SOURCE
export ONE_SOURCE
export REBUILD_LIBC

CC=${CC-${cross_prefix}gcc}
CPPFLAGS="
-I $MES_PREFIX/include
-I $MES_PREFIX/lib
-D BOOTSTRAP=1
"

CFLAGS="
-fpack-struct
-nostdinc
-nostdlib
-fno-builtin
"

if test "$mes_cpu" = x86; then
    CPP_TARGET_FLAG="-D TCC_TARGET_I386=1"
elif test "$mes_cpu" = arm; then
    CFLAGS="$CFLAGS -marm"
    CPP_TARGET_FLAG="-D TCC_TARGET_ARM=1 -D TCC_ARM_VFP=1 -D CONFIG_TCC_LIBTCC1_MES=1"
elif test "$mes_cpu" = x86_64; then
    CPP_TARGET_FLAG="-D TCC_TARGET_X86_64=1"
else
    echo "cpu not supported: $mes_cpu"
fi

rm -f mes
ln -sf $MES_PREFIX mes

rm -f ${cross_prefix}tcc
unset C_INCLUDE_PATH LIBRARY_PATH

$CC -c $CPPFLAGS $CFLAGS $MES_PREFIX/lib/linux/$mes_cpu-mes-gcc/crt1.c
$CC -c $CPPFLAGS $CFLAGS $MES_PREFIX/lib/linux/$mes_cpu-mes-gcc/crti.c
$CC -c $CPPFLAGS $CFLAGS $MES_PREFIX/lib/linux/$mes_cpu-mes-gcc/crtn.c

cp $MES_LIB/libc+tcc.a .
cp $MES_LIB/libtcc1.a .
cp $MES_LIB/libc+tcc.a libc.a

mkdir -p $prefix/lib
absprefix=$(cd $prefix && pwd)

interpreter=/lib/mes-loader
export interpreter

if $ONE_SOURCE; then
    CFLAGS="$CFLAGS
--include=$MES_SOURCE/lib/linux/$cpu-mes-gcc/crt1.c
-Wl,-Ttext-segment=0x1000000
"
else
    LDFLAGS="
-L .
--include=$MES_SOURCE/lib/linux/$cpu-mes-gcc/crt1.c
-Wl,-Ttext-segment=0x1000000
"
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
    CPPFLAGS_TCC="$CPPFLAGS_TCC -D ONE_SOURCE=1"
fi

if $ONE_SOURCE; then
    $CC -g -o ${cross_prefix}tcc                \
        $CFLAGS                                 \
        $CPPFLAGS_TCC                           \
        tcc.c                                   \
        libtcc1.a                               \
        libc.a                                  \
        -lgcc                                   \
        libc.a
else
    $CC -g -c $CFLAGS $CPPFLAGS_TCC tccpp.c
    $CC -g -c $CFLAGS $CPPFLAGS_TCC tccgen.c
    $CC -g -c $CFLAGS $CPPFLAGS_TCC tccelf.c
    $CC -g -c $CFLAGS $CPPFLAGS_TCC tccrun.c
    $CC -g -c $CFLAGS $CPPFLAGS_TCC ${tcc_cpu}-gen.c
    $CC -g -c $CFLAGS $CPPFLAGS_TCC ${tcc_cpu}-link.c
    $CC -g -c $CFLAGS $CPPFLAGS_TCC ${tcc_cpu}-asm.c
    $CC -g -c $CFLAGS $CPPFLAGS_TCC tccasm.c
    $CC -g -c $CFLAGS $CPPFLAGS_TCC libtcc.c
    $CC -g -c $CFLAGS $CPPFLAGS_TCC tcc.c
    files="
tccpp.o
tccgen.o
tccelf.o
tccrun.o
${tcc_cpu}-gen.o
${tcc_cpu}-link.o
${tcc_cpu}-asm.o
tccasm.o
libtcc.o
tcc.o
"
    $CC                                         \
    -g                                          \
    $LDFLAGS                                    \
    $CPPFLAGS_TCC                               \
    -o ${cross_prefix}tcc                       \
    $files                                      \
    libtcc1.a                                   \
    libc.a                                      \
    -lgcc                                       \
    libc.a
fi

rm -rf ${cross_prefix}gcc-usr
mkdir -p ${cross_prefix}gcc-usr
cp *.a ${cross_prefix}gcc-usr
cp *.o ${cross_prefix}gcc-usr

mkdir -p $prefix/lib/tcc
cp -f libc.a $prefix/lib
cp -f libtcc1.a $prefix/lib/tcc

rm -f armeabi.o
cp libtcc1.a libtcc1-mes.a

# REBUILD_LIBC=true
# TCC=$CC sh -x boot.sh
# REBUILD_LIBC=true
# TCC=./tcc-boot0 sh boot.sh
# TCC=./tcc-boot1 sh boot.sh
# TCC=./tcc-boot2 sh boot.sh
# TCC=./tcc-boot3 sh boot.sh
# TCC=./tcc-boot4 sh boot.sh
# TCC=./tcc-boot5 sh boot.sh
# TCC=./tcc-boot6 sh boot.sh

# exit 22

rm -rf ${cross_prefix}gcc-boot
mkdir -p ${cross_prefix}gcc-boot
cp *.a ${cross_prefix}gcc-boot
cp *.o ${cross_prefix}gcc-boot

CC="./${cross_prefix}tcc"
AR="./${cross_prefix}tcc -ar"
CFLAGS=

REBUILD_LIBC=${REBUILD_LIBC-true}

$CC -c $CPPFLAGS $CFLAGS $MES_PREFIX/lib/linux/$mes_cpu-mes-gcc/crt1.c
$CC -c $CPPFLAGS $CFLAGS $MES_PREFIX/lib/linux/$mes_cpu-mes-gcc/crti.c
$CC -c $CPPFLAGS $CFLAGS $MES_PREFIX/lib/linux/$mes_cpu-mes-gcc/crtn.c

cp $MES_LIB/libc+tcc.a .
cp $MES_LIB/libtcc1.a .
cp $MES_LIB/libc+tcc.a libc.a

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
    $CC -c $CPPFLAGS $CPP_TARGET_FLAG $CFLAGS lib/libtcc1.c
    $AR cr libtcc1.a libtcc1.o

    if [ $mes_cpu = arm ]; then
        $CC -c -g $CPPFLAGS $CFLAGS $CPP_TARGET_FLAG lib/armeabi.c

        $CC -c -g $CPPFLAGS $CFLAGS $CPP_TARGET_FLAG -o libtcc1-tcc.o lib/libtcc1.c
        $AR rc libtcc1-tcc.a libtcc1-tcc.o armeabi.o

        $CC -c -g $CPPFLAGS $CFLAGS -D HAVE_FLOAT=1 -D HAVE_LONG_LONG=1 -o libtcc1-mes.o $MES_LIB/libtcc1.c
        $AR cr libtcc1-mes.a libtcc1-mes.o armeabi.o

        $CC -c -g $CPP_TARGET_FLAG $CFLAGS -o libtcc1.o lib/libtcc1.c
        $AR cr libtcc1.a libtcc1.o armeabi.o

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
        cp -f $MES_LIB/libtcc1.a $MES_LIB/libtcc1-mes.a
        cp -f libtcc1-mes.a $prefix/lib/tcc
    fi
fi

cp -f libc.a $prefix/lib
cp -f libtcc1.a $prefix/lib/tcc

rm -rf ${cross_prefix}tcc-usr
mkdir -p ${cross_prefix}tcc-usr
cp *.a ${cross_prefix}tcc-usr
cp *.o ${cross_prefix}tcc-usr
