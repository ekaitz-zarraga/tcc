#! /bin/sh
set -ex
rm -f *.i686-unknown-linux-gnu-o *.mesc-o
rm -f 1.a 2.a

# trivial bin
./tcc ../mes/scaffold/main.c
./i686-unknown-linux-gnu-tcc -static -o a.i686-unknown-linux-gnu-out -I $MES_PREFIX/include $TINYCC_SEED/crt1.mlibc-o $MES_PREFIX/scaffold/main.c 2> 1.a
set +e
./mes-tcc -static -o a.mes-out -I $MES_PREFIX/include $TINYCC_SEED/crt1.mlibc-o $MES_PREFIX/scaffold/main.c 2> 2.a
readelf -a a.i686-unknown-linux-gnu-out > 1.r
readelf -a a.mes-out > 2.r
diff -y 1.a 2.a
