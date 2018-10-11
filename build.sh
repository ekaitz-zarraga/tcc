#! /bin/sh

set -e

export BUILD_DEBUG
export MES_DEBUG
export MES_PREFIX
export PREFIX
export MES_SEED
export interpreter

if [ -n "$BUILD_DEBUG" ]; then
    set -x
    MESCCFLAGS="$MESCCFLAGS -v"
fi

rm -f tcc.E tcc.hex2 tcc.M1 tcc.m1 mes-tcc boot?-tcc

unset C_INCLUDE_PATH LIBRARY_PATH
PREFIX=${PREFIX-usr}
GUIX=${GUIX-$(command -v guix||:)}
CC=${MESCC-mescc}
MES=${MES-../mes/src/mes}
MESCC=${MESCC-mescc}
HEX2=${HEX2-hex2}
M1=${M1-M1}
BLOOD_ELF=${BLOOD_ELF-blood-elf}

MES_PREFIX=${MES_PREFIX-${MESCC%/*}/../share/mes}
#MES_PREFIX=${MES_PREFIX-../mes}
MES_SEED=${MES_SEED-../mes-seed}
cp $MES_SEED/x86-mes-gcc/crt1.o crt1.o
cp $MES_SEED/x86-mes-gcc/crti.o crti.o
cp $MES_SEED/x86-mes-gcc/crtn.o crtn.o

if [ -z "$interpreter" -a -n "$GUIX" ]; then
    interpreter=$($GUIX environment --ad-hoc patchelf -- patchelf --print-interpreter $(guix build --system=i686-linux hello)/bin/hello)
elif [ -x /lib/ld-linux.so.2 ]; then
    # legacy non-GuixSD support
    interpreter=/lib/ld-linux.so.2
fi
interpreter=${interpreter-interpreter}
export interpreter

mkdir -p $PREFIX/lib
ABSPREFIX=$(cd $PREFIX && pwd)
cp $MES_SEED/x86-mes-gcc/libc+tcc.o $ABSPREFIX/lib


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
    -L $MES_SEED\
    -l c+tcc\
    $files\
    $MES_SEED/x86-mes/libc+tcc.o

rm -f libc.a
if false; then
    # ../mes/lib/linux-gcc.c:33: error: bad operand with opcode 'mov'
    # it works with bootx-tcc
    ./mes-tcc -c -I $MES_PREFIX/include -I $MES_PREFIX/lib $MES_PREFIX/lib/libc+gnu.c
    ./mes-tcc -ar rc libc.a libc+gnu.o
else
    ##./mes-tcc -ar rc libc.a $MES_SEED/x86-mes-gcc/libc+gnu.o
    cp -f $MES_SEED/x86-mes-gcc/libc+gnu.o .
    ./mes-tcc -ar rc libc.a libc+gnu.o
fi
rm -f libtcc1.a
cp -f $MES_SEED/x86-mes-gcc/libtcc1.o .
./mes-tcc -ar rc libtcc1.a libtcc1.o

sh boot.sh
TCC=./boot0-tcc sh boot.sh
TCC=./boot1-tcc sh boot.sh
TCC=./boot2-tcc sh boot.sh
TCC=./boot3-tcc sh boot.sh

ln -f boot4-tcc tcc
