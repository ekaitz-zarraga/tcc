#! /bin/sh

set -e

if [ "$V" = 1 -o "$V" = 2 ]; then
    set -x
fi

if [ "$TCC" = ./mes-tcc ]; then
    PROGRAM_PREFIX=${PROGRAM_PREFIX-boot0-}
elif [ "$TCC" = ./boot0-tcc ]; then
    PROGRAM_PREFIX=${PROGRAM_PREFIX-boot1-}
elif [ "$TCC" = ./boot1-tcc ]; then
    PROGRAM_PREFIX=${PROGRAM_PREFIX-boot2-}
elif [ "$TCC" = ./boot2-tcc ]; then
    PROGRAM_PREFIX=${PROGRAM_PREFIX-boot3-}
elif [ "$TCC" = ./boot3-tcc ]; then
    PROGRAM_PREFIX=${PROGRAM_PREFIX-boot4-}
elif [ "$TCC" = ./boot4-tcc ]; then
    PROGRAM_PREFIX=${PROGRAM_PREFIX-boot5-}
elif [ "$TCC" = ./boot5-tcc ]; then
    PROGRAM_PREFIX=${PROGRAM_PREFIX-boot6-}
elif [ "$TCC" = ./boot6-tcc ]; then
    PROGRAM_PREFIX=${PROGRAM_PREFIX-boot7-}
elif [ "$TCC" = ./boot7-tcc ]; then
    PROGRAM_PREFIX=${PROGRAM_PREFIX-boot8-}
elif [ "$TCC" = ./boot8-tcc ]; then
    PROGRAM_PREFIX=${PROGRAM_PREFIX-boot9-}
fi

unset C_INCLUDE_PATH LIBRARY_PATH
prefix=${prefix-/usr/local}
mkdir -p $prefix
absprefix=$(cd $prefix && pwd)
GUIX=${GUIX-$(command -v guix||:)}
MES_PREFIX=${MES_PREFIX-mes}
C_INCLUDE_PATH=${C_INCLUDE_PATH-$MES_PREFIX/include}
LIBRARY_PATH=${LIBRARY_PATH-..$MES_PREFIX/lib}

if [ -z "$interpreter" -a -n "$GUIX" ]; then
    interpreter=$($GUIX environment --ad-hoc patchelf -- patchelf --print-interpreter $(guix build --system=i686-linux hello)/bin/hello)
elif [ -x /lib/ld-linux.so.2 ]; then
    # legacy non-GuixSD support
    interpreter=/lib/ld-linux.so.2
fi
interpreter=${interpreter-interpreter}

