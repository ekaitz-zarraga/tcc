#! /bin/sh
set -e

if test "$V" = 1 -o "$V" = 2; then
    set -x
fi

prefix=${prefix-/usr/local}
MES_PREFIX=${MES_PREFIX-mes}
MES_STACK=${MES_STACK-10000000}
export MES_STACK
interpreter=${interpreter-interpreter}
mescc=${mescc-$(command -v mescc)}

if test "$V" = 2; then
    sh $mescc --help
fi

CPPFLAGS="
-I .
-I $MES_PREFIX/lib
-I $MES_PREFIX/include
-D inline=
-D CONFIG_TCCDIR=\"$prefix/lib/tcc\"
-D CONFIG_TCC_CRTPREFIX=\"$prefix/lib:"{B}"/lib:.\"
-D CONFIG_TCC_ELFINTERP=\"$interpreter\"
-D CONFIG_TCC_LIBPATHS=\"$prefix/lib:"{B}"/lib:.\"
-D CONFIG_TCC_SYSINCLUDEPATHS=\"$MES_PREFIX/include:$prefix/include:"{B}"/include\"
-D TCC_LIBGCC=\"$prefix/lib/libc.a\"
-D BOOTSTRAP=1
-D CONFIG_TCCBOOT=1
-D CONFIG_TCC_STATIC=1
-D CONFIG_TCC_LIBTCC1=1
-D CONFIG_USE_LIBGCC=1
-D TCC_MES_LIBC=1
-D TCC_TARGET_I386=1
"
if test -n "$ONE_SOURCE"; then
    objects="tcc.o"
    CPPFLAGS="$CPPFLAGS -D ONE_SOURCE=1"
else
    objects="tcc.o tccpp.o tccgen.o tccelf.o tccrun.o i386-gen.o i386-link.o i386-asm.o tccasm.o libtcc.o"
fi

CFLAGS=
if test "$V" = 1; then
    CFLAGS="$CFLAGS -v"
elif test "$V" = 2; then
    CFLAGS="$CFLAGS -vv"
fi

for o in $objects; do
    i=$(basename $o .o)
    [ -z "$V" ] && echo "  CC         $i.c"
    sh $mescc\
       -c\
       -o $o\
       $CPPFLAGS\
       $CFLAGS\
       $i.c
done

[ -z "$V" ] && echo "  CCLD       mes-tcc"
sh $mescc $verbose -o mes-tcc $objects -L mes-source/mescc-lib -L mes-source/lib -l c+tcc

CC=${CC-mescc}

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
    ##cp -f ${MES_PREFIX}/gcc-lib/x86-mes/libc+gnu.c libc.c
    $CC -c $CPPFLAGS $CFLAGS libc.c
    $AR cr libc.a libc.o

    rm -f libtcc1.a
    cp -f ${MES_PREFIX}/lib/libtcc1.c .
    ##cp -f ${MES_PREFIX}/gcc-lib/x86-mes/libtcc1.c .
    $CC -c $CPPFLAGS $CFLAGS libtcc1.c
    $AR cr libtcc1.a libtcc1.o

    rm -f libgetopt.a
    cp -f ${MES_PREFIX}/lib/libgetopt.c .
    ##cp -f ${MES_PREFIX}/gcc-lib/x86-mes/libgetopt.c .
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

mkdir -p $prefix/lib/tcc
cp -f libc.a $prefix/lib
cp -f libtcc1.a $prefix/lib/tcc
cp -f libgetopt.a $prefix/lib

TCC=./mes-tcc sh boot.sh
TCC=./boot0-tcc sh boot.sh
TCC=./boot1-tcc sh boot.sh
TCC=./boot2-tcc sh boot.sh
TCC=./boot3-tcc sh boot.sh
TCC=./boot4-tcc sh boot.sh
cmp boot4-tcc boot5-tcc
cp -f boot4-tcc tcc

CC=./tcc
AR='./tcc -ar'
if true; then
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

echo "bootstrap.sh: done"
