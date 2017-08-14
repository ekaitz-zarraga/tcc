#! /bin/sh

set -ex

TCC=${TCC-./mes-tcc}
MESCC=${MESCC-mescc}
MES_PREFIX=${MES_PREFIX-../mes}
MES_PREFIX=${MES_PREFIX-${MESCC%/*}}
TINYCC_SEED=${TINYCC_SEED-../tinycc-seed}
OBJDUMP=${OBJDUMP-objdump}
DIFF=${DIFF-diff}

unset C_INCLUDE_PATH LIBRARY_PATH

t=${1-$MES_PREFIX/scaffold/tests/t}
mkdir -p scaffold
b=scaffold/${t##*/}
rm -f "$b".i686-unknown-linux-gnu-out
rm -f "$b".mes-out

r=0
if [ -x ./i686-unknown-linux-gnu-tcc ]; then
    ./i686-unknown-linux-gnu-tcc\
        -c\
        -o "$b".mes-gcc-o\
        -nostdlib\
        -g\
        -m32\
        -D __TINYC__=1\
        -I $MES_PREFIX/include\
        -I $MES_PREFIX/scaffold/tests\
        -I $MES_PREFIX/scaffold/tinycc\
        "$t".c &> 1
    #$OBJDUMP -d "$t".mes-gcc-o > 1.s
    ./i686-unknown-linux-gnu-tcc\
        -static\
        -o "$b".mes-gcc-out\
        -L .\
        -L $TINYCC_SEED\
        "$b".mes-gcc-o &> 1.link
    set +e
    "$b".mes-gcc-out arg1 arg2 arg3 arg4 arg5 > "$b".mes-gcc-stdout
    m=$?
    set -e
    [ -f "$t".exit ] && r=$(cat "$t".exit)
    [ $m = $r ]
    if [ -f "$t".expect ]; then
        $DIFF -ub "$t".expect "$b".mes-gcc-stdout;
    fi
fi

$TCC\
    -c\
    -g\
    -m32\
    -o "$b".mes-o\
    -D __TINYC__=1\
    -I $MES_PREFIX/include\
    -I $MES_PREFIX/scaffold/tests\
    -I $MES_PREFIX/scaffold/tinycc\
    "$t".c &> 2
$OBJDUMP -d "$b".mes-o > 2.s || true
$TCC\
    -static\
    -o "$b".mes-out\
    -g\
    -m32\
    -D __TINYC__=1\
    -I $MES_PREFIX/include\
    -I $MES_PREFIX/scaffold/tests\
    -I $MES_PREFIX/scaffold/tinycc\
    -L $TINYCC_SEED\
    "$t".c &> 2.link
set +e
"$b".mes-out arg1 arg2 arg3 arg4 arg5 > "$b".mes-stdout
m=$?
#$OBJDUMP -d "$t".mes-out > 2.x

set -e
[ $m = $r ]
[ -f "$t".exit ] && r=$(cat "$t".exit)
if [ -f "$t".expect ]; then
    $DIFF -ub "$t".expect "$b".mes-stdout;
fi

#diff -y 1.s 2.s
#diff -y 1 2
