#! /bin/sh

set -ex

t=${1-t}
rm -f "scaffold/tests/$t".i686-unknown-linux-gnu-out
rm -f "scaffold/tests/$t".mes-out

MESCC=${MESCC-mescc}
MES_PREFIX=${MES_PREFIX-$(dirname $MESCC)/../share/mes}
TINYCC_SEED=${TINYCC_SEED-../tinycc-seed}

mkdir -p scaffold/tests

if [ -x ./i686-unknown-linux-gnu-tcc ]; then
    ./i686-unknown-linux-gnu-tcc -static -o "scaffold/tests/$t".i686-unknown-linux-gnu-out\
                                 -I $MES_PREFIX/include\
                                 -I $MES_PREFIX/scaffold/tests\
                                 $MES_PREFIX/scaffold/tests/"$t".c &> 1
    set +e
    "scaffold/tests/$t.i686-unknown-linux-gnu-out"
    r=$?
    set -e
else
    r=0
fi

./mes-tcc -static -o "scaffold/tests/$t".mes-out\
          -I $MES_PREFIX/include\
          -I $MES_PREFIX/scaffold/tests\
          $MES_PREFIX/scaffold/tests/"$t".c &> 2

set +e
scaffold/tests/"$t".mes-out
m=$?

[ $m = $r ]
