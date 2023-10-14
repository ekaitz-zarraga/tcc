#! /bin/sh

set -e

if [ "$V" = 1 -o "$V" = 2 ]; then
    set -x
fi

arch=${arch-$(uname -m)}
case $arch in
     aarch*)
         cpu=arm
         mes_cpu=arm
         tcc_cpu=arm
         triplet=arm-linux-gnueabihf
         cross_prefix=${triplet}-
         ;;
     arm*|aarch*)
         cpu=arm
         mes_cpu=arm
         tcc_cpu=arm
         triplet=arm-unknown-linux-gnueabihf
         cross_prefix=${triplet}-
         ;;
     *)
         cpu=x86
         mes_cpu=x86
         tcc_cpu=i386
         triplet=i686-unknown-linux-gnu
         cross_prefix=${triplet}-
         ;;
esac

if [ "$TCC" = ./tcc-mes ]; then
    program_suffix=${program_suffix--boot0}
elif [ "$TCC" = ./tcc-boot0 ]; then
    program_suffix=${program_suffix--boot1}
elif [ "$TCC" = ./tcc-boot1 ]; then
    program_suffix=${program_suffix--boot2}
elif [ "$TCC" = ./tcc-boot2 ]; then
    program_suffix=${program_suffix--boot3}
elif [ "$TCC" = ./tcc-boot3 ]; then
    program_suffix=${program_suffix--boot4}
elif [ "$TCC" = ./tcc-boot4 ]; then
    program_suffix=${program_suffix--boot5}
elif [ "$TCC" = ./tcc-boot5 ]; then
    program_suffix=${program_suffix--boot6}
elif [ "$TCC" = ./tcc-boot6 ]; then
    program_suffix=${program_suffix--boot7}
elif [ "$TCC" = ./tcc-boot7 ]; then
    program_suffix=${program_suffix--boot8}
elif [ "$TCC" = ./tcc-boot8 ]; then
    program_suffix=${program_suffix--boot9}
elif [ "$TCC" = ./tcc-gcc ]; then
    program_suffix=${program_suffix--boot0}
elif [ "$TCC" = ${cross_prefix}gcc ]; then
    program_suffix=${program_suffix--boot0}
elif [ "$TCC" = ./${cross_prefix}tcc ]; then
    program_suffix=${program_suffix--boot0}
else
    program_suffix=${program_suffix--foo}
fi

unset C_INCLUDE_PATH LIBRARY_PATH
prefix=${prefix-/usr/local}
mkdir -p $prefix
absprefix=$(cd $prefix && pwd)
GUIX=${GUIX-$(command -v guix||:)}
MES_PREFIX=${MES_PREFIX-mes}
MES_LIB=${MES_LIB-$MES_PREFIX/lib}
C_INCLUDE_PATH=${C_INCLUDE_PATH-$MES_PREFIX/include}
LIBRARY_PATH=${LIBRARY_PATH-..$MES_PREFIX/lib}
interpreter=/lib/mes-loader

if [ "$program_suffix" = "-boot0" ]; then
    BOOT_CPPFLAGS_TCC="
    -D BOOTSTRAP=1
"
    if $have_long_long; then
        BOOT_CPPFLAGS_TCC="$BOOT_CPPFLAGS_TCC -D HAVE_LONG_LONG_STUB=1"
    fi
elif [ "$program_suffix" = "-boot1" ]; then
    BOOT_CPPFLAGS_TCC="
    -D BOOTSTRAP=1
    -D HAVE_BITFIELD=1
"
    if $have_long_long; then
        BOOT_CPPFLAGS_TCC="$BOOT_CPPFLAGS_TCC -D HAVE_LONG_LONG=1"
    fi
elif [ "$program_suffix" = "-boot2" ]; then
    BOOT_CPPFLAGS_TCC="
    -D BOOTSTRAP=1
    -D HAVE_BITFIELD=1
"
    if $have_float; then
        BOOT_CPPFLAGS_TCC="$BOOT_CPPFLAGS_TCC -D HAVE_FLOAT_STUB=1"
    fi
    if $have_long_long; then
        BOOT_CPPFLAGS_TCC="$BOOT_CPPFLAGS_TCC -D HAVE_LONG_LONG=1"
    fi
elif [ "$program_suffix" = "-boot3" ]; then
    BOOT_CPPFLAGS_TCC="
    -D BOOTSTRAP=1
    -D HAVE_BITFIELD=1
"
    if $have_float; then
        BOOT_CPPFLAGS_TCC="$BOOT_CPPFLAGS_TCC -D HAVE_FLOAT=1"
    fi
    if $have_long_long; then
        BOOT_CPPFLAGS_TCC="$BOOT_CPPFLAGS_TCC -D HAVE_LONG_LONG=1"
    fi
else
    BOOT_CPPFLAGS_TCC="
    -D BOOTSTRAP=1
    -D HAVE_BITFIELD=1
"
    if $have_float; then
        BOOT_CPPFLAGS_TCC="$BOOT_CPPFLAGS_TCC -D HAVE_FLOAT=1"
    fi
    if $have_long_long; then
        BOOT_CPPFLAGS_TCC="$BOOT_CPPFLAGS_TCC -D HAVE_LONG_LONG=1"
    fi
