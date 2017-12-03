#! /bin/sh

set -ex

t=${1-t}
rm -f "scaffold/tests/$t".i686-unknown-linux-gnu-out
rm -f "scaffold/tests/$t".mes-out

MESCC=${MESCC-mescc}
MES_PREFIX=${MES_PREFIX-$(dirname $MESCC)/../share/mes}
TINYCC_SEED=${TINYCC_SEED-../tinycc-seed}
OBJDUMP=${OBJDUMP-objdump}

mkdir -p scaffold/tests

if [ -x ./i686-unknown-linux-gnu-tcc ]; then
    ./i686-unknown-linux-gnu-tcc\
        -c\
        -o scaffold/tests/"$t".i686-unknown-linux-gnu-o\
        -I $MES_PREFIX/include\
        -I $MES_PREFIX/scaffold/tests\
        $MES_PREFIX/scaffold/tests/"$t".c &> 1
    $OBJDUMP -d scaffold/tests/"$t".i686-unknown-linux-gnu-o > 1.s

    ./i686-unknown-linux-gnu-tcc\
        -static\
        -o scaffold/tests/"$t".i686-unknown-linux-gnu-out\
        -I $MES_PREFIX/include\
        -I $MES_PREFIX/scaffold/tests\
        $MES_PREFIX/scaffold/tests/"$t".c &> 1.elf

    set +e
    scaffold/tests/"$t".i686-unknown-linux-gnu-out
    r=$?
    #$OBJDUMP -d scaffold/tests/"$t".i686-unknown-linux-gnu-out > 1.x
    set -e
else
    r=0
fi

./mes-tcc\
    -c\
    -o scaffold/tests/"$t".mes-o\
    -I $MES_PREFIX/include\
    -I $MES_PREFIX/scaffold/tests\
    $MES_PREFIX/scaffold/tests/"$t".c &> 2
$OBJDUMP -d scaffold/tests/"$t".mes-o > 2.s
./mes-tcc\
    -static\
    -o scaffold/tests/"$t".mes-out\
    -I $MES_PREFIX/include\
    -I $MES_PREFIX/scaffold/tests\
    $MES_PREFIX/scaffold/tests/"$t".c &> 2.elf
set +e
scaffold/tests/"$t".mes-out
m=$?
#$OBJDUMP -d scaffold/tests/"$t".mes-out > 2.x

[ $m = $r ]

#diff -y 1.s 2.s
#diff -y 1 2
