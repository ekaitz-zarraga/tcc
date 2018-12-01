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
fi

unset C_INCLUDE_PATH LIBRARY_PATH
PREFIX=${PREFIX-usr}
mkdir -p $PREFIX
ABSPREFIX=$(cd $PREFIX && pwd && (cd - 2>&1 >/dev/null)) # FIXME: Gash
GUIX=${GUIX-$(command -v guix||:)}
MES_PREFIX=${MES_PREFIX-../mes}
##MES_PREFIX=${MES_PREFIX-$(dirname $MESCC)/../share/mes}
C_INCLUDE_PATH=${C_INCLUDE_PATH-$MES_PREFIX/include}
MES_SEED=${MES_SEED-../mes-seed}
LIBRARY_PATH=${LIBRARY_PATH-..$MES_SEED}

if [ -z "$interpreter" -a -n "$GUIX" ]; then
    interpreter=$($GUIX environment --ad-hoc patchelf -- patchelf --print-interpreter $(guix build --system=i686-linux hello)/bin/hello)
elif [ -x /lib/ld-linux.so.2 ]; then
    # legacy non-GuixSD support
    interpreter=/lib/ld-linux.so.2
fi
interpreter=${interpreter-interpreter}

if [ "$(basename $SHELL)" = gash ]; then

    if [ "$PROGRAM_PREFIX" = "boot0-" ]; then
        ./$TCC\
        -v\
        -static\
        -o ${PROGRAM_PREFIX}tcc\
        -D inline=\
        -D BOOTSTRAP=1\
        -D HAVE_FLOAT_STUB=1\
        -D CONFIG_TCCBOOT=1\
        -D CONFIG_USE_LIBGCC=1\
        -D TCC_MES_LIBC=1\
        -I .\
        -I $MES_PREFIX/include\
        -D TCC_TARGET_I386\
        -D CONFIG_TCCDIR=\"$PREFIX/lib/tcc\"\
        -D CONFIG_TCC_CRTPREFIX=\"$PREFIX/lib:"{B}"/lib:.\"\
        -D CONFIG_TCC_ELFINTERP=\"$interpreter\"\
        -D CONFIG_TCC_LIBPATHS=\"$ABSPREFIX/lib:"{B}"/lib:.\"\
        -D CONFIG_TCC_SYSINCLUDEPATHS=\"$MES_PREFIX/include:$PREFIX/include:"{B}"/include\"\
        -D TCC_LIBGCC=\"$ABSPREFIX/lib/libc.a\"\
        -D ONE_SOURCE=yes\
        -D CONFIG_TCC_LIBTCC1=1\
        -D CONFIG_TCC_STATIC=1\
        -D TCC_TARGET_I386=1\
        -L .\
        -L $MES_SEED\
        tcc.c\
        -ltcc1
    elif [ "$PROGRAM_PREFIX" = "boot1-" ]; then
        ./$TCC\
        -v\
        -static\
        -o ${PROGRAM_PREFIX}tcc\
        -D BOOTSTRAP=1\
        -D HAVE_BITFIELD=1\
        -D HAVE_FLOAT_STUB=1\
        -D CONFIG_TCCBOOT=1\
        -D CONFIG_USE_LIBGCC=1\
        -D TCC_MES_LIBC=1\
        -I .\
        -I $MES_PREFIX/include\
        -D TCC_TARGET_I386\
        -D CONFIG_TCCDIR=\"$PREFIX/lib/tcc\"\
        -D CONFIG_TCC_CRTPREFIX=\"$PREFIX/lib:"{B}"/lib:.\"\
        -D CONFIG_TCC_ELFINTERP=\"$interpreter\"\
        -D CONFIG_TCC_LIBPATHS=\"$ABSPREFIX/lib:"{B}"/lib:.\"\
        -D CONFIG_TCC_SYSINCLUDEPATHS=\"$MES_PREFIX/include:$PREFIX/include:"{B}"/include\"\
        -D TCC_LIBGCC=\"$ABSPREFIX/lib/libc.a\"\
        -D ONE_SOURCE=yes\
        -D CONFIG_TCC_LIBTCC1=1\
        -D CONFIG_TCC_STATIC=1\
        -D TCC_TARGET_I386=1\
        -L .\
        -L $MES_SEED\
        tcc.c\
        -ltcc1
    elif [ "$PROGRAM_PREFIX" = "boot2-" ]; then
        ./$TCC\
        -v\
        -static\
        -o ${PROGRAM_PREFIX}tcc\
        -D BOOTSTRAP=1\
        -D HAVE_BITFIELD=1\
        -D HAVE_FLOAT_STUB=1\
        -D HAVE_LONG_LONG=1\
        -D CONFIG_TCCBOOT=1\
        -D CONFIG_USE_LIBGCC=1\
        -D TCC_MES_LIBC=1\
        -I .\
        -I $MES_PREFIX/include\
        -D TCC_TARGET_I386\
        -D CONFIG_TCCDIR=\"$PREFIX/lib/tcc\"\
        -D CONFIG_TCC_CRTPREFIX=\"$PREFIX/lib:"{B}"/lib:.\"\
        -D CONFIG_TCC_ELFINTERP=\"$interpreter\"\
        -D CONFIG_TCC_LIBPATHS=\"$ABSPREFIX/lib:"{B}"/lib:.\"\
        -D CONFIG_TCC_SYSINCLUDEPATHS=\"$MES_PREFIX/include:$PREFIX/include:"{B}"/include\"\
        -D TCC_LIBGCC=\"$ABSPREFIX/lib/libc.a\"\
        -D ONE_SOURCE=yes\
        -D CONFIG_TCC_LIBTCC1=1\
        -D CONFIG_TCC_STATIC=1\
        -D TCC_TARGET_I386=1\
        -L .\
        -L $MES_SEED\
        tcc.c\
        -ltcc1
    elif [ "$PROGRAM_PREFIX" = "boot3-" ]; then
        ./$TCC\
        -v\
        -static\
        -o ${PROGRAM_PREFIX}tcc\
        -D BOOTSTRAP=1\
        -D HAVE_FLOAT=1\
        -D HAVE_BITFIELD=1\
        -D HAVE_LONG_LONG=1\
        -D CONFIG_TCCBOOT=1\
        -D CONFIG_USE_LIBGCC=1\
        -D TCC_MES_LIBC=1\
        -I .\
        -I $MES_PREFIX/include\
        -D TCC_TARGET_I386\
        -D CONFIG_TCCDIR=\"$PREFIX/lib/tcc\"\
        -D CONFIG_TCC_CRTPREFIX=\"$PREFIX/lib:"{B}"/lib:.\"\
        -D CONFIG_TCC_ELFINTERP=\"$interpreter\"\
        -D CONFIG_TCC_LIBPATHS=\"$ABSPREFIX/lib:"{B}"/lib:.\"\
        -D CONFIG_TCC_SYSINCLUDEPATHS=\"$MES_PREFIX/include:$PREFIX/include:"{B}"/include\"\
        -D TCC_LIBGCC=\"$ABSPREFIX/lib/libc.a\"\
        -D ONE_SOURCE=yes\
        -D CONFIG_TCC_LIBTCC1=1\
        -D CONFIG_TCC_STATIC=1\
        -D TCC_TARGET_I386=1\
        -L .\
        -L $MES_SEED\
        tcc.c
    elif [ "$PROGRAM_PREFIX" = "boot4-" ]; then
        ./$TCC\
        -v\
        -static\
        -o ${PROGRAM_PREFIX}tcc\
        -D BOOTSTRAP=1\
        -D HAVE_FLOAT=1\
        -D HAVE_BITFIELD=1\
        -D HAVE_LONG_LONG=1\
        -D CONFIG_TCCBOOT=1\
        -D CONFIG_USE_LIBGCC=1\
        -D TCC_MES_LIBC=1\
        -I .\
        -I $MES_PREFIX/include\
        -D TCC_TARGET_I386\
        -D CONFIG_TCCDIR=\"$PREFIX/lib/tcc\"\
        -D CONFIG_TCC_CRTPREFIX=\"$PREFIX/lib:"{B}"/lib:.\"\
        -D CONFIG_TCC_ELFINTERP=\"$interpreter\"\
        -D CONFIG_TCC_LIBPATHS=\"$ABSPREFIX/lib:"{B}"/lib:.\"\
        -D CONFIG_TCC_SYSINCLUDEPATHS=\"$MES_PREFIX/include:$PREFIX/include:"{B}"/include\"\
        -D TCC_LIBGCC=\"$ABSPREFIX/lib/libc.a\"\
        -D ONE_SOURCE=yes\
        -D CONFIG_TCC_LIBTCC1=1\
        -D CONFIG_TCC_STATIC=1\
        -D TCC_TARGET_I386=1\
        -L .\
        -L $MES_SEED\
        tcc.c
    fi