fi

if $have_setjmp; then
    BOOT_CPPFLAGS_TCC="$BOOT_CPPFLAGS_TCC -D HAVE_SETJMP=1"
fi

if test "$mes_cpu" = x86; then
    CPP_TARGET_FLAG="-D TCC_TARGET_I386=1"
elif test "$mes_cpu" = arm; then
    CPP_TARGET_FLAG="-D TCC_TARGET_ARM=1 -D TCC_ARM_VFP=1 -D CONFIG_TCC_LIBTCC1_MES=1"
elif test "$mes_cpu" = x86_64; then
    BOOT_CPPFLAGS_TCC="$BOOT_CPPFLAGS_TCC -D HAVE_SETJMP=1"
    CPP_TARGET_FLAG="-D TCC_TARGET_X86_64=1"
else
    echo "cpu not supported: $mes_cpu"
fi

CPPFLAGS_TCC="
-I .
-I $MES_PREFIX/lib
-I $MES_PREFIX/include
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
    files="tcc.c"
else
    $TCC -g -v -c $BOOT_CPPFLAGS_TCC $CPPFLAGS_TCC tccpp.c
    $TCC -g -v -c $BOOT_CPPFLAGS_TCC $CPPFLAGS_TCC tccgen.c
    $TCC -g -v -c $BOOT_CPPFLAGS_TCC $CPPFLAGS_TCC tccelf.c
    $TCC -g -v -c $BOOT_CPPFLAGS_TCC $CPPFLAGS_TCC tccrun.c
    $TCC -g -v -c $BOOT_CPPFLAGS_TCC $CPPFLAGS_TCC ${tcc_cpu}-gen.c
    $TCC -g -v -c $BOOT_CPPFLAGS_TCC $CPPFLAGS_TCC ${tcc_cpu}-link.c
    $TCC -g -v -c $BOOT_CPPFLAGS_TCC $CPPFLAGS_TCC ${tcc_cpu}-asm.c
    $TCC -g -v -c $BOOT_CPPFLAGS_TCC $CPPFLAGS_TCC tccasm.c
    $TCC -g -v -c $BOOT_CPPFLAGS_TCC $CPPFLAGS_TCC libtcc.c
    $TCC -g -v -c $BOOT_CPPFLAGS_TCC $CPPFLAGS_TCC tcc.c
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
fi

tcc=${program_prefix}tcc${program_suffix}

echo $TCC                                       \
     -g                                         \
     -v                                         \
     -static                                    \
     -o $tcc                                    \
     $BOOT_CPPFLAGS_TCC                         \
     $CPPFLAGS_TCC                              \
     -L .                                       \
     $files

$TCC                                            \
    -g                                          \
    -v                                          \
    -static                                     \
     -o $tcc                                    \
    $BOOT_CPPFLAGS_TCC                          \
    $CPPFLAGS_TCC                               \
    -L .                                        \
    $files

if $REBUILD_LIBC; then
    for i in 1 i n; do
        cp -f $MES_LIB/crt$i.c .
        ./$tcc -c -g -o crt$i${program_suffix}.o crt$i.c
        cp -f crt$i${program_suffix}.o crt$i.o
    done

    rm -f libtcc1.a
    ./$tcc -c -g $CPP_TARGET_FLAG -D HAVE_FLOAT=1 -o libtcc1.o $MES_LIB/libtcc1.c
    ./$tcc -ar rc libtcc1.a libtcc1.o

    if [ $mes_cpu = arm ]; then
        ./$tcc -c -g $BOOT_CPPFLAGS_TCC lib/armeabi.c
        ./$tcc -c -g $CPP_TARGET_FLAG $BOOT_CPPFLAGS_TCC -o libtcc1-tcc.o lib/libtcc1.c
        ./$tcc -ar rc libtcc1-tcc.a libtcc1-tcc.o armeabi.o

        # BOOTSTRAP: => Bus error
        ##./$tcc -c -g $CPP_TARGET_FLAG $BOOT_CPPFLAGS_TCC -o libtcc1-mes.o $MES_LIB/libtcc1.c
        ##./$tcc -c -g $CPP_TARGET_FLAG -D BOOTSTRAP=1 -D HAVE_FLOAT=1 -D HAVE_LONG_LONG=1 -o libtcc1-mes.o $MES_LIB/libtcc1.c
        ./$tcc -c -g $CPP_TARGET_FLAG -D HAVE_FLOAT=1 -D HAVE_LONG_LONG=1 -o libtcc1-mes.o $MES_LIB/libtcc1.c
        ./$tcc -ar rc libtcc1-mes.a libtcc1-mes.o armeabi.o

        ./$tcc -c -g $CPP_TARGET_FLAG $BOOT_CPPFLAGS_TCC -o libtcc1.o lib/libtcc1.c
        ./$tcc -ar rc libtcc1.a libtcc1.o armeabi.o
        cp -f libtcc1-mes.a $prefix/lib/tcc
    fi

    cp -f libtcc1.a $prefix/lib/tcc
fi

echo "boot.sh: done"