if [ "$PROGRAM_PREFIX" = "boot0-" ]; then
    BOOT_CPPFLAGS=${BOOT_CPPFLAGS-"
        -D inline=
    -D BOOTSTRAP=1
    -D HAVE_FLOAT_STUB=1
    -D CONFIG_TCCBOOT=1
    -D CONFIG_USE_LIBGCC=1
    -D TCC_MES_LIBC=1
    "}
    LIBTCC1=-ltcc1
    LIBTCC1=
elif [ "$PROGRAM_PREFIX" = "boot1-" ]; then
    BOOT_CPPFLAGS=${BOOT_CPPFLAGS-"
    -D BOOTSTRAP=1
    -D HAVE_BITFIELD=1
    -D HAVE_FLOAT_STUB=1
    -D CONFIG_TCCBOOT=1
    -D CONFIG_USE_LIBGCC=1
    -D TCC_MES_LIBC=1
    "}
    LIBTCC1=-ltcc1
    LIBTCC1=
elif [ "$PROGRAM_PREFIX" = "boot2-" ]; then
    BOOT_CPPFLAGS=${BOOT_CPPFLAGS-"
    -D BOOTSTRAP=1
    -D HAVE_BITFIELD=1
    -D HAVE_FLOAT_STUB=1
    -D HAVE_LONG_LONG=1
    -D CONFIG_TCCBOOT=1
    -D CONFIG_USE_LIBGCC=1
    -D TCC_MES_LIBC=1
    "}
    LIBTCC1=-ltcc1
    LIBTCC1=
elif [ "$PROGRAM_PREFIX" = "boot3-" ]; then
    BOOT_CPPFLAGS=${BOOT_CPPFLAGS-"
    -D BOOTSTRAP=1
    -D HAVE_FLOAT=1
    -D HAVE_BITFIELD=1
    -D HAVE_LONG_LONG=1
    -D CONFIG_TCCBOOT=1
    -D CONFIG_USE_LIBGCC=1
    -D TCC_MES_LIBC=1
    "}
    LIBTCC1=-ltcc1
    LIBTCC1=
else
    BOOT_CPPFLAGS=${BOOT_CPPFLAGS-"
    -D BOOTSTRAP=1
    -D HAVE_FLOAT=1
    -D HAVE_BITFIELD=1
    -D HAVE_LONG_LONG=1
    -D CONFIG_TCCBOOT=1
    -D CONFIG_USE_LIBGCC=1
    -D TCC_MES_LIBC=1
    "}
    LIBTCC1=-ltcc1
    LIBTCC1=
fi

echo $TCC\
     -g\
     -v\
     -static\
     -o ${PROGRAM_PREFIX}tcc\
     $BOOT_CPPFLAGS\
     -I .\
     -I $MES_PREFIX/include\
     -D TCC_TARGET_I386\
     -D CONFIG_TCCDIR=\"$prefix/lib/tcc\"\
     -D CONFIG_TCC_CRTPREFIX=\"$prefix/lib:"{B}"/lib:.\"\
     -D CONFIG_TCC_ELFINTERP=\"$interpreter\"\
     -D CONFIG_TCC_LIBPATHS=\"$absprefix/lib:"{B}"/lib:.\"\
     -D CONFIG_TCC_SYSINCLUDEPATHS=\"$MES_PREFIX/include:$prefix/include:"{B}"/include\"\
     -D TCC_LIBGCC=\"$absprefix/lib/libc.a\"\
     -D ONE_SOURCE=yes\
     -D CONFIG_TCC_LIBTCC1=1\
     -D CONFIG_TCC_STATIC=1\
     -D TCC_TARGET_I386=1\
     -L .\
     tcc.c\
     $LIBTCC1

./$TCC\
    -g\
    -v\
    -static\
    -o ${PROGRAM_PREFIX}tcc\
    $BOOT_CPPFLAGS\
    -I .\
    -I $MES_PREFIX/include\
    -D TCC_TARGET_I386\
    -D CONFIG_TCCDIR=\"$prefix/lib/tcc\"\
    -D CONFIG_TCC_CRTPREFIX=\"$prefix/lib:"{B}"/lib:.\"\
    -D CONFIG_TCC_ELFINTERP=\"$interpreter\"\
    -D CONFIG_TCC_LIBPATHS=\"$absprefix/lib:"{B}"/lib:.\"\
    -D CONFIG_TCC_SYSINCLUDEPATHS=\"$MES_PREFIX/include:$prefix/include:"{B}"/include\"\
    -D TCC_LIBGCC=\"$absprefix/lib/libc.a\"\
    -D ONE_SOURCE=yes\
    -D CONFIG_TCC_LIBTCC1=1\
    -D CONFIG_TCC_STATIC=1\
    -D TCC_TARGET_I386=1\
    -L .\
    tcc.c\
    $LIBTCC1

for i in 1 i n; do
    rm -f crt$i.o;
    ./${PROGRAM_PREFIX}tcc -c crt$i.c
done

rm -f libtcc1.a
./${PROGRAM_PREFIX}tcc -c -g -D TCC_TARGET_I386=1 -o libtcc1.o lib/libtcc1.c
./${PROGRAM_PREFIX}tcc -ar rc libtcc1.a libtcc1.o
cp -f libtcc1.a $prefix/lib/tcc

echo "boot.sh: done"
