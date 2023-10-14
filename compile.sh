#! /bin/sh
set -ex

MES_PREFIX=${MES_PREFIX-mes}
MES_SOURCE=${MES_SOURCE-mes-source}

arch=$(uname -m)
case $arch in
     aarch*)
         cpu=arm
         tcc_cpu=arm
         triplet=arm-linux-gnueabihf
         cross_prefix=${triplet}-
         ;;
     arm*|aarch*)
         cpu=arm
         tcc_cpu=arm
         triplet=arm-unknown-linux-gnueabihf
         cross_prefix=${triplet}-
         ;;
     *)
         cpu=x86
         tcc_cpu=i386
         triplet=i686-unknown-linux-gnu
         cross_prefix=${triplet}-
         ;;
esac

rm -f *.$triplet-o *.mes-o
rm -f 1 2 1.elf 2.elf 1.a 2.a

# trivial object
./tcc -c -I $MES_PREFIX/include $MES_SOURCE/scaffold/main.c 2>/dev/null
./$triplet-tcc -o main.$triplet-o -c -I $MES_PREFIX/include $MES_SOURCE/scaffold/main.c 2> 1
set +e
./tcc-mes -o main.mes-o -c -I $MES_PREFIX/include $MES_SOURCE/scaffold/main.c &> 2
diff -y 1 2
readelf -a main.$triplet-o > 1.elf
readelf -a main.mes-o > 2.elf
diff -y 1.elf 2.elf || :
