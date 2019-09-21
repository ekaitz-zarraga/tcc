#! /bin/sh

set -e

export V
export MES_DEBUG
export MES_PREFIX
export prefix
export interpreter

if test "$V" = 1 -o "$V" = 2; then
    set -x
fi

rm -f tcc.E tcc.hex2 tcc.M1 tcc.m1 mes-tcc boot?-tcc

verbose=
if test "$V" = 1; then
    MESCCFLAGS="$MESCCFLAGS -v"
elif test "$V" = 2; then
    MESCCFLAGS="$MESCCFLAGS -vv"
fi

unset CPATH C_INCLUDE_PATH LIBRARY_PATH
prefix=${prefix-/usr/local}
mescc=${mescc-$(command -v mescc)}

GUIX=${GUIX-$(command -v guix||:)}
CC=${mescc-mescc}
MES=${MES-../mes/src/mes}
HEX2=${HEX2-hex2}
M1=${M1-M1}
BLOOD_ELF=${BLOOD_ELF-blood-elf}

MES_PREFIX=${MES_PREFIX-mes}
MES_SOURCE=${MES_SOURCE-mes-source}

if [ -z "$interpreter" -a -n "$GUIX" ]; then
    interpreter=$($GUIX environment --ad-hoc patchelf -- patchelf --print-interpreter $(guix build --system=i686-linux hello)/bin/hello)
elif [ -x /lib/ld-linux.so.2 ]; then
    # legacy non-GuixSD support
    interpreter=/lib/ld-linux.so.2
fi
interpreter=${interpreter-interpreter}
export interpreter

mkdir -p $prefix/lib

if test "$V" = 2; then
    sh $mescc --help
fi

if [ -n "$ONE_SOURCE" ]; then
    sh cc.sh tcc
    files="tcc.S"
else
    sh cc.sh tccpp
    sh cc.sh tccgen
    sh cc.sh tccelf
    sh cc.sh tccrun
    sh cc.sh i386-gen
    sh cc.sh i386-link
    sh cc.sh i386-asm
    sh cc.sh tccasm
    sh cc.sh libtcc
    sh cc.sh tcc
    files="
tccpp.S
tccgen.S
tccelf.S
tccrun.S
i386-gen.S
i386-link.S
i386-asm.S
tccasm.S
libtcc.S
tcc.S
"
fi

$MESCC\
    $MESCCFLAGS\
    -g\
    -o mes-tcc\
    -L $MES_SOURCE/lib\
    $files\
    -l c+tcc

host=${host-$($CC -dumpmachine 2>/dev/null)}
if test -z "$host$host_type"; then
    mes_cpu=${arch-$(get_machine || uname -m)}
else
    mes_cpu=${host%%-*}
fi
if test "$mes_cpu" = i386\
        || test "$mes_cpu" = i486\
        || test "$mes_cpu" = i586\
        || test "$mes_cpu" = i686; then
    mes_cpu=x86
fi
if test "$mes_cpu" = armv4\
        || test "$arch" = armv7l; then
    mes_cpu=arm
fi
if test "$mes_cpu" = amd64; then
    mes_cpu=x86_64
fi

case "$host" in
    *linux-gnu|*linux)
        mes_kernel=linux;;
    *gnu)
        mes_kernel=gnu;;
    *)
        mes_kernel=linux;;
esac

CC="./mes-tcc"
AR="./mes-tcc -ar"
CPPFLAGS="-I $MES_PREFIX/include -I $MES_PREFIX/include/$mes_kernel/$mes_cpu"
CFLAGS=

REBUILD_LIBC=${REBUILD_LIBC-t}

if [ -n "$REBUILD_LIBC" ]; then
    for i in 1 i n; do
        rm -f crt$i.o;
        cp -f $MES_PREFIX/lib/crt$i.c .
        ##cp -f $MES_PREFIX/gcc-lib/x86-mes/crt$i.c .
        $CC $CPPFLAGS $CFLAGS -static -nostdlib -nostdinc -c crt$i.c
    done

    rm -f libc.a
    cp -f ${MES_PREFIX}/lib/libc+gnu.c libc.c
    ## cp -f ${MES_PREFIX}/gcc-lib/x86-mes/libc+gnu.c libc.c
    $CC -c $CPPFLAGS $CFLAGS libc.c
    $AR cr libc.a libc.o

    rm -f libtcc1.a
    cp -f ${MES_PREFIX}/lib/libtcc1.c .
    ## cp -f ${MES_PREFIX}/gcc-lib/x86-mes/libtcc1.c .
    $CC -c $CPPFLAGS $CFLAGS libtcc1.c
    $AR cr libtcc1.a libtcc1.o

    rm -f libgetopt.a
    cp -f ${MES_PREFIX}/lib/libgetopt.c .
    ## cp -f ${MES_PREFIX}/gcc-lib/x86-mes/libgetopt.c .
    $CC -c $CPPFLAGS $CFLAGS libgetopt.c
    $AR cr libgetopt.a libgetopt.o

else
    cp -f $MES_PREFIX/lib/crt1.o .
    cp -f $MES_PREFIX/lib/crti.o .
    cp -f $MES_PREFIX/lib/crtn.o .
    cp -f $MES_PREFIX/lib/libc+gnu.a .
    cp -f $MES_PREFIX/lib/libtcc1.a .

    ## cp -f $MES_PREFIX/gcc-lib/libc+gnu.a libc.a
    ## cp -f $MES_PREFIX/gcc-lib/libtcc1.a .
    ## cp -f $MES_PREFIX/gcc-lib/crt1.o .
    ## cp -f $MES_PREFIX/gcc-lib/crti.o .
    ## cp -f $MES_PREFIX/gcc-lib/crtn.o .
fi

sh boot.sh
TCC=./boot0-tcc sh boot.sh
TCC=./boot1-tcc sh boot.sh
TCC=./boot2-tcc sh boot.sh
TCC=./boot3-tcc sh boot.sh

ln -f boot4-tcc tcc

CC=./tcc
AR='./tcc -ar'
if true; then
    for i in 1 i n; do
        rm -f crt$i.o;
        cp -f $MES_PREFIX/lib/crt$i.c .
        ##cp -f $MES_PREFIX/gcc-lib/x86-mes/crt$i.c .
        $CC $CPPFLAGS $CFLAGS -static -nostdlib -nostdinc -c crt$i.c
    done

    rm -f libc.a
    $CC -c $CPPFLAGS $CFLAGS libc.c
    $AR cr libc.a libc.o

    rm -f libtcc1.a
    $CC -c $CPPFLAGS $CFLAGS libtcc1.c
    $AR cr libtcc1.a libtcc1.o

    rm -f libgetopt.a
    $CC -c $CPPFLAGS $CFLAGS libgetopt.c
    $AR cr libgetopt.a libgetopt.o

    cp -f libc.a $prefix/lib
    cp -f libtcc1.a $prefix/lib/tcc
    cp -f libgetopt.a $prefix/lib
fi

echo "build.sh: done"
