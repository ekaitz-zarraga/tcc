#! /bin/sh
set -ex
rm -f *.i686-unknown-linux-gnu-o *.mes-o
rm -f 1 2 1.elf 2.elf 1.a 2.a

# trivial object
./tcc -c -I ../mes/include ../mes/scaffold/main.c 2>/dev/null
./i686-unknown-linux-gnu-tcc -o main.i686-unknown-linux-gnu-o -c -I ../mes/include ../mes/scaffold/main.c 2> 1
set +e
./mes-tcc -o main.mes-o -c -I ../mes/include ../mes/scaffold/main.c &> 2
diff -y 1 2
readelf -a main.i686-unknown-linux-gnu-o > 1.elf
readelf -a main.mes-o > 2.elf
diff -y 1.elf 2.elf || :