else

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
    elif [ "$PROGRAM_PREFIX" = "boot4-" ]; then
        BOOT_CPPFLAGS=${BOOT_CPPFLAGS-"
    -D BOOTSTRAP=1
    -D HAVE_FLOAT=1
    -D HAVE_BITFIELD=1
    -D HAVE_LONG_LONG=1
    -D CONFIG_TCCBOOT=1
    -D CONFIG_USE_LIBGCC=1
    -D TCC_MES_LIBC=1
    "}
    fi

    echo $TCC\
        -v\
        -static\
        -o ${PROGRAM_PREFIX}tcc\
        $BOOT_CPPFLAGS\
        -I .\
        -I $MES_PREFIX/include\
        -D TCC_TARGET_I386\
        -D CONFIG_TCCDIR=\"$PREFIX/lib/tcc\"\
        -D CONFIG_TCC_CRTPREFIX=\"$PREFIX/lib:"{B}"/lib:.\"\
        -D CONFIG_TCC_ELFINTERP=\"$interpreter\"\
        -D CONFIG_TCC_LIBPATHS=\"$ABSPREFIX/lib:"{B}"/lib:.\"\
        -D CONFIG_TCC_SYSINCLUDEPATHS=\"$MES_PREFIX/include:$PREFIX/include:"{B}"/include\"\
        -D TCC_LIBGCC=\"$ABSPREFIX/lib/libc.a\"\
        -D ONE_SOURCE=yes\
        -D CONFIG_TCC_LIBTCC1=1\
        -D CONFIG_TCC_STATIC=1\
        -D TCC_TARGET_I386=1\
        -L .\
        -L $MES_SEED\
        tcc.c\
        $LIBTCC1

    ./$TCC\
        -v\
        -static\
        -o ${PROGRAM_PREFIX}tcc\
        $BOOT_CPPFLAGS\
        -I .\
        -I $MES_PREFIX/include\
        -D TCC_TARGET_I386\
        -D CONFIG_TCCDIR=\"$PREFIX/lib/tcc\"\
        -D CONFIG_TCC_CRTPREFIX=\"$PREFIX/lib:"{B}"/lib:.\"\
        -D CONFIG_TCC_ELFINTERP=\"$interpreter\"\
        -D CONFIG_TCC_LIBPATHS=\"$ABSPREFIX/lib:"{B}"/lib:.\"\
        -D CONFIG_TCC_SYSINCLUDEPATHS=\"$MES_PREFIX/include:$PREFIX/include:"{B}"/include\"\
        -D TCC_LIBGCC=\"$ABSPREFIX/lib/libc.a\"\
        -D ONE_SOURCE=yes\
        -D CONFIG_TCC_LIBTCC1=1\
        -D CONFIG_TCC_STATIC=1\
        -D TCC_TARGET_I386=1\
        -L .\
        -L $MES_SEED\
        tcc.c\
        $LIBTCC1
fi

for i in 1 i n; do
    rm -f crt$i.o;
    ./${PROGRAM_PREFIX}tcc -c $MES_PREFIX/lib/linux/x86-mes-gcc/crt$i.c
done

rm -f libtcc1.a
./${PROGRAM_PREFIX}tcc -c -g -D TCC_TARGET_I386=1 -o libtcc1.o lib/libtcc1.c
./${PROGRAM_PREFIX}tcc -ar rc libtcc1.a libtcc1.o
mkdir -p $PREFIX/lib/tcc
cp libtcc1.a $PREFIX/lib/tcc
cp -f libtcc1.a $PREFIX/lib/tcc
echo "boot.sh: done"
