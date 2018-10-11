#! /bin/sh
set -ex
rm -f 1.a 2.a

MES_PREFIX=${MES_PREFIX-../mes}
MES_SEED=${MES_SEED-../mes-seed}

# trivial bin
###./tcc ../mes/scaffold/main.c
c=${1-$MES_PREFIX/scaffold/main}
b=scaffold/${c##*/}

rm -f "$b".mes-gcc-out
rm -f "$b".mes-out

./i686-unknown-linux-gnu-tcc\
    -static -g -o "$b".mes-gcc-out -I $MES_PREFIX/include -L $MES_SEED "$c".c 2> "$b".mes-gcc-stderr
set +e
${MES_TCC-./mes-tcc}\
    -static -g -o "$b".mes-out -I $MES_PREFIX/include -L $MES_SEED "$c".c 2> "$b".mes-stderr
objdump -d "$b".mes-gcc-out > "$b".mes-gcc-d
objdump -d "$b".mes-out  > "$b".mes-d
#readelf -a a.i686-unknown-linux-gnu-out > 1.r
#readelf -a a.mes-out > 2.r
#diff -y 1.a 2.a
echo diff -y "$b".mes-gcc-stderr "$b".mes-stderr
echo diff -y "$b".mes-gcc-d "$b".mes-d
"$b".mes-out

