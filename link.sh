#! /bin/sh
set -ex
rm -f 1.a 2.a

MES_PREFIX=${MES_PREFIX-mes}
MES_SOURCE=${MES_SOURCE-mes-source}

arch=$(uname -m)
case $arch in
     aarch*)
         cpu=arm
         triplet=arm-linux-gnueabihf
         cross_prefix=${triplet}-
         ;;
     arm*|aarch*)
         cpu=arm
         triplet=arm-unknown-linux-gnueabihf
         cross_prefix=${triplet}-
         ;;
     *)
         cpu=x86
         triplet=i686-unknown-linux-gnu
         cross_prefix=${triplet}-
         ;;
esac
export cpu
export cross_prefix
export triplet

c=${1-$MES_PREFIX/scaffold/main}
b=scaffold/${c##*/}

rm -f "$b".mes-gcc-out
rm -f "$b".mes-out

./${cross_prefix}tcc\
    -static -g -o "$b".mes-gcc-out\
   -I.\
   -I $MES_PREFIX/lib\
   -I $MES_PREFIX/include\
   "$c".c \
    2> "$b".mes-gcc-stderr
set +e
${TCC_MES-./tcc-mes}\
    -static -g -o "$b".mes-out
   -I.\
   -I $MES_PREFIX/lib\
   -I $MES_PREFIX/include\
   2> "$b".mes-stderr
objdump -d "$b".mes-gcc-out > "$b".mes-gcc-d
objdump -d "$b".mes-out  > "$b".mes-d
#readelf -a a.${cross_prefix}out > 1.r
#readelf -a a.mes-out > 2.r
#diff -y 1.a 2.a
echo diff -y "$b".mes-gcc-stderr "$b".mes-stderr
echo diff -y "$b".mes-gcc-d "$b".mes-d
"$b".mes-out
